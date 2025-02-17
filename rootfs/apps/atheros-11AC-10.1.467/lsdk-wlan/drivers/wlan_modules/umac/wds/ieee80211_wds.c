/*
 * Copyright (c) 2010, Atheros Communications Inc.
 *
 * Permission to use, copy, modify, and/or distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

#include <osdep.h>

#if UMAC_SUPPORT_WDS

#include <ieee80211_var.h>
#include <ieee80211_node.h>
#include <wbuf.h>
#include <ieee80211_rateset.h>

#ifdef ATH_SUPPORT_HTC
#include "htc_thread.h"
#endif
/* FIXME : Commented calls to lock_bh */

/* Add wds address to the node table */
int
ieee80211_add_wds_addr(struct ieee80211_node_table *nt,
		       struct ieee80211_node *ni, const u_int8_t *macaddr,
		       u_int32_t flags)
{
    int hash;
    struct ieee80211_wds_addr *wds;
   
    rwlock_state_t lock_state;

    wds = (struct ieee80211_wds_addr *) OS_MALLOC(ni->ni_ic->ic_osdev,
            sizeof(struct ieee80211_wds_addr), GFP_KERNEL );

    if (wds == NULL) {
	    /* XXX msg */
	    return 1;
	}

    printk("Adding WDS entry for %s, through ", ether_sprintf(macaddr));
    printk("ni=%s \n", ether_sprintf(ni->ni_macaddr));

    IEEE80211_DPRINTF(ni->ni_vap, IEEE80211_MSG_TDLS,
                      "Adding WDS entry for %s\n", ether_sprintf(macaddr));

    if (flags & IEEE80211_NODE_F_WDS_BEHIND) {
        IEEE80211_DPRINTF(ni->ni_vap, IEEE80211_MSG_TDLS, "%s is behind me\n",
                          ether_sprintf(macaddr));
    } else {
        IEEE80211_DPRINTF(ni->ni_vap, IEEE80211_MSG_TDLS,
                          " it is reachable through: %s, refcnt:%d\n",
                          ether_sprintf(ni->ni_macaddr),
                          ieee80211_node_refcnt(ni));
    }

    wds->wds_agingcount = WDS_AGING_COUNT;
    wds->wds_staging_age = 2 * WDS_AGING_COUNT;
    hash = IEEE80211_NODE_HASH(macaddr);
    IEEE80211_ADDR_COPY(wds->wds_macaddr, macaddr);
    ieee80211_ref_node(ni);             /* Reference node */
    wds->flags = flags;
    wds->wds_ni = ni;
    wds->wds_last_pkt_time = OS_GET_TIMESTAMP();
    if (IEEE80211_TDLS_ENABLED(ni->ni_vap) &&
        ni->ni_flags & IEEE80211_NODE_TDLS) {
        printk(" Setting IEEE80211_NODE_F_WDS_START for ni=%s\n",
                ether_sprintf(ni->ni_macaddr));
        wds->flags |= IEEE80211_NODE_F_WDS_START;
    }
    OS_RWLOCK_WRITE_LOCK(&nt->nt_wds_nodelock, &lock_state);
    LIST_INSERT_HEAD(&nt->nt_wds_hash[hash], wds, wds_hash);
    OS_RWLOCK_WRITE_UNLOCK(&nt->nt_wds_nodelock, &lock_state);

    /* Send an update to all the TDLS nodes */
    if (IEEE80211_TDLS_ENABLED(ni->ni_vap) &&
        flags & IEEE80211_NODE_F_WDS_BEHIND)
        IEEE80211_TDLS_SND_MGMT(ni->ni_vap, IEEE80211_TDLS_LEARNED_ARP,
                                (void *)macaddr);

    return 0;
}

/* remove wds address from the wds hash table */
void
ieee80211_remove_wds_addr(struct ieee80211_node_table *nt,
			  const u_int8_t *macaddr, u_int32_t flags)
{
    int hash;
    struct ieee80211_wds_addr *wds;
    rwlock_state_t lock_state;

    OS_RWLOCK_WRITE_LOCK(&nt->nt_wds_nodelock, &lock_state);

    hash = IEEE80211_NODE_HASH(macaddr);
    LIST_FOREACH(wds, &nt->nt_wds_hash[hash], wds_hash) {
        if (IEEE80211_ADDR_EQ(wds->wds_macaddr, macaddr)) {
            if (!(wds->flags & IEEE80211_NODE_F_WDS_STAGE) &&
                (wds->flags & flags)  ) {
                ieee80211_free_node(wds->wds_ni);  /* Decrement ref count */
                LIST_REMOVE(wds, wds_hash);
                OS_FREE(wds);
            }
            break;
        }
    }
    OS_RWLOCK_WRITE_UNLOCK(&nt->nt_wds_nodelock, &lock_state);
}

/* Remove node references from wds table */
void
ieee80211_del_wds_node(struct ieee80211_node_table *nt,
		       struct ieee80211_node *ni)
{
    int hash;
    struct ieee80211_wds_addr *wds;
    struct ieee80211_wds_addr *wds_next = NULL;

    for (hash=0; hash<IEEE80211_NODE_HASHSIZE; hash++) {
        for ((wds) = LIST_FIRST((&nt->nt_wds_hash[hash])); (wds);) {
            if (wds->wds_ni == ni) {
                /* Instead of freeing the node, make sure that the wds entry is
                 * flagged as stage wds_addr, and force the node pointer to be
                 * NULL. When actual staging timer expires, free the wds entry.
                 */
                wds_next = LIST_NEXT(wds, wds_hash);
                wds->flags |= IEEE80211_NODE_F_WDS_STAGE;
                wds->wds_ni = NULL;
                /* cache the address of the node */
                OS_MEMCPY(wds->wds_ni_macaddr, ni->ni_macaddr, IEEE80211_ADDR_LEN);
                ieee80211_free_node(ni); 
                wds = wds_next;
            } else {
                wds = LIST_NEXT(wds, wds_hash);	
            }
        }
	}
}

static OS_TIMER_FUNC(ieee80211_node_wds_ageout)
{
    struct ieee80211_node_table *nt;
    struct ieee80211_wds_addr *wds = NULL;
    struct ieee80211_wds_addr *wds_next = NULL;
    int hash;
    rwlock_state_t lock_state;

	OS_GET_TIMER_ARG( nt,struct ieee80211_node_table *);

    OS_RWLOCK_WRITE_LOCK(&nt->nt_wds_nodelock, &lock_state);

    for (hash=0; hash<IEEE80211_NODE_HASHSIZE; hash++) {
        for ((wds) = LIST_FIRST((&nt->nt_wds_hash[hash])); (wds);) {
            if (wds->flags & IEEE80211_NODE_F_WDS_STAGE) {
                /* use different count for this */
                wds->wds_staging_age--;
                if (!wds->wds_staging_age) {
                    wds_next = LIST_NEXT(wds, wds_hash);
                    LIST_REMOVE(wds, wds_hash);
                    OS_FREE(wds);
                    wds = wds_next;
                    if (NULL == wds) {
                        break;
                    }
                }
                /* current entry already marked as 'on Stage', but this is not
                 * right time to free the entry, process the next 
                 */
                wds = LIST_NEXT(wds, wds_hash);
                continue;
            }

            if (wds->wds_ni->ni_flags & IEEE80211_NODE_NAWDS && 
            IEEE80211_ADDR_EQ(wds->wds_macaddr, wds->wds_ni->ni_macaddr))
            {
                wds = LIST_NEXT(wds, wds_hash);
                continue;
            }
            
            if (!wds->wds_agingcount) {
                wds_next = LIST_NEXT(wds, wds_hash);
                ieee80211_free_node(wds->wds_ni);  /* Decrement ref count */
                LIST_REMOVE(wds, wds_hash);
                OS_FREE(wds);
                wds = wds_next;
            } else {
                wds->wds_agingcount--;
                wds = LIST_NEXT(wds, wds_hash);                
            }
        }
	}
    OS_RWLOCK_WRITE_UNLOCK(&nt->nt_wds_nodelock, &lock_state);
    OS_SET_TIMER(&nt->nt_wds_aging_timer,WDS_AGING_TIMER_VAL);

}

void
ieee80211_wds_attach(struct ieee80211_node_table *nt)
{

	OS_INIT_TIMER(nt->nt_ic->ic_osdev,
				  &nt->nt_wds_aging_timer,
	              ieee80211_node_wds_ageout,
	              nt);
    OS_RWLOCK_INIT(&nt->nt_wds_nodelock);
    OS_SET_TIMER(&nt->nt_wds_aging_timer,WDS_AGING_TIMER_VAL);
}

void
ieee80211_wds_detach(struct ieee80211_node_table *nt)
{
    OS_FREE_TIMER(&nt->nt_wds_aging_timer);
    OS_RWLOCK_DESTROY(&nt->nt_wds_nodelock);
}


static struct ieee80211_node *
_ieee80211_find_wds_node(
        struct ieee80211_node_table *nt,
        const u_int8_t *macaddr,
        struct ieee80211_wds_addr **wds_stag,
        u_int8_t *stage)
{
    struct ieee80211_node *ni;
    struct ieee80211_wds_addr *wds;
    int hash;

    hash = IEEE80211_NODE_HASH(macaddr);
    LIST_FOREACH(wds, &nt->nt_wds_hash[hash], wds_hash) {
        if (IEEE80211_ADDR_EQ(wds->wds_macaddr, macaddr)) {

            /* if the node is flagged as STAGE, it means, node has gone
             * probably and quickly came back. We should be checking that
             * and add clear the flag, if necessary.
             *
             * If the wireless station behind the AP is moved/roamed onto
             * other AP, l2UF would have cleared the path. But we do not
             * expect the wired stations to go quickly from one wds station
             * to other. In any case, if there any frame coming from one
             * station should clear the path.
             */
            if (wds->flags & IEEE80211_NODE_F_WDS_STAGE) {
                    *wds_stag = wds; 
                    *stage = 1;
                    return NULL;
            } else {
		ni = wds->wds_ni;
		wds->wds_agingcount = WDS_AGING_COUNT; /* reset the aging count */
                wds->wds_staging_age = 2 * WDS_AGING_COUNT;

                if (ni && IEEE80211_IS_TDLS_NODE(ni) &&
                    IEEE80211_TDLS_ENABLED(ni->ni_vap) &&
                    (wds->flags & IEEE80211_NODE_F_WDS_START)) {
                    wds->flags &= ~IEEE80211_NODE_F_WDS_START;
                    ni = ni->ni_vap->iv_bss;
                }

                if (ni) {
                    ieee80211_ref_node(ni);
                }
		return ni;
	    }
    }
    }
    return NULL;
}

void
ieee80211_set_wds_node_time(struct ieee80211_node_table *nt, const u_int8_t *macaddr)
{
    struct ieee80211_wds_addr *wds;
    int hash;

    hash = IEEE80211_NODE_HASH(macaddr);
    LIST_FOREACH(wds, &nt->nt_wds_hash[hash], wds_hash) {
        if (IEEE80211_ADDR_EQ(wds->wds_macaddr, macaddr)) {
            wds->wds_last_pkt_time = OS_GET_TIMESTAMP();
        }
    }
}
static systime_t
_ieee80211_get_wds_node_time(
        struct ieee80211_node_table *nt,
        const u_int8_t *macaddr)
{
    struct ieee80211_wds_addr *wds;
    int hash;
    
    hash = IEEE80211_NODE_HASH(macaddr);
    LIST_FOREACH(wds, &nt->nt_wds_hash[hash], wds_hash) {
        if (IEEE80211_ADDR_EQ(wds->wds_macaddr, macaddr)) {
            return wds->wds_last_pkt_time;
        }
    }
    return 0;
}

/* Remove all the wds entries associated with the AP when the AP to
 * which STA is associated goes down
 */
int ieee80211_node_removeall_wds (struct ieee80211_node_table *nt,struct ieee80211_node *ni)
{
    unsigned int hash;
    struct ieee80211_wds_addr *wds;
    struct ieee80211_wds_addr *wds_next;
    rwlock_state_t lock_state;
    OS_RWLOCK_WRITE_LOCK(&nt->nt_wds_nodelock, &lock_state);
    for (hash=0 ;hash < IEEE80211_NODE_HASHSIZE;hash++) {
        for ((wds) = LIST_FIRST((&nt->nt_wds_hash[hash])); (wds);) {
            if (wds->wds_ni == ni) {
                wds_next = LIST_NEXT(wds,wds_hash);
                ieee80211_free_node(wds->wds_ni);
                LIST_REMOVE(wds, wds_hash);
                OS_FREE(wds);
                wds = wds_next;
            } else {
                wds = LIST_NEXT(wds, wds_hash);    
            }
        }
	}
    OS_RWLOCK_WRITE_UNLOCK(&nt->nt_wds_nodelock, &lock_state);
    return 0;
}

struct ieee80211_node *
ieee80211_find_wds_node(struct ieee80211_node_table *nt, const u_int8_t *macaddr)
{
    struct ieee80211_node *ni;
    struct ieee80211_wds_addr *wds=NULL;
    u_int8_t stag=0;


    rwlock_state_t lock_state;
    OS_RWLOCK_WRITE_LOCK(&nt->nt_wds_nodelock, &lock_state);
    ni = _ieee80211_find_wds_node(nt, macaddr, &wds, &stag);
    /* find wds node should return the pointer the ni, for some reasons,
     * wds entry would have been found on staging. At that instance
     * probably we do not have the node pointer. It, means, there is no
     * real association between wds and wds_ni. Now because it is found
     * on staging, try to establish the relationship between these two in
     * a special way. 
     *
     * the 'wds' argument should contain the pointer to the wds that is in
     * staging. If node is found, that would be NULL, and NI pointer would
     * be returned properly. 
     */
    if (ni == NULL  && stag == 1) {
        if (wds) {
            ni = _ieee80211_find_node(nt, wds->wds_ni_macaddr);
        } else {
            OS_RWLOCK_WRITE_UNLOCK(&nt->nt_wds_nodelock, &lock_state);
            return NULL;
        }
        if (ni && wds) {
            wds->wds_ni = ni;
            wds->wds_agingcount = WDS_AGING_COUNT;
            wds->wds_staging_age = 2 * WDS_AGING_COUNT;
            wds->flags &= ~IEEE80211_NODE_F_WDS_STAGE;

            IEEE80211_DPRINTF(ni->ni_vap, IEEE80211_MSG_WDS, 
                    "%s attaching the node macaddr %s wds mac %s\n", 
                  __func__, ni->ni_macaddr, macaddr);

            ieee80211_ref_node(ni);             /* Reference node */

        } else {
            OS_RWLOCK_WRITE_UNLOCK(&nt->nt_wds_nodelock, &lock_state);
            return NULL;
        }
    }
    OS_RWLOCK_WRITE_UNLOCK(&nt->nt_wds_nodelock, &lock_state);
    return ni;
}

u_int32_t
ieee80211_find_wds_node_age(struct ieee80211_node_table *nt, const u_int8_t *macaddr)
{
    systime_t wds_time;
    u_int32_t wds_age = 0;
    
    rwlock_state_t lock_state;
    systime_t time=OS_GET_TIMESTAMP();
    OS_RWLOCK_WRITE_LOCK(&nt->nt_wds_nodelock, &lock_state);
    wds_time = _ieee80211_get_wds_node_time(nt, macaddr);
    wds_age = CONVERT_SYSTEM_TIME_TO_MS((time - wds_time));
    OS_RWLOCK_WRITE_UNLOCK(&nt->nt_wds_nodelock, &lock_state);
    return wds_age;
}

static void
ieee80211_wds_node_ageout(struct ieee80211_node_table *nt, const u_int8_t *macaddr)
{
    struct ieee80211_wds_addr *wds;
    int hash;
    rwlock_state_t lock_state;

    OS_RWLOCK_WRITE_LOCK(&nt->nt_wds_nodelock, &lock_state);

    hash = IEEE80211_NODE_HASH(macaddr);
    LIST_FOREACH(wds, &nt->nt_wds_hash[hash], wds_hash) {
	if (IEEE80211_ADDR_EQ(wds->wds_macaddr, macaddr)) {
                wds->wds_agingcount = 0;
		break;
	    }
    }

    OS_RWLOCK_WRITE_UNLOCK(&nt->nt_wds_nodelock, &lock_state);
    return;
}


void
wds_clear_wds_table(struct ieee80211_node * ni, struct ieee80211_node_table *nt, wbuf_t wbuf )
{
    struct ieee80211_frame *wh;
    rwlock_state_t lock_state;
    wh = (struct ieee80211_frame *) wbuf_header(wbuf);

    if (ni != ni->ni_vap->iv_bss) {
        struct ieee80211_node *ni_wds=NULL;
        ni_wds = ieee80211_find_wds_node(nt,wh->i_addr2);

        if (ni_wds) {
            OS_BEACON_DECLARE_AND_RESET_VAR(flags);
            OS_BEACON_WRITE_LOCK(&nt->nt_nodelock, &lock_state, flags);
            (void) ieee80211_remove_wds_addr(nt,wh->i_addr2,IEEE80211_NODE_F_WDS_BEHIND | IEEE80211_NODE_F_WDS_REMOTE);
            OS_BEACON_WRITE_UNLOCK(&nt->nt_nodelock, &lock_state, flags);
            ieee80211_free_node(ni_wds);
        }
    }
}
#ifdef ATH_HTC_MII_RXIN_TASKLET
void
ieee80211_nawds_learn(struct ieee80211vap *vap, u_int8_t *mac);

void
ieee80211_nawds_learn_deferwork(void *arg)

{
    struct ieee80211com *ic = (struct ieee80211com *)arg;
    nawds_dentry_t * nawds_entry = NULL ;

    do {

        OS_NAWDSDEFER_LOCKBH(&ic->ic_nawdsdefer_lock);
        nawds_entry = TAILQ_FIRST(&ic->ic_nawdslearnlist);
        if(nawds_entry)
            TAILQ_REMOVE(&ic->ic_nawdslearnlist,nawds_entry,nawds_dlist);
        OS_NAWDSDEFER_UNLOCKBH(&ic->ic_nawdsdefer_lock);
        if(!nawds_entry)
            break;
        ieee80211_nawds_learn(nawds_entry->vap, &nawds_entry->mac[0]);
        OS_FREE(nawds_entry);

    }while(1);
    atomic_set(&ic->ic_nawds_deferflags, DEFER_DONE);
}



void
ieee80211_nawds_learn_defer(struct ieee80211vap *vap, u_int8_t *mac)
{

    struct ieee80211com *ic = vap->iv_ic;

    nawds_dentry_t * nawds_entry ;
   
    nawds_entry = ( nawds_dentry_t * )  OS_MALLOC(ic->ic_osdev, sizeof(nawds_dentry_t), GFP_KERNEL);
    nawds_entry->vap = vap;

    OS_MEMCPY(&nawds_entry->mac[0],mac,IEEE80211_ADDR_LEN);

    TAILQ_INSERT_TAIL(&ic->ic_nawdslearnlist, nawds_entry, nawds_dlist);


    if(atomic_read(&ic->ic_nawds_deferflags) != DEFER_PENDING){
        {
            atomic_set(&ic->ic_nawds_deferflags, DEFER_PENDING);
            OS_PUT_DEFER_ITEM(ic->ic_osdev,
                    ieee80211_nawds_learn_deferwork,
                    WORK_ITEM_SINGLE_ARG_DEFERED,
                    ic, NULL, NULL);

        }
    }

}

#endif
void
wds_update_rootwds_table(struct ieee80211_node * ni, struct ieee80211_node_table *nt, wbuf_t wbuf )
{
    struct ieee80211_frame_addr4 *wh4;
    struct ieee80211_node *ni_wds=NULL;
    struct ieee80211_node *ni_wds_dest=NULL;
    struct ieee80211_node *temp_node=NULL;
    rwlock_state_t lock_state;
#if 0 /* check already perfomed in ieee80211_input.c */
    if (!IEEE80211_VAP_IS_WDS_ENABLED(vap)) {
        IEEE80211_DISCARD(vap, IEEE80211_MSG_INPUT,
                  wh, "data", "%s", "4 addr not allowed");
        goto err;
    }
#endif
    wh4 = (struct ieee80211_frame_addr4 *) wbuf_header(wbuf);
    ni_wds = ieee80211_find_wds_node(nt, wh4->i_addr4);
    /* Last call increments ref count if !NULL */
    if ((ni_wds != NULL) && (ni_wds != ni)) {
        /* node with source address (addr4) moved to another WDS capable
           station. remove the reference to  the previous statation add
           reference to the new one */
        (void) ieee80211_remove_wds_addr(nt,wh4->i_addr4, IEEE80211_NODE_F_WDS_REMOTE);
        ni_wds_dest = ieee80211_find_wds_node(nt, wh4->i_addr3);
        /* node with source address (addr4) and node with address(addr3)
           destination both are reachable through ni. But since ni hands this
           packet to us, we delete the oldest entry of the two(destination) */       
        if((ni_wds_dest != NULL) && (ni_wds_dest == ni))
        {
            /* node with source address (addr4) and node with address(addr3)
             * destination both are reachable through ni. But since ni hands this
             * packet to us, we delete the oldest entry of the two(destination) */       
            (void) ieee80211_remove_wds_addr(nt,wh4->i_addr3, IEEE80211_NODE_F_WDS_REMOTE);
        }
        if(ni_wds_dest != NULL)
            ieee80211_free_node(ni_wds_dest); /* Decr ref count */
        ieee80211_add_wds_addr(nt, ni, wh4->i_addr4,
            IEEE80211_NODE_F_WDS_REMOTE);
    }
    if (ni_wds == NULL) {
        temp_node = ieee80211_find_node(nt,wh4->i_addr4);
        if (temp_node) {
            if (temp_node == ni->ni_vap->iv_bss) {
                /* Received a frame with wrong SA (it is ourself). Do not update the wds table */
                ieee80211_free_node(temp_node);
                return;
            }
            IEEE80211_NODE_LEAVE(temp_node);
            ieee80211_free_node(temp_node);
        }
        ni_wds_dest = ieee80211_find_wds_node(nt, wh4->i_addr3);
        if((ni_wds_dest != NULL) && (ni_wds_dest == ni))
        {
            (void) ieee80211_remove_wds_addr(nt,wh4->i_addr3, IEEE80211_NODE_F_WDS_REMOTE);
        }
        if(ni_wds_dest != NULL)
            ieee80211_free_node(ni_wds_dest); /* Decr ref count */
        ieee80211_add_wds_addr(nt, ni, wh4->i_addr4, 
            IEEE80211_NODE_F_WDS_REMOTE);
    }
    else
    {
        OS_RWLOCK_WRITE_LOCK(&nt->nt_wds_nodelock, &lock_state);
        ieee80211_set_wds_node_time(nt, wh4->i_addr4);
        OS_RWLOCK_WRITE_UNLOCK(&nt->nt_wds_nodelock, &lock_state);
        ni_wds_dest = ieee80211_find_wds_node(nt, wh4->i_addr3);
        if((ni_wds_dest != NULL) && (ni_wds_dest == ni_wds))
        {
            (void) ieee80211_remove_wds_addr(nt,wh4->i_addr3, IEEE80211_NODE_F_WDS_REMOTE);
        }
        if(ni_wds_dest != NULL)
            ieee80211_free_node(ni_wds_dest); /* Decr ref count */
        ieee80211_free_node(ni_wds); /* Decr ref count */
    }
}

int 
wds_sta_chkmcecho(struct ieee80211_node_table * nt, const u_int8_t *sender )
{
    struct ieee80211_node *ni_wds=NULL;
    int mcastecho = 0;
    ni_wds = ieee80211_find_wds_node(nt,sender);

    if (ni_wds ) {
        if (ieee80211_find_wds_node_age(nt, sender) < 1000)
        {
            mcastecho = 1;
        }
        else
        {
            ieee80211_remove_wds_addr(nt,sender, IEEE80211_NODE_F_WDS_BEHIND);
        }
        ieee80211_free_node(ni_wds); /* Decr ref count */
    }

    return mcastecho;
}
/* Due to OWL specific HW bug: Deny aggregation if
 * we're Owl in WDS mode and
 * the remote node hasn't sent us an IE indicating they're Atheros Owl or later
 * and we're a WDS client or we're WDS AP and the remote node is discovered
 * to be a WDS client.
 * Disablement of this is controlled by toggling IEEE80211_C_WDS_AUTODETECT
 * via "iwpriv athN wdsdetect 0".
 */
int ieee80211_node_wdswar_isaggrdeny(struct ieee80211_node *ni)
{
    return (((ni->ni_vap->iv_flags_ext & IEEE80211_FEXT_WDS) &&
	     (ni->ni_vap->iv_flags_ext & IEEE80211_C_WDS_AUTODETECT) &&
	     (ni->ni_vap->iv_ic->ic_ath_extcap & IEEE80211_ATHEC_OWLWDSWAR) &&
	     !(ni->ni_flags & IEEE80211_NODE_ATH) &&
	     ((ni->ni_vap->iv_opmode & IEEE80211_M_STA) ||
	      ((ni->ni_vap->iv_opmode & IEEE80211_M_HOSTAP) &&
	       (ni->ni_flags & IEEE80211_NODE_WDS)))) != 0 );

}

/* Due to OWL specific HW bug, send a DELBA to remote node when we detect
 * that they're a WDS link potentially sending aggregates to us.
 * We do this if we're Owl in WDS mode and
 * the remote node hasn't sent us an IE indicating they're Atheros Owl or later
 * and we're a WDS AP and the remote node is discovered to be a WDS client.
 * Disablement of this is controlled by toggling IEEE80211_C_WDS_AUTODETECT
 * via "iwpriv athN wdsdetect 0".
 */
int ieee80211_node_wdswar_issenddelba(struct ieee80211_node *ni)
{
    return (((ni->ni_vap->iv_flags_ext & IEEE80211_FEXT_WDS) &&
	     (ni->ni_vap->iv_flags_ext & IEEE80211_C_WDS_AUTODETECT) &&
	     (ni->ni_ic->ic_ath_extcap & IEEE80211_ATHEC_OWLWDSWAR) &&
	     !(ni->ni_flags & IEEE80211_NODE_ATH) &&
	     (ni->ni_vap->iv_opmode & IEEE80211_M_HOSTAP)) != 0 );
}

#if UMAC_SUPPORT_NAWDS

#ifndef UMAC_MAX_NAWDS_REPEATER
#error NAWDS feature is enabled but UMAC_MAX_NAWDS_REPEATER is not defined
#endif

/* codes for Non-Associated WDS - NAWDS */
/* common functions for UMAC and MLME support */
static int
is_nawds_valid_mac(char *addr)
{
    char nullmac[] = {0x00, 0x00, 0x00, 0x00, 0x00, 0x00};

    if (IEEE80211_IS_MULTICAST(addr) ||
        IEEE80211_ADDR_EQ(addr, nullmac))
        return 0;
    return 1;
}

static int
is_nawds_valid_caps(u_int8_t caps)
{
    uint8_t ht_flags, vht_flags;

    if(caps >= NAWDS_INVALID_CAP_MODE || caps < 0)
        return 0;
    ht_flags  = (NAWDS_REPEATER_CAP_HT20 | NAWDS_REPEATER_CAP_HT2040 | NAWDS_REPEATER_CAP_DS);
    vht_flags = (NAWDS_REPEATER_CAP_11ACVHT20 | NAWDS_REPEATER_CAP_11ACVHT40 | NAWDS_REPEATER_CAP_11ACVHT80);
    if (caps & (NAWDS_REPEATER_CAP_TS | NAWDS_REPEATER_CAP_DS | vht_flags)) {
        if (!((caps & vht_flags) || (caps & ht_flags))){
            return 0;
        }
    }
    return 1;
}

/* UMAC Support Functions */
void
ieee80211_nawds_attach(struct ieee80211vap *vap)
{
    OS_MEMZERO(&vap->iv_nawds, sizeof(struct ieee80211_nawds));
    NAWDS_LOCK_INIT(&vap->iv_nawds.lock);
}

int ieee80211_nawds_send_wbuf(struct ieee80211vap *vap, wbuf_t wbuf)
{
    int i, count = 0;
    struct ieee80211_node *rep_ni, *src_ni, *wbuf_ni = NULL;
    struct ieee80211_nawds *nawds = &vap->iv_nawds;
    struct ieee80211com *ic = vap->iv_ic;
    struct ether_header *eh;
    wbuf_t wbuf1 = NULL;

    /* Do not send nawds packet when mode is off or node is inactive */
    wbuf_ni = wbuf_get_node(wbuf);
    if ((wbuf_ni != NULL) &&
        (wbuf_ni->ni_flags & IEEE80211_NODE_NAWDS)) {
        if ((nawds->mode == IEEE80211_NAWDS_DISABLED) || 
            (wbuf_ni->ni_inact <= 1)) {
            IEEE80211_DPRINTF(vap, IEEE80211_MSG_WDS, 
                "%s: nawds mode off or node inactive\n", __func__);
            ieee80211_free_node(wbuf_ni);
            wbuf_complete(wbuf);
            return -1;
        }
    }

    if (nawds->mode == IEEE80211_NAWDS_DISABLED)
        return 0;

    eh = (struct ether_header *)wbuf_header(wbuf);

    if (!((vap->iv_flags_ext & IEEE80211_FEXT_WDS) &&
         (IEEE80211_IS_MULTICAST(eh->ether_dhost))))
        return 0;

    IEEE80211_DPRINTF(vap, IEEE80211_MSG_WDS, "nawds: %s: ", 
            ether_sprintf(eh->ether_dhost));

    for (i = 0; i < UMAC_MAX_NAWDS_REPEATER; i++) {
        if (!is_nawds_valid_mac(nawds->repeater[i].mac))
            continue;
        if ((rep_ni = ieee80211_find_node(&ic->ic_sta, nawds->repeater[i].mac)) == NULL) {
            IEEE80211_DPRINTF(vap, IEEE80211_MSG_WDS, "missing node: %s\n", 
                    ether_sprintf(nawds->repeater[i].mac));
            continue;
        }
        if (!(rep_ni->ni_flags & IEEE80211_NODE_NAWDS)) {
            IEEE80211_DPRINTF(vap, IEEE80211_MSG_WDS, "node without flags: %s\n", 
                    ether_sprintf(nawds->repeater[i].mac));
            ieee80211_free_node(rep_ni);
            continue;
        }
        if (rep_ni->ni_inact <= 1) {
            IEEE80211_DPRINTF(vap, IEEE80211_MSG_WDS, "node inactive: %s\n", 
                    ether_sprintf(nawds->repeater[i].mac));
            ieee80211_free_node(rep_ni);
            continue;
        }
        /* To avoid a bcast storm we need to check if the src is reachable
         * over this repeater; if it is, skip this process for this
         * repeater alone and contine to send on other repeaters
         */
        src_ni = ieee80211_find_txnode(vap, eh->ether_shost);
        if (rep_ni == src_ni) {
            IEEE80211_DPRINTF(vap, IEEE80211_MSG_WDS, "drop: %s\n", 
                    ether_sprintf(nawds->repeater[i].mac));
            ieee80211_free_node(rep_ni);
            ieee80211_free_node(src_ni);
            continue;
        }
        if (src_ni)
            ieee80211_free_node(src_ni);

        /* copy buf and send it out */
        wbuf1 = wbuf_copy(wbuf);
        wbuf_set_node(wbuf1, rep_ni);
        wbuf_clear_flags(wbuf1);
        vap->iv_evtable->wlan_dev_xmit_queue(vap->iv_ifp, wbuf1);

        IEEE80211_DPRINTF(vap, IEEE80211_MSG_WDS, "send: %s ref: %d\n", 
                ether_sprintf(nawds->repeater[i].mac), 
                ieee80211_node_refcnt(rep_ni));
        count++;
    }

    return count;
}

int 
ieee80211_nawds_disable_beacon(struct ieee80211vap *vap)
{
    if ((vap->iv_nawds.mode == IEEE80211_NAWDS_STATIC_BRIDGE) ||
        (vap->iv_nawds.mode == IEEE80211_NAWDS_LEARNING_BRIDGE))
        return 1;
    return 0;
}

int
ieee80211_nawds_enable_learning(struct ieee80211vap *vap)
{
    if ((vap->iv_nawds.mode == IEEE80211_NAWDS_LEARNING_REPEATER) ||
        (vap->iv_nawds.mode == IEEE80211_NAWDS_LEARNING_BRIDGE))
        return 1;
    return 0;
}

void
ieee80211_nawds_learn(struct ieee80211vap *vap, u_int8_t *mac)
{
    wlan_nawds_config_mac(vap, mac, vap->iv_nawds.defcaps);
	IEEE80211_DPRINTF(vap, IEEE80211_MSG_WDS, "NAWDS repeater learned %s: %d\n", 
            ether_sprintf(mac),vap->iv_nawds.defcaps);
}


/* IEEE80211 MLME support functions */
static void 
ieee80211_nawds_node_leave(wlan_if_t vaphandle, u_int8_t *addr)
{
    int i;
    struct ieee80211_node* ni;
	struct ieee80211vap *vap = vaphandle;
    struct ieee80211_nawds *nawds = &vap->iv_nawds;
    struct ieee80211com *ic = vap->iv_ic;

    for(i = 0; i < UMAC_MAX_NAWDS_REPEATER; i++) {
        if (IEEE80211_ADDR_EQ(nawds->repeater[i].mac, addr))
            break;
    }

    if (i == UMAC_MAX_NAWDS_REPEATER)
        return;
   
    /* reclaim the node */
    ni = ieee80211_find_node(&ic->ic_sta, addr);
    if (ni) {
        IEEE80211_NODE_LEAVE(ni);
        ieee80211_free_node(ni);
    }

    /* clear NAWDS node table for the mac */
    nawds->repeater[i].caps = 0;
    OS_MEMZERO(nawds->repeater[i].mac, IEEE80211_ADDR_LEN);
}

static void
ieee80211_nawds_node_leave_all(wlan_if_t vaphandle)
{
    int i;
	struct ieee80211vap *vap = vaphandle;
    struct ieee80211_nawds *nawds = &vap->iv_nawds;

    for(i = 0; i < UMAC_MAX_NAWDS_REPEATER; i++) {
        if (is_nawds_valid_mac(nawds->repeater[i].mac)) {
            ieee80211_nawds_node_leave(vap, nawds->repeater[i].mac);
        }
    }
}

/* This function is called to configure a repeater node as a HT node.
 * To avoid too much configuration, defaults are assumed as follows
 * MAX A-MPDU factor (valid range 0-3) default 2
 * MAX mpdudensity (valid range 0-7) default 7
 * SHORTGI not supprted as HT40 is not supported
 */
#define ATH_WDS_SINGLE_STREAM_REP_MAXAMPDUFACTOR 2
#define ATH_WDS_SINGLE_STREAM_REP_MPDUDENSITY    7
#define ATH_WDS_DOUBLE_STREAM_REP_MAXAMPDUFACTOR 3
#define ATH_WDS_DOUBLE_STREAM_REP_MPDUDENSITY    0
#define ATH_WDS_TRIPLE_STREAM_REP_MAXAMPDUFACTOR 3
#define ATH_WDS_TRIPLE_STREAM_REP_MPDUDENSITY    6
static int
ieee80211_nawds_config_ht(struct ieee80211_node *ni, u_int8_t caps)
{
    struct ieee80211_node * vapnode;
    struct ieee80211com   *ic = ni->ni_ic;
    struct ieee80211vap   *vap = ni->ni_vap;
    u_int32_t  mpdudensity = 0;
    u_int16_t  maxampdufactor = 0;

    /* Check the HT20/40 ratesets */
    if (caps & NAWDS_REPEATER_CAP_HT2040)
        ni->ni_chwidth = IEEE80211_CWM_WIDTH40;
    else
        ni->ni_chwidth = IEEE80211_CWM_WIDTH20;

    /* Check if DS rates could be used */
    ni->ni_htcap &= (~IEEE80211_HTCAP_C_SM_MASK);
    ni->ni_htcap &= ~(IEEE80211_HTCAP_C_SHORTGI40);
    
    if (caps &NAWDS_REPEATER_CAP_TS){
        ni->ni_htcap |= IEEE80211_HTCAP_C_TXSTBC;
        ni->ni_htcap |= (IEEE80211_HTCAP_C_RXSTBC & ( 1 << IEEE80211_HTCAP_C_RXSTBC_S));
        ni->ni_htcap |= IEEE80211_HTCAP_C_ADVCODING;
        ni->ni_htcap |= IEEE80211_HTCAP_C_SM_ENABLED;
        ni->ni_htcap |= IEEE80211_HTCAP_C_SHORTGI20;
        
        if (caps & NAWDS_REPEATER_CAP_HT2040) {
            ni->ni_htcap |= IEEE80211_HTCAP_C_SHORTGI40;
            ni->ni_htcap |= IEEE80211_HTCAP_C_CHWIDTH40;
        } 
        
        if (IEEE80211_IS_CHAN_11NA(vap->iv_bsschan)) 
            ni->ni_htcap &= ~IEEE80211_HTCAP_C_DSSSCCK40;
        else
            ni->ni_htcap |= IEEE80211_HTCAP_C_DSSSCCK40;

        ni->ni_updaterates = IEEE80211_NODE_SM_EN;
        ni->ni_streams = 3;
        mpdudensity = ATH_WDS_TRIPLE_STREAM_REP_MPDUDENSITY;
        maxampdufactor = ATH_WDS_TRIPLE_STREAM_REP_MAXAMPDUFACTOR;
    
    }else if (caps & NAWDS_REPEATER_CAP_DS) {
        ni->ni_htcap |= IEEE80211_HTCAP_C_TXSTBC;
        ni->ni_htcap |= (IEEE80211_HTCAP_C_RXSTBC & ( 1 << IEEE80211_HTCAP_C_RXSTBC_S));
        ni->ni_htcap |= IEEE80211_HTCAP_C_ADVCODING;
        ni->ni_htcap |= IEEE80211_HTCAP_C_SM_ENABLED;
        ni->ni_htcap |= IEEE80211_HTCAP_C_SHORTGI20;
        
        if (caps & NAWDS_REPEATER_CAP_HT2040) {
            ni->ni_htcap |= IEEE80211_HTCAP_C_SHORTGI40;
            ni->ni_htcap |= IEEE80211_HTCAP_C_CHWIDTH40;
        } 
        
        if (IEEE80211_IS_CHAN_11NA(vap->iv_bsschan))
            ni->ni_htcap &= ~IEEE80211_HTCAP_C_DSSSCCK40;
        else
            ni->ni_htcap |= IEEE80211_HTCAP_C_DSSSCCK40;
        
        ni->ni_updaterates = IEEE80211_NODE_SM_EN;
        ni->ni_streams = 2;
        mpdudensity = ATH_WDS_DOUBLE_STREAM_REP_MPDUDENSITY;
        maxampdufactor = ATH_WDS_DOUBLE_STREAM_REP_MAXAMPDUFACTOR;
    
    } else {
        ni->ni_htcap |= IEEE80211_HTCAP_C_SMPOWERSAVE_STATIC;
        ni->ni_updaterates = IEEE80211_NODE_SM_PWRSAV_STAT;
        ni->ni_streams = 1;
        mpdudensity = ATH_WDS_SINGLE_STREAM_REP_MPDUDENSITY;
        maxampdufactor =  ATH_WDS_SINGLE_STREAM_REP_MAXAMPDUFACTOR;
    }

#ifdef ATH_SUPPORT_TxBF
    if (caps &  NAWDS_REPEATER_CAP_TXBF){
        ni->ni_txbf.value = ic->ic_txbf.value; /* force node's txbf setting as local setting*/
        ieee80211_match_txbfcapability(ic, ni);
    }
#endif

    /* mark the node as HT-capable */
    ni->ni_flags |= IEEE80211_NODE_HT;

    /*
     * The Maximum Rx A-MPDU defined by this field is equal to
     *      (2^^(13 + Maximum Rx A-MPDU Factor)) - 1
     * octets.  Maximum Rx A-MPDU Factor is an integer in the
     * range 0 to 3.
     */
    ni->ni_maxampdu = ((1u << (IEEE80211_HTCAP_MAXRXAMPDU_FACTOR + maxampdufactor)) - 1);
    ni->ni_mpdudensity = ieee80211_parse_mpdudensity(mpdudensity);

    /* copy the VAP HT Rates */
    vapnode = ni->ni_vap->iv_bss;
    memcpy(&(ni->ni_htrates), &(vapnode->ni_htrates), sizeof(struct ieee80211_rateset));

    if (ic->ic_set_ampduparams) {
        ic->ic_set_ampduparams(ni);
    }

    return 0;
}

static int
ieee80211_nawds_config_base(struct ieee80211_node *ni, int caps, uint8_t ht_disable)
{

    struct ieee80211vap *vap = ni->ni_vap;
    struct ieee80211com *ic ;
    struct ieee80211_node * vapni;

    /* sanity check */
    if ((vap == NULL) || ((ic = vap->iv_ic) == NULL)) {
        return -EINVAL;
    }

    vapni = vap->iv_bss;

    /* configure the capabilties */
    ni->ni_capinfo = vapni->ni_capinfo;
    ni->ni_flags = vapni->ni_flags;

    /* for bkward compat I assume bg unless configured otherwise */
    ni->ni_flags &= ~(IEEE80211_NODE_HT);
    ni->ni_flags &= ~(IEEE80211_NODE_WDS);
    ni->ni_flags |=  IEEE80211_NODE_QOS;
    ni->ni_flags |=  IEEE80211_NODE_ERP;

    if ((caps &  NAWDS_REPEATER_CAP_DS) || (caps & NAWDS_REPEATER_CAP_TS) || ht_disable) {
        if (ht_disable || IEEE80211_IS_CHAN_11NG(vap->iv_bsschan)) {
            ni->ni_capinfo |= IEEE80211_CAPINFO_SHORT_PREAMBLE;
            ni->ni_capinfo |= IEEE80211_CAPINFO_SHORT_SLOTTIME;
            IEEE80211_DISABLE_PROTECTION(ic);
            ic->ic_protmode = IEEE80211_PROT_NONE;
            ic->ic_update_protmode(ic);          
        }
    }    
    
    /* copy the rates and xrates */
    memcpy(&(ni->ni_rates), &(vapni->ni_rates), sizeof(struct ieee80211_rateset));

    if ((ni->ni_capinfo & IEEE80211_CAPINFO_SHORT_PREAMBLE) == 0) {
        /* set preamble to no short preamble */
        ic->ic_flags &= ~IEEE80211_F_SHPREAMBLE;
        ic->ic_flags |= IEEE80211_F_USEBARKER;
    }    
    else {
        /* set preamble to short preamble */
        ic->ic_flags |= IEEE80211_F_SHPREAMBLE;
        ic->ic_flags &= ~IEEE80211_F_USEBARKER;
    }    
    
    ieee80211_set_shortslottime(ic,
            IEEE80211_IS_CHAN_A(ic->ic_curchan) ||
            IEEE80211_IS_CHAN_11NA(ic->ic_curchan) ||
            (ni->ni_capinfo & IEEE80211_CAPINFO_SHORT_SLOTTIME));

    return 0;
}

/*
 * VHT Configuration : 
 * 1. vhtcap
 * 2. rx_max_rate;
 *    rx_vhtrates;
 *    tx_max_rate;
 *    ni_tx_vhtrates;
 *    IEEE80211_NODE_VHT
 */
static int
ieee80211_nawds_config_vht(struct ieee80211_node *ni, u_int8_t caps)
{
    struct ieee80211com   *ic = ni->ni_ic;
    struct ieee80211vap   *vap = ni->ni_vap;
    u_int32_t vhtcap_info, ampdu_len = 0;
    u_int8_t  chwidth = 0;

    /* Fill in the VHT capabilities info */
    vhtcap_info    = ic->ic_vhtcap; 
    vhtcap_info   &= ((vap->iv_sgi) ? ic->ic_vhtcap : ~IEEE80211_VHTCAP_SHORTGI_80);
    vhtcap_info   &= ((vap->iv_ldpc) ?  ic->ic_vhtcap  : ~IEEE80211_VHTCAP_RX_LDPC);
    vhtcap_info   &= ((vap->iv_tx_stbc) ?  ic->ic_vhtcap : ~IEEE80211_VHTCAP_TX_STBC);
    vhtcap_info   &= ((vap->iv_rx_stbc) ?  ic->ic_vhtcap : ~IEEE80211_VHTCAP_RX_STBC);
    ni->ni_vhtcap  = htole32(vhtcap_info); 

    /* Set Chwidth depending on defcaps */
    if(caps & NAWDS_REPEATER_CAP_11ACVHT80)
        chwidth = IEEE80211_CWM_WIDTH80;
    else if(caps & NAWDS_REPEATER_CAP_11ACVHT40)
        chwidth = IEEE80211_CWM_WIDTH40;
    else if(caps & NAWDS_REPEATER_CAP_11ACVHT20)
        chwidth = IEEE80211_CWM_WIDTH20;

    if (vap->iv_opmode == IEEE80211_M_HOSTAP) {
        switch(chwidth) {
            case IEEE80211_CWM_WIDTH20:
                ni->ni_chwidth = IEEE80211_CWM_WIDTH20;
            break;

            case IEEE80211_CWM_WIDTH40:
                    ni->ni_chwidth = IEEE80211_CWM_WIDTH40;
            break;

            case IEEE80211_CWM_WIDTH80:
                    ni->ni_chwidth = IEEE80211_CWM_WIDTH80;
            break;

            default:
                /* Do nothing */
            break;
        }
    }

    /* Fill in the VHT MCS info */
    ieee80211_set_vht_rates(ic,vap);

    /*
     * The Maximum Rx A-MPDU defined by this field is equal to
     *   (2^^(13 + Maximum Rx A-MPDU Factor)) - 1
     * octets.  Maximum Rx A-MPDU Factor is an integer in the
     * range 0 to 7.
     */
    ampdu_len = (le32toh(ni->ni_vhtcap) & IEEE80211_VHTCAP_MAX_AMPDU_LEN_EXP) >> IEEE80211_VHTCAP_MAX_AMPDU_LEN_EXP_S;
    ni->ni_maxampdu = (1u << (IEEE80211_VHTCAP_MAX_AMPDU_LEN_FACTOR + ampdu_len)) -1;
    ni->ni_tx_vhtrates = ic->ic_vhtcap_max_mcs.tx_mcs_set.mcs_map;
    ni->ni_tx_max_rate = ic->ic_vhtcap_max_mcs.tx_mcs_set.data_rate;
    ni->ni_rx_vhtrates = ic->ic_vhtcap_max_mcs.rx_mcs_set.mcs_map;
    ni->ni_rx_max_rate = ic->ic_vhtcap_max_mcs.rx_mcs_set.data_rate;

    ni->ni_flags |= IEEE80211_NODE_VHT;

    /* Streams decision based on TS / DS flag */
    if(caps & NAWDS_REPEATER_CAP_TS){
        ni->ni_streams = 3; 
    }
    else if(caps & NAWDS_REPEATER_CAP_DS){
        ni->ni_streams = 2; 
    } else {
        ni->ni_streams = 1;
    }
    /*
     * Update NSS and CHWIDTH params on target
     */
    ic->ic_nss_change(ni);
    ic->ic_chwidth_change(ni);

    return 0;
}

static struct
ieee80211_node *wlan_nawds_config_repeater(wlan_if_t vaphandle, char *macaddr, int caps)
{
    struct ieee80211_node *ni = NULL;
    struct ieee80211vap *vap = vaphandle;
    struct ieee80211com *ic = vap->iv_ic;
    struct ieee80211_node       *ni_wds = NULL;
    struct ieee80211_node_table  *nt = &ic->ic_sta;
    uint8_t ht_flags, vht_flags, ht_disable=0;

    /* if previously configured node found, start the node over */
    ni = ieee80211_find_node(&ic->ic_sta, macaddr);
    if (ni) {
        ieee80211_free_node(ni);
        goto reconfigure;
    }

    ni = ieee80211_dup_bss(vap, macaddr);
    if (ni == NULL)
        return NULL;

    /* free the extra refcount got from dup_bss() */
    ieee80211_free_node(ni);

reconfigure:
    /* another check for NG setup  was earlier 0 */
    /* we do not want very low RSSI as we may start at very poor rates, so setting RSSI to a normal value*/
    ni->ni_rssi = 35;

    if((IEEE80211_VAP_IS_PRIVACY_ENABLED(vap) || (ni->ni_capinfo & IEEE80211_CAPINFO_PRIVACY)) &&
            (RSN_CIPHER_IS_WEP(&vap->iv_rsn))){
       ht_disable = 1;
    }
    /* base configuration */
    ieee80211_nawds_config_base(ni, caps, ht_disable);

    /* HT capability */
    ht_flags  = (NAWDS_REPEATER_CAP_HT20 | NAWDS_REPEATER_CAP_HT2040 | NAWDS_REPEATER_CAP_DS);
    vht_flags = (NAWDS_REPEATER_CAP_11ACVHT20 | NAWDS_REPEATER_CAP_11ACVHT40 | NAWDS_REPEATER_CAP_11ACVHT80);
    if (caps & (ht_flags | vht_flags) || ht_disable) {
        if((IEEE80211_VAP_IS_PRIVACY_ENABLED(vap) || (ni->ni_capinfo & IEEE80211_CAPINFO_PRIVACY)) &&
                (RSN_CIPHER_IS_WEP(&vap->iv_rsn))){ 
            IEEE80211_DPRINTF(vap, IEEE80211_MSG_WDS, "%s: WEP Mode, so not configuring HT Cap\n", __FUNCTION__);
        }
        else {
            ieee80211_nawds_config_ht(ni, caps);
            /* VHT Capability */
            if(caps & vht_flags) {
                ieee80211_nawds_config_vht(ni, caps);
            }
        }
    }

    /* the node was created as a repeater to avoid kickout */
    ni->ni_flags |= IEEE80211_NODE_WDS;
    ni->ni_flags |= IEEE80211_NODE_NAWDS;

    ieee80211_node_join(ni);
    ieee80211_node_authorize(ni);
    if (ic->ic_newassoc != NULL)
        ic->ic_newassoc(ni, 1);

    ni_wds = ieee80211_find_wds_node(nt, macaddr);
    if (ni_wds == NULL) {
        ieee80211_add_wds_addr(nt, ni, macaddr,
            IEEE80211_NODE_F_WDS_REMOTE);
    } else {
        ieee80211_free_node(ni_wds);
    }

    return ni;
}

int wlan_nawds_config_mac(wlan_if_t vaphandle, char *macaddr, char caps)
{
    int i, slot_free = -1, max_xretries = 0, slot_max_retries = 0;
    struct ieee80211vap *vap = vaphandle;
    struct ieee80211_nawds *nawds = &vap->iv_nawds;
    struct ieee80211com *ic = vap->iv_ic;
    nawds_rwlock_state_t(lock_state);


    /* if VHT is enabled, Also enable HT flags */
    if(caps & NAWDS_REPEATER_CAP_11ACVHT20){
        nawds->defcaps |= NAWDS_REPEATER_CAP_HT20;
        caps           |= NAWDS_REPEATER_CAP_HT20; 
    }
    else if(caps & NAWDS_REPEATER_CAP_11ACVHT40){
        nawds->defcaps |= NAWDS_REPEATER_CAP_HT2040;
        caps           |= NAWDS_REPEATER_CAP_HT2040;
    }

    /* sanity check */
    if (!is_nawds_valid_mac(macaddr) ||
        !is_nawds_valid_caps(caps)) {
        return -EINVAL;
    }

    NAWDS_WRITE_LOCK(&nawds->lock, &lock_state);

    /* try to find repeater with the mac and update the caps */
    for(i = 0; i < UMAC_MAX_NAWDS_REPEATER; i++) {
        if (IEEE80211_ADDR_EQ(nawds->repeater[i].mac, macaddr)) {
            nawds->repeater[i].caps = caps;
            wlan_nawds_config_repeater(vaphandle, macaddr, caps);
            OS_RWLOCK_WRITE_UNLOCK(&nawds->lock, &lock_state);
            return 0;
        }
        if (!is_nawds_valid_mac(nawds->repeater[i].mac)) {
            if (slot_free == -1)
                slot_free = i;
        } else if (nawds->override) {
            /* the entry has a valid mac */
            struct ieee80211_node *ni = NULL;
            ni = ieee80211_find_node(&ic->ic_sta, nawds->repeater[i].mac);
            if (!ni)
                continue;
            ieee80211_free_node(ni);
            if (ni->ni_consecutive_xretries >= max_xretries) {
                max_xretries = ni->ni_consecutive_xretries;
                slot_max_retries = i;
            }
        }
    }

    /* can't find the repeater for the given mac address */
    if (slot_free == -1) {
        if (!nawds->override) {
            NAWDS_WRITE_UNLOCK(&nawds->lock, &lock_state);
            return -ENOSPC;
        } else {
            ieee80211_nawds_node_leave(vaphandle, 
                    nawds->repeater[slot_max_retries].mac);
            slot_free = slot_max_retries;
        }
    }

    /* clear the NAWDS repeater with the largest tx errors */

    /* configure the NAWDS repeater node */
    IEEE80211_ADDR_COPY(nawds->repeater[slot_free].mac, macaddr);
    nawds->repeater[slot_free].caps = caps;
    wlan_nawds_config_repeater(vaphandle, macaddr, caps);

    NAWDS_WRITE_UNLOCK(&nawds->lock, &lock_state);

    return 0;
}

int wlan_nawds_delete_mac(wlan_if_t vaphandle, char *macaddr)
{
    int i;
    struct ieee80211vap *vap = vaphandle;
    struct ieee80211_nawds *nawds = &vap->iv_nawds;
    nawds_rwlock_state_t(lock_state);

    NAWDS_WRITE_LOCK(&nawds->lock, &lock_state);

    /* try to find repeater with the mac and update the caps */
    for(i = 0; i < UMAC_MAX_NAWDS_REPEATER; i++) {
        if (IEEE80211_ADDR_EQ(nawds->repeater[i].mac, macaddr)) {
            ieee80211_nawds_node_leave(vaphandle, macaddr);
            NAWDS_WRITE_UNLOCK(&nawds->lock, &lock_state);
            return 0;
        }
    }

    /* can't find the repeater for the given mac address */
    NAWDS_WRITE_UNLOCK(&nawds->lock, &lock_state);
    return -ENXIO;
}

int wlan_nawds_get_mac(wlan_if_t vaphandle, int num, char *macaddr, char *caps)
{
    struct ieee80211vap *vap = vaphandle;
    struct ieee80211_nawds *nawds = &vap->iv_nawds;
    nawds_rwlock_state_t(lock_state);

    /* sanity check */
    if (num < 0 || num >= UMAC_MAX_NAWDS_REPEATER) {
        return -EINVAL;
    }

    NAWDS_WRITE_LOCK(&nawds->lock, &lock_state);

    OS_MEMCPY(macaddr, nawds->repeater[num].mac, IEEE80211_ADDR_LEN);
    *caps = nawds->repeater[num].caps;

    NAWDS_WRITE_UNLOCK(&nawds->lock, &lock_state);

    return 0;
}

int wlan_nawds_set_param(wlan_if_t vaphandle, enum ieee80211_nawds_param param, void *val)
{
    int ret = 0;
    struct ieee80211vap *vap = vaphandle;
    struct ieee80211_nawds *nawds = &vap->iv_nawds;
    nawds_rwlock_state_t(lock_state);
    int mode, defcaps, override;

    NAWDS_WRITE_LOCK(&nawds->lock, &lock_state);

    switch(param) {
        case IEEE80211_NAWDS_PARAM_MODE:
            mode = *((u_int8_t *) val);
            /* sanity check */
            if (mode < IEEE80211_NAWDS_DISABLED ||
                mode > IEEE80211_NAWDS_LEARNING_BRIDGE) {
                ret = -EINVAL;
                goto out;
            }
            if (mode == nawds->mode)
                goto out;
            /* clear all nawds repeaters */
            ieee80211_nawds_node_leave_all(vap);
            /* change mode */
            nawds->mode = mode;
            break;
        case IEEE80211_NAWDS_PARAM_DEFCAPS:
            defcaps = *((u_int8_t *) val);
            if (!is_nawds_valid_caps(defcaps)) {
                ret = -EINVAL;
                goto out;
            }
            nawds->defcaps = defcaps;
            break;
        case IEEE80211_NAWDS_PARAM_OVERRIDE:
            override = *((u_int8_t *) val);
            nawds->override = override;
            break;
        default:
            ret = -EINVAL;
            goto out;
    }

out:
    NAWDS_WRITE_UNLOCK(&nawds->lock, &lock_state);

    return ret;
}

int wlan_nawds_get_param(wlan_if_t vaphandle, enum ieee80211_nawds_param param, void *val)
{
    struct ieee80211vap *vap = vaphandle;
    struct ieee80211_nawds *nawds = &vap->iv_nawds;
    nawds_rwlock_state_t(lock_state);

    NAWDS_WRITE_LOCK(&nawds->lock, &lock_state);

    switch(param) {
        case IEEE80211_NAWDS_PARAM_MODE:
            *((u_int8_t *) val) = nawds->mode;
            break;
        case IEEE80211_NAWDS_PARAM_DEFCAPS:
            *((u_int8_t *) val) = nawds->defcaps;
            break;
        case IEEE80211_NAWDS_PARAM_OVERRIDE:
            *((u_int8_t *) val) = nawds->override;
            break;
        case IEEE80211_NAWDS_PARAM_NUM:
            *((u_int8_t *) val) = UMAC_MAX_NAWDS_REPEATER;
            break;
        default:
            NAWDS_WRITE_UNLOCK(&nawds->lock, &lock_state);
            return -EINVAL;
    }

    NAWDS_WRITE_UNLOCK(&nawds->lock, &lock_state);

    return 0;
}

#endif /* UMAC_SUPPORT_NAWDS */

int wlan_wds_add_entry(wlan_if_t vaphandle, char *destmac, char *peermac)
{
    struct ieee80211vap *vap = vaphandle;
    struct ieee80211com *ic = vap->iv_ic;
    ic->ic_node_add_wds_entry(ic, destmac, peermac);
    return 0;
}

int wlan_wds_del_entry(wlan_if_t vaphandle, char *destmac)
{
    struct ieee80211vap *vap = vaphandle;
    struct ieee80211com *ic = vap->iv_ic;
    ic->ic_node_del_wds_entry(ic, destmac);
    return 0;
}

int wlan_wds_add_addr(wlan_if_t vaphandle, char *mac_node, char *mac, u_int32_t flags)
{
    int retval = 0;
    struct ieee80211vap *vap = vaphandle;
    struct ieee80211com *ic = vap->iv_ic;
    struct ieee80211_node_table *nt = &ic->ic_sta;
    struct ieee80211_node *ni = NULL;
    struct ieee80211_node *ni_wds = NULL;

    ni_wds = ieee80211_find_wds_node(nt, mac);
    if(ni_wds)
    {
        ieee80211_free_node(ni_wds); /* Decr ref count */
    }
    else
    {
        ni = ieee80211_find_node(nt, mac_node);
        if (ni == NULL) {
            retval = -EINVAL;
        } else {
            retval = ieee80211_add_wds_addr(nt, ni, mac, flags);
            ieee80211_free_node(ni);
        }
    }
    return retval;
}

#endif /* UMAC_SUPPORT_WDS */
