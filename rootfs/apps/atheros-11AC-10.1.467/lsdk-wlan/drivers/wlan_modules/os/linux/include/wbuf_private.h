/*
 *  Copyright (c) 2005 Atheros Communications Inc.  All rights reserved.
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

#ifndef _WBUF_PRIVATE_LINUX_H
#define _WBUF_PRIVATE_LINUX_H

/*
 * Linux Definition and Implementation for wbuf
 */
#ifdef ADF_SUPPORT
#include <osdep_adf.h>
#define M_FLAG_SET    N_FLAG_SET
#define M_FLAG_GET    N_FLAG_GET
#define M_FLAG_CLR    N_FLAG_CLR

#define M_AMSDU       N_AMSDU
#define M_EAPOL       N_EAPOL
#define M_QOSNULL     N_QOSNULL
#define M_ARP         N_ARP
#define M_DHCP        N_DHCP
#define M_ERROR       N_ERROR
#define M_FF          N_FF
#define M_ENCAP_DONE  N_ENCAP_DONE
#define M_UAPSD       N_UAPSD

#define M_FMSS        N_FMSS
#define M_FMSQID      N_FMSQID

#define M_CLONED_CLR    N_CLONED_CLR
#define M_CLONED_GET    N_CLONED_GET
#define M_CLONED_SET    N_CLONED_SET

#define M_MOREDATA_CLR  N_MOREDATA_CLR
#define M_MOREDATA_GET  N_MOREDATA_GET
#define M_MOREDATA_SET  N_MOREDATA_SET

#define M_PROBING_CLR   N_PROBING_CLR
#define M_PROBING_GET   N_PROBING_GET
#define M_PROBING_SET   N_PROBING_SET

#define M_PWR_SAV_CLR   N_PWR_SAV_CLR
#define M_PWR_SAV_GET   N_PWR_SAV_GET
#define M_PWR_SAV_SET   N_PWR_SAV_SET

#if UMAC_SUPPORT_SMARTANTENNA
#define __wbuf_sa_get_antenna              N_ANT_GET
#define __wbuf_sa_get_rateidx              N_RATE_INDEX_GET
#define __wbuf_is_sa_train_packet          N_TRAIN_PKT_IS
#define __wbuf_is_sa_train_lastpacket      N_TRAIN_LASTPKT_IS 

#define __wbuf_sa_set_antenna              N_ANT_SET
#define __wbuf_sa_set_rateidx              N_RATE_INDEX_SET
#define __wbuf_sa_set_train_packet         N_TRAIN_PKT_SET
#define __wbuf_sa_unset_train_packet       N_TRAIN_PKT_UNSET
#define __wbuf_sa_set_train_lastpacket     N_TRAIN_LASTPKT_SET 
#endif

#ifdef ATH_SUPPORT_WAPI
#define M_WAI           N_WAI
#endif

#else
#include <osdep.h>
#endif

typedef struct sk_buff *__wbuf_t;
#define OSDEP_EAPOL_TID 6  /* send it on VO queue */


#if LMAC_SUPPORT_POWERSAVE_QUEUE
#define M_LEGACY_PS     0x80000
#endif
/*
 * WBUF private API's for Linux
 */

/*
 * NB: This function shall only be called for wbuf
 * with type WBUF_RX or WBUF_RX_INTRENAL.
 */
#if USE_MULTIPLE_BUFFER_RCV 
/* 
   When using multiple recv buffer, wbuf_init 
   should reset skb tailroom to zero.
 */
#define __wbuf_init(_skb, _pktlen)  do {    \
    skb_trim(_skb, _skb->len);              \
    skb_put(_skb, _pktlen);                 \
    (_skb)->protocol = ETH_P_CONTROL;       \
} while (0)
#else
#define __wbuf_init(_skb, _pktlen)  do {    \
    skb_put(_skb, _pktlen);                 \
    (_skb)->protocol = ETH_P_CONTROL;       \
} while (0)
#endif

#define __wbuf_header(_skb)                 ((_skb)->data)

/*
 * NB: The following two API's only work when skb's header
 * has not been ajusted, i.e., no one calls skb_push or skb_pull
 * on this skb yet.
 */
#define __wbuf_raw_data(_skb)               ((_skb)->data)

#if USE_MULTIPLE_BUFFER_RECV
#define __wbuf_get_len(_skb)                (((struct ieee80211_cb *)skb->cb)->buf_size)
#else
#define __wbuf_get_len(_skb)                skb_tailroom(_skb)
#endif

#define __wbuf_get_datalen_temp(_skb)       ((_skb)->len)

#define __wbuf_get_pktlen(_skb)             ((_skb)->len)
#define __wbuf_get_tailroom(_skb)           skb_tailroom(_skb)
#define __wbuf_get_priority(_skb)           ((_skb)->priority)
#define __wbuf_set_priority(_skb, _p)       ((_skb)->priority = (_p))

#define __wbuf_hdrspace(_skb)               skb_headroom(_skb)

#define __wbuf_next(_skb)                   ((_skb)->next)
#define __wbuf_next_buf(_skb)               ((_skb)->next)
#define __wbuf_set_next(_skb,_next)         ((_skb)->next = (_next))
#define __wbuf_setnextpkt(_skb,_next)       ((_skb)->next = (_next))

#define __wbuf_free(_skb)                   dev_kfree_skb(_skb)
#define __wbuf_ref(skb)                     skb_get(skb)

#define __wbuf_push(_skb, _len)             skb_push(_skb, _len)
#define __wbuf_clone(_osdev, _skb)          skb_copy(_skb, GFP_ATOMIC)
#define __wbuf_trim(_skb, _len)             skb_trim(_skb, ((_skb)->len - (_len)))
#define __wbuf_pull(_skb, _len)             skb_pull(_skb, _len)
#define __wbuf_set_age(_skb,v)              ((_skb)->csum = v)
#define __wbuf_get_age(_skb)                ((_skb)->csum)
#ifdef ATH_SUPPORT_HTC
#define __wbuf_complete(_skb)               dev_kfree_skb_any(_skb);
#else
#define __wbuf_complete(_skb)               dev_kfree_skb(_skb);
#endif

#define __wbuf_copydata(_skb, _offset, _len, _to)   \
    skb_copy_bits((_skb), (_offset), (_to), (_len))
#define __wbuf_copy(_skb)                   skb_copy(_skb, GFP_ATOMIC)

#define wbuf_set_pktlen(_wbuf, _len)         __wbuf_set_pktlen(_wbuf, _len)
#define wbuf_set_len                         __wbuf_set_pktlen
#define wbuf_set_smpsactframe(_skb)                 
#define wbuf_is_smpsactframe(wbuf)                0  
#define wbuf_set_moredata(wbuf)             __wbuf_set_moredata(wbuf)
#define wbuf_set_smpsframe(wbuf)          
#define wbuf_set_status(_wbuf, _s)          __wbuf_set_status(_wbuf, _s)
#define wbuf_get_status(_wbuf)              __wbuf_get_status(_wbuf)
#define wbuf_is_moredata(wbuf)             __wbuf_is_moredata(wbuf)
#define wbuf_set_type(wbuf,type)           __wbuf_set_type(wbuf,type)
#define wbuf_get_type(wbuf)                __wbuf_get_type(wbuf)
#define wbuf_set_initimbf(wbuf)

#if 0
int __wbuf_is_smpsframe(struct sk_buff *skb);
void __wbuf_set_qosframe(struct sk_buff *skb);
int __wbuf_is_qosframe(struct sk_buff *skb);
#endif

int __wbuf_map_sg(osdev_t osdev, struct sk_buff *skb, dma_context_t context, void *arg);
void __wbuf_unmap_sg(osdev_t osdev, struct sk_buff *skb, dma_context_t context);
dma_addr_t __wbuf_map_single_tx(osdev_t osdev, struct sk_buff *skb, int direction, dma_context_t context);
void __wbuf_uapsd_update(struct sk_buff *skb);

int wbuf_start_dma(struct sk_buff *skb, sg_t *sg, u_int32_t n_sg, void *arg);

#if (LINUX_VERSION_CODE < KERNEL_VERSION(2,6,22))
  #define  UNI_SKB_END_POINTER(skb)   (skb)->end
#else
  #define  UNI_SKB_END_POINTER(skb)    skb_end_pointer(skb)
#endif

static INLINE dma_addr_t
__wbuf_map_single(osdev_t osdev, struct sk_buff *skb, int direction, dma_addr_t *pa)
{
    /*
     * NB: do NOT use skb->len, which is 0 on initialization.
     * Use skb's entire data area instead.
     */
    *pa = bus_map_single(osdev, skb->data, UNI_SKB_END_POINTER(skb) - skb->data, direction);

    return *pa;
}

static INLINE void
__wbuf_unmap_single(osdev_t osdev, struct sk_buff *skb, int direction, dma_addr_t *pa)
{
    /*
     * Unmap skb's entire data area.
     */
    bus_unmap_single(osdev, *pa, UNI_SKB_END_POINTER(skb) - skb->data, direction);
}

static INLINE void
__wbuf_set_pktlen(struct sk_buff *skb, uint32_t len)
{
    if (skb->len > len) {
        skb_trim(skb, len);
    }
    else {
        skb_put(skb, (len - skb->len));
    }
}
static INLINE int
__wbuf_append(struct sk_buff *skb, u_int16_t size)
{
    skb_put(skb, size);
    return 0;
}

static INLINE __wbuf_t 
__wbuf_coalesce(osdev_t os_handle, struct sk_buff *skb)
{
    /* The sk_buff is already contiguous in memory, no need to coalesce. */
    return skb;
}

static INLINE void
__wbuf_set_pwrsaveframe(struct sk_buff *skb)
{
    M_PWR_SAV_SET(skb);
}

static INLINE int 
__wbuf_is_pwrsaveframe(struct sk_buff *skb)
{
    if (M_PWR_SAV_GET(skb))
        return 1;
    else
        return 0;
}

static INLINE void
__wbuf_set_node(struct sk_buff *skb, struct ieee80211_node *ni)
{
    ((struct ieee80211_cb *)skb->cb)->ni = ni;
}

static INLINE void
__wbuf_set_exemption_type(struct sk_buff *skb, int type)
{
   ((struct ieee80211_cb *)skb->cb)->exemptiontype = type;

}

static INLINE int
__wbuf_get_exemption_type(struct sk_buff *skb)
{
    return ((struct ieee80211_cb *)skb->cb)->exemptiontype;
}


static INLINE void
__wbuf_set_type(struct sk_buff *skb, int type)
{
   ((struct ieee80211_cb *)skb->cb)->type = type;

}

static INLINE int
__wbuf_get_type(struct sk_buff *skb)
{
    return ((struct ieee80211_cb *)skb->cb)->type;
}

static INLINE int 
__wbuf_get_tid(struct sk_buff *skb)
{
    return ((struct ieee80211_cb *)skb->cb)->u_tid; 
}

static INLINE int
__wbuf_is_qosframe(struct sk_buff *skb)
{
    return 0;
}

static INLINE int
__wbuf_is_smpsframe(struct sk_buff *skb)
{
    return 0;
}

static INLINE void
__wbuf_set_eapol(struct sk_buff *skb)
{
     M_FLAG_SET(skb, M_EAPOL);
}

static INLINE int
__wbuf_is_eapol(struct sk_buff *skb)
{
    if (M_FLAG_GET(skb, M_EAPOL))
        return 1;
    else
        return 0;
}

static INLINE int
__wbuf_is_dhcp(struct sk_buff *skb)
{
    if (M_FLAG_GET(skb, M_DHCP))
        return 1;
    else
        return 0;
}

static INLINE void
__wbuf_set_dhcp(struct sk_buff *skb)
{
     M_FLAG_SET(skb, M_DHCP);
}

static INLINE int
__wbuf_is_arp(struct sk_buff *skb)
{
    if (M_FLAG_GET(skb, M_ARP))
        return 1;
    else
        return 0;
}

static INLINE void
__wbuf_set_arp(struct sk_buff *skb)
{
     M_FLAG_SET(skb, M_ARP);
}

static INLINE int
__wbuf_is_qosnull(struct sk_buff *skb)
{
    if (M_FLAG_GET(skb, M_QOSNULL))
        return 1;
    else
        return 0;
}

static INLINE void
__wbuf_set_qosnull(struct sk_buff *skb)
{
     M_FLAG_SET(skb, M_QOSNULL);
}

#ifdef ATH_SUPPORT_WAPI
static INLINE void
__wbuf_set_wai(struct sk_buff *skb)
{
     M_FLAG_SET(skb, M_WAI);
}

static INLINE int
__wbuf_is_wai(struct sk_buff *skb)
{
    if (M_FLAG_GET(skb, M_WAI))
        return 1;
    else
        return 0;
}
#endif

static INLINE int
__wbuf_is_encap_done(struct sk_buff *skb)
{
    if (M_FLAG_GET(skb, M_ENCAP_DONE))
        return 1;
    else 
        return 0;
}
static INLINE void
__wbuf_set_encap_done(struct sk_buff *skb)
{
    M_FLAG_SET(skb, M_ENCAP_DONE);
}
static INLINE void
__wbuf_clr_encap_done(struct sk_buff *skb)
{
    M_FLAG_CLR(skb, M_ENCAP_DONE);
}

static INLINE struct ieee80211_node * 
__wbuf_get_node(struct sk_buff *skb)
{
    return ((struct ieee80211_cb *)skb->cb)->ni;
}

static INLINE void 
__wbuf_set_qosframe(struct sk_buff *skb)
{

}

static INLINE void
__wbuf_set_tid(struct sk_buff *skb, u_int8_t tid)
{
    ((struct ieee80211_cb *)skb->cb)->u_tid = tid;
}

static INLINE void
__wbuf_set_rate(struct sk_buff *skb, int8_t rate)
{

}

static INLINE int32_t
__wbuf_get_rate(struct sk_buff *skb)
{
    return 0;
}

static INLINE void
__wbuf_set_retries(struct sk_buff *skb, int8_t retries)
{

}

static INLINE int32_t
__wbuf_get_retries(struct sk_buff *skb)
{
    return 0;
}

static INLINE void
__wbuf_set_txpower(struct sk_buff *skb, int8_t txpower)
{

}

static INLINE int32_t
__wbuf_get_txpower(struct sk_buff *skb)
{
    return 0;
}

static INLINE void
__wbuf_set_txchainmask(struct sk_buff *skb, int8_t txchainmask)
{

}

static INLINE int32_t
__wbuf_get_txchainmask(struct sk_buff *skb)
{
    return 0;
}

static INLINE void
__wbuf_set_status(struct sk_buff *skb, u_int8_t status)
{
    if(status != WB_STATUS_OK)
        ((struct ieee80211_cb *)skb->cb)->flags |= M_ERROR;
}

static INLINE int
__wbuf_get_status(struct sk_buff *skb)
{
    if((((struct ieee80211_cb *)skb->cb)->flags & M_ERROR) == 0)
        return WB_STATUS_OK;

    return WB_STATUS_TX_ERROR;
}


static INLINE void * 
__wbuf_get_context(struct sk_buff *skb)
{
    return (void *)skb;
}
static INLINE void
__wbuf_set_amsdu(struct sk_buff *skb)
{
    M_FLAG_SET(skb, M_AMSDU);
}
static INLINE int
__wbuf_is_amsdu(struct sk_buff *skb)
{
    if (M_FLAG_GET(skb, M_AMSDU))
        return 1;
    else
        return 0;
}

static INLINE u_int8_t *
__wbuf_get_scatteredbuf_header(__wbuf_t wbuf, u_int16_t len)
{
    u_int8_t *pHead = NULL;
    return pHead;
}

static INLINE void 
__wbuf_set_fastframe(struct sk_buff *skb)
{
    M_FLAG_SET(skb, M_FF);
}
static INLINE int 
__wbuf_is_fastframe(struct sk_buff *skb)
{
    if (M_FLAG_GET(skb, M_FF))
        return 1;
    else
        return 0;
}

#ifdef ATH_SUPPORT_UAPSD
static INLINE void
__wbuf_set_uapsd(struct sk_buff *skb)
{
   M_FLAG_SET(skb, M_UAPSD);
}

static INLINE void
__wbuf_clear_uapsd(struct sk_buff *skb)
{
   M_FLAG_CLR(skb, M_UAPSD);
}

static INLINE int
__wbuf_is_uapsd(struct sk_buff *skb)
{
    if (M_FLAG_GET(skb, M_UAPSD))
        return 1;
    else
        return 0;
}
#endif

#if UMAC_SUPPORT_WNM 
static INLINE void
__wbuf_set_fmsstream(struct sk_buff *skb)
{
   M_FLAG_SET(skb, M_FMSS);
}

static INLINE void
__wbuf_clear_fmsstream(struct sk_buff *skb)
{
   M_FLAG_CLR(skb, M_FMSS);
}

static INLINE int
__wbuf_is_fmsstream(struct sk_buff *skb)
{
    if (M_FLAG_GET(skb, M_FMSS))
        return 1;
    else
        return 0;
}

static INLINE u_int8_t
__wbuf_get_fmsqid(struct sk_buff *skb)
{
    if (!skb) return 0;
    return ((struct ieee80211_cb *)skb->cb)->fmsq_id;
}

static INLINE void
__wbuf_set_fmsqid(struct sk_buff *skb, u_int8_t fmsq_id)
{
    if (!skb) return;
    ((struct ieee80211_cb *)skb->cb)->fmsq_id = fmsq_id;
}

#endif /* UMAC_SUPPORT_WNM */


#if LMAC_SUPPORT_POWERSAVE_QUEUE
static INLINE void
__wbuf_set_legacy_ps(struct sk_buff *skb)
{
   M_FLAG_SET(skb, M_LEGACY_PS);
}

static INLINE void
__wbuf_clear_legacy_ps(struct sk_buff *skb)
{
   M_FLAG_CLR(skb, M_LEGACY_PS);
}

static INLINE int
__wbuf_is_legacy_ps(struct sk_buff *skb)
{
    if (M_FLAG_GET(skb, M_LEGACY_PS))
        return 1;
    else
        return 0;
}
#endif

static INLINE int
__wbuf_is_initimbf(struct sk_buff *skb)
{
    return 0;
}

static INLINE void
wbuf_tx_remove_8021q(struct sk_buff *skb)
{
}

static INLINE void
wbuf_tx_recovery_8021q(struct sk_buff *skb)
{
}

static INLINE void
wbuf_SetWMMInfo(struct sk_buff *skb, int tid)
{
}

static INLINE int
wbuf_classify(struct sk_buff *skb)
{
    struct ether_header *eh = (struct ether_header *) skb->data;
    u_int8_t tos = 0;
    /*
     * Find priority from IP TOS DSCP field
     */
    if (eh->ether_type == __constant_htons(ETHERTYPE_IP))
    {
        const struct iphdr *ip = (struct iphdr *)
                    (skb->data + sizeof (struct ether_header));
        /*
         * IP frame: exclude ECN bits 0-1 and map DSCP bits 2-7
         * from TOS byte.
         */
        tos = (ip->tos & (~INET_ECN_MASK)) >> IP_PRI_SHIFT;
    }
    else if (eh->ether_type == htons(ETHERTYPE_IPV6)) {
        /* TODO
	 * use flowlabel
	 */
        unsigned long ver_pri_flowlabel;
	unsigned long pri;
	/*
            IPv6 Header.
            +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
            |Version| TrafficClass. |                   Flow Label          |
            +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
            |         Payload Length        |  Next Header  |   Hop Limit   |
            +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
            |                                                               |
            +                                                               +
            |                                                               |
            +                         Source Address                        +
            |                                                               |
            +                                                               +
            |                                                               |
            +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
            |                                                               |
            +                                                               +
            |                                                               |
            +                      Destination Address                      +
            |                                                               |
            +                                                               +
            |                                                               |
            +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
	*/

        ver_pri_flowlabel = *(unsigned long*)(eh + 1);
        pri = (ntohl(ver_pri_flowlabel) & IPV6_PRIORITY_MASK) >> IPV6_PRIORITY_SHIFT;
        tos = (pri & (~INET_ECN_MASK)) >> IP_PRI_SHIFT;
    }
    else if (eh->ether_type == __constant_htons(ETHERTYPE_PAE)) {
        /* mark as EAPOL frame */
         M_FLAG_SET(skb, M_EAPOL);
         tos = OSDEP_EAPOL_TID;  /* send it on VO queue */;
    }
#ifdef ATH_SUPPORT_WAPI
    else if (eh->ether_type == __constant_htons(ETHERTYPE_WAI)) {
        /* mark as WAI frame */
         M_FLAG_SET(skb, M_WAI);
         tos = OSDEP_EAPOL_TID;  /* send it on VO queue */;
    }
#endif

    return tos;
}

static INLINE int
wbuf_UserPriority(struct sk_buff *skb)
{
    return 0;
}

static INLINE int
wbuf_VlanId(struct sk_buff *skb)
{
    return 0;
}

#if ATH_SUPPORT_VLAN

#define VLAN_PRI_SHIFT  13
#define VLAN_PRI_MASK   7

/*
** Public Prototypes
*/

unsigned short adf_net_get_vlan(osdev_t osif);

int adf_net_is_vlan_defined(osdev_t osif);


static INLINE int
wbuf_8021p(struct sk_buff *skb)
{
    struct vlan_ethhdr *veth = (struct vlan_ethhdr *) skb->data;
    u_int8_t tos = 0;

    /*
    ** Determine if this is an 802.1p frame, and get the proper
    ** priority information as required
    */

    if ( veth->h_vlan_proto == __constant_htons(ETH_P_8021Q) )
    {
        tos = (veth->h_vlan_TCI >> VLAN_PRI_SHIFT) & VLAN_PRI_MASK;
    }

    return tos;
}

static INLINE int
adf_net_get_vlan_tag(struct sk_buff *skb)
{
    return ( vlan_tx_tag_get(skb) );
}

static INLINE int
adf_net_vlan_tag_present(struct sk_buff *skb)
{
    return ( vlan_tx_tag_present(skb) );
}

#endif

static INLINE void
wbuf_concat(struct sk_buff *head, struct sk_buff *skb)
{
    if (skb_is_nonlinear(head))
    {
        KASSERT(0,("wbuf_concat: skb is nonlinear"));
    }
    if (skb_tailroom(head) < skb->len)
    {
#if USE_MULTIPLE_BUFFER_RCV

        /* For multiple buffer case, it's not a abnormal case if tailroom is 
         * not enough. We should not call assert but handle it carefully.
         */

        if (!pskb_expand_head(head, 
                              0, __wbuf_get_len(skb),
                              GFP_ATOMIC))
        {
            dev_kfree_skb(skb);
            return;
        }
#else
        KASSERT(0,("wbuf_concat: Not enough space to concat"));
#endif
    }
    /* copy the skb data to the head */
    memcpy(head->tail, skb->data, skb->len);
    /* Update tail and length */
    skb_put(head, skb->len);
    /* free the skb */
    dev_kfree_skb(skb);
}
static INLINE void
__wbuf_set_moredata(struct sk_buff *skb)
{
    M_MOREDATA_SET(skb);
}

static INLINE int 
__wbuf_is_moredata(struct sk_buff *skb)
{
    if (M_MOREDATA_GET(skb))
        return 1;
    else
        return 0;
}

static INLINE void
__wbuf_set_probing(struct sk_buff *skb)
{
    M_PROBING_SET(skb);
}

static INLINE void
__wbuf_clear_probing(struct sk_buff *skb)
{
    M_PROBING_CLR(skb);
}

static INLINE int
__wbuf_is_probing(struct sk_buff *skb)
{
    if (M_PROBING_GET(skb))
        return 1;
    else
        return 0;
}

#if ATH_SUPPORT_WIFIPOS
static INLINE void
__wbuf_set_pos(struct sk_buff *skb)
{
    M_LOC_SET(skb);
}

static INLINE void
__wbuf_clear_pos(struct sk_buff *skb)
{
    M_LOC_CLR(skb);
}

static INLINE void
__wbuf_set_wifipos(struct sk_buff *skb, void *data) 
{
	return;
}


static INLINE void *
__wbuf_get_wifipos(struct sk_buff *skb) 
{
	return NULL;
}

static INLINE u_int32_t
__wbuf_get_wifipos_req_id(struct sk_buff *skb)
{
    return 0;
}

static INLINE void
__wbuf_set_wifipos_req_id(struct sk_buff *skb, u_int32_t request_id)
{
	return;
}

static INLINE int
__wbuf_is_pos(struct sk_buff *skb)
{
    if (M_LOC_GET(skb))
        return 1;
    else
        return 0;
}

static INLINE void
__wbuf_set_keepalive(struct sk_buff *skb)
{
    M_LOC_KEEPALIVE_SET(skb);
}

static INLINE int
__wbuf_is_keepalive(struct sk_buff *skb)
{
    if (M_LOC_KEEPALIVE_GET(skb))
        return 1;
    else
        return 0;
}

static INLINE void
__wbuf_set_cts_frame(struct sk_buff *skb) 
{
    return;
}


static INLINE int
__wbuf_get_cts_frame(struct sk_buff *skb) 
{
    return 0;
}
#endif

static INLINE void
__wbuf_set_cloned(struct sk_buff *skb)
{
    M_CLONED_SET(skb);
}

static INLINE void
__wbuf_clear_cloned(struct sk_buff *skb)
{
    M_CLONED_CLR(skb);
}

static INLINE int
__wbuf_is_cloned(struct sk_buff *skb)
{
    if (M_CLONED_GET(skb))
        return 1;
    else
        return 0;
}
static INLINE void 
__wbuf_set_complete_handler(struct sk_buff *skb,void *handler, void *arg)
{
#if defined(ATH_SUPPORT_P2P) ||(defined(ATH_SUPPORT_DEFERRED_NODE_CLEANUP) && ATH_SUPPORT_DEFERRED_NODE_CLEANUP !=0)
    struct ieee80211_cb *ctx = (struct ieee80211_cb *)skb->cb;
    ctx->complete_handler = handler;
    ctx->complete_handler_arg = arg;
#endif
}

static INLINE void 
__wbuf_get_complete_handler(struct sk_buff *skb,void **handler, void **arg)
{
#if defined(ATH_SUPPORT_P2P) ||(defined(ATH_SUPPORT_DEFERRED_NODE_CLEANUP) && ATH_SUPPORT_DEFERRED_NODE_CLEANUP !=0)
    struct ieee80211_cb *ctx = (struct ieee80211_cb *)skb->cb;
    *handler = ctx->complete_handler;
    *arg = ctx->complete_handler_arg;
#else
    *handler = NULL;
    *arg = NULL;
#endif
}

#ifdef ATH_SUPPORT_HTC
__wbuf_t __wbuf_realloc_hdrspace(__wbuf_t wbuf, u_int16_t size);
int __wbuf_cat(__wbuf_t dst, __wbuf_t src);
#endif

#if defined(ATH_SUPPORT_VOWEXT) || defined(ATH_SUPPORT_IQUE) || defined(VOW_LOGLATENCY) || UMAC_SUPPORT_NAWDS != 0
static INLINE u_int8_t
__wbuf_get_firstxmit(struct sk_buff *skb)
{
    if (!skb) return 0;
    return ((struct ieee80211_cb *)skb->cb)->firstxmit;
}
static INLINE void
__wbuf_set_firstxmit(struct sk_buff *skb, u_int8_t firstxmit)
{
    if (!skb) return;
    ((struct ieee80211_cb *)skb->cb)->firstxmit = firstxmit;
}

static INLINE u_int32_t
__wbuf_get_firstxmitts(struct sk_buff *skb)
{
    if (!skb) return 0;
#ifdef ADF_SUPPORT
    return ((struct ieee80211_cb *)skb->cb)->_u.firstxmitts;
#else
    return ((struct ieee80211_cb *)skb->cb)->firstxmitts;
#endif // ADF_SUPPORT
}
static INLINE void
__wbuf_set_firstxmitts(struct sk_buff *skb, u_int32_t firstxmitts)
{
    if (!skb) return;
#ifdef ADF_SUPPORT
    ((struct ieee80211_cb *)skb->cb)->_u.firstxmitts = firstxmitts;
#else
    ((struct ieee80211_cb *)skb->cb)->firstxmitts = firstxmitts;
#endif // ADF_SUPPORT
}

static INLINE void
__wbuf_clear_flags(struct sk_buff *skb)
{
    M_FLAG_CLR(skb, 0xFFFF);
}
#endif /* ATH_SUPPORT_VOWEXT*/

#if defined(VOW_TIDSCHED) || defined (ATH_SUPPORT_IQUE) || defined(VOW_LOGLATENCY)
static INLINE u_int32_t
__wbuf_get_qin_timestamp(struct sk_buff *skb)
{
    if (!skb) return 0;
    return ((struct ieee80211_cb *)skb->cb)->qin_timestamp;
}
static INLINE void
__wbuf_set_qin_timestamp(struct sk_buff *skb, u_int32_t qin_timestamp)
{
    if (!skb) return;
    ((struct ieee80211_cb *)skb->cb)->qin_timestamp = qin_timestamp;
}
#endif

#if UMAC_SUPPORT_RPTPLACEMENT || ATH_SUPPORT_AOW || ATH_SUPPORT_WIFIPOS
static INLINE void
__wbuf_set_netlink_pid(struct sk_buff *skb, u_int32_t val)
{
    NETLINK_CB(skb).pid = val;
}
#if LINUX_VERSION_CODE < KERNEL_VERSION(2,6,20)	
static INLINE void
__wbuf_set_netlink_dst_pid(struct sk_buff *skb, u_int32_t val)
{
    NETLINK_CB(skb).dst_pid = val;
}
#endif    
static INLINE void
__wbuf_set_netlink_dst_group(struct sk_buff *skb, u_int32_t val)
{
    NETLINK_CB(skb).dst_group = val;
}
#endif /*UMAC_SUPPORT_RPTPLACEMENT || ATH_SUPPORT_AOW || ATH_SUPPORT_WIFIPOS*/

#endif // #ifdef WBUF_PRIVATE_LINUX_H
