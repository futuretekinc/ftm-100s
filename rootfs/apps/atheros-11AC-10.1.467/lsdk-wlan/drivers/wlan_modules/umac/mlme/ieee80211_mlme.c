/*
 *  Copyright (c) 2008 Atheros Communications Inc. 
 * All Rights Reserved.
 * 
 * Copyright (c) 2011 Qualcomm Atheros, Inc.
 * All Rights Reserved.
 * Qualcomm Atheros Confidential and Proprietary.
 * 
 */
#include "ieee80211_mlme_priv.h"    /* Private to MLME module */
#ifdef CONFIG_CS75XX_WFO_AR9580
extern u32 cs_wfo_rate_adjust;
extern bool CS_AR9580_WFO_TX_mac_entry_delete(struct ath_softc_net80211 *scn, struct ieee80211_node *ni);
extern bool CS_AR9580_WFO_mac_entry_timer_delete(struct ath_softc_net80211 *scn, struct ieee80211_node *ni);
#endif

/* Local function prototypes */
static OS_TIMER_FUNC(timeout_callback);
static void mlme_timeout_callback(struct ieee80211vap *vap, IEEE80211_STATUS  ieeeStatus);
static void sta_disassoc(void *arg, struct ieee80211_node *ni);
void sta_deauth(void *arg, struct ieee80211_node *ni);


/*
 * Public MLME APIs (within UMAC, ieee80211_mlme_*)
 */
int ieee80211_mlme_attach(struct ieee80211com *ic)
{
    return 0;
} 

int ieee80211_mlme_detach(struct ieee80211com *ic)
{
    return 0;
}

int ieee80211_mlme_vattach(struct ieee80211vap *vap)
{
    struct ieee80211com     *ic = vap->iv_ic;
    ieee80211_mlme_priv_t    mlme_priv;

#if 0
    vap->iv_debug |= IEEE80211_MSG_MLME;
#endif

    if (vap->iv_mlme_priv) {
        ASSERT(vap->iv_mlme_priv == 0);
        return -1; /* already attached ? */
    }

    mlme_priv = (ieee80211_mlme_priv_t) OS_MALLOC(ic->ic_osdev, (sizeof(struct ieee80211_mlme_priv)),0);
    vap->iv_mlme_priv = mlme_priv;

    if (mlme_priv == NULL) {
       return -ENOMEM;
    } else {
        OS_MEMZERO(mlme_priv, sizeof(*mlme_priv));
        mlme_priv->im_vap = vap; 
        mlme_priv->im_osdev = ic->ic_osdev; 
        OS_INIT_TIMER(ic->ic_osdev, &mlme_priv->im_timeout_timer, 
                      timeout_callback, vap);
        /* Default configuration values */
        mlme_priv->im_disassoc_timeout = MLME_DEFAULT_DISASSOCIATION_TIMEOUT;
        switch(vap->iv_opmode) {
        case IEEE80211_M_IBSS:
            mlme_adhoc_vattach(vap);
            break;
        case IEEE80211_M_STA:
            mlme_sta_vattach(vap);
            break;
        default:
            break;
        } 


        return 0;
    }
} 

int ieee80211_mlme_vdetach(struct ieee80211vap *vap)
{
    ieee80211_mlme_priv_t    mlme_priv = vap->iv_mlme_priv;
    int                      ftype;

    if (mlme_priv == NULL) {
        ASSERT(mlme_priv);
        return -1; /* already detached ? */
    }

    OS_CANCEL_TIMER(&mlme_priv->im_timeout_timer);
    OS_FREE_TIMER(&mlme_priv->im_timeout_timer);
	
    switch(vap->iv_opmode) {
    case IEEE80211_M_IBSS:
        mlme_adhoc_vdetach(vap);
        break;
    case IEEE80211_M_STA:
        mlme_sta_vdetach(vap);
        break;
    default:
        break;
    } 
    OS_FREE(mlme_priv);
    vap->iv_mlme_priv = NULL;

    /* Free app ie buffers */
    for (ftype = 0; ftype < IEEE80211_FRAME_TYPE_MAX; ftype++) {
        if (vap->iv_app_ie[ftype].ie) {
            OS_FREE(vap->iv_app_ie[ftype].ie);
            vap->iv_app_ie[ftype].ie = NULL;
            vap->iv_app_ie[ftype].length = 0;
        }
    }
    /* Make sure we have release all the App IE */
    for (ftype = 0; ftype < IEEE80211_FRAME_TYPE_MAX; ftype++) {
        ASSERT(LIST_EMPTY(&vap->iv_app_ie_list[ftype]));
    }

    /* Free opt ie buffer */
    if (vap->iv_opt_ie.ie) {
        OS_FREE(vap->iv_opt_ie.ie);
        vap->iv_opt_ie.ie = NULL;
        vap->iv_opt_ie.length = 0;
    }

    if (vap->iv_beacon_copy_buf) {
        void *pTmp = vap->iv_beacon_copy_buf;
        vap->iv_beacon_copy_buf = NULL;
        vap->iv_beacon_copy_len = 0;
        OS_FREE(pTmp);
    }

    return 0;
}

int wlan_mlme_auth(wlan_if_t vaphandle, u_int8_t *macaddr, u_int16_t seq, u_int16_t status, 
                   u_int8_t *challenge_txt, u_int8_t challenge_len,
                   struct ieee80211_app_ie_t* optie)
{
    struct ieee80211vap      *vap = vaphandle;
    struct ieee80211_node    *ni;
    int                      error = 0;

    IEEE80211_DPRINTF(vap, IEEE80211_MSG_MLME, "%s status %d \n", __func__, status);
    

    ni = ieee80211_find_node(&vap->iv_ic->ic_sta, macaddr);
    if (ni == NULL) {
        error = -ENOMEM;
        return error;
    }

    /* Send auth frame */
    if (status != IEEE80211_STATUS_SUCCESS) {
        ni->ni_authstatus = status;
    }
    ieee80211_send_auth(ni, seq, ni->ni_authstatus, challenge_txt, challenge_len, optie);

    if (ni->ni_authstatus != IEEE80211_STATUS_SUCCESS) {
        /* auth is not success, remove the node from node table */
        IEEE80211_DPRINTF(vap, IEEE80211_MSG_MLME, "%s auth failed with status %d \n", __func__, ni->ni_authstatus);
        IEEE80211_NODE_LEAVE(ni);
        error = -EIO;     
    }


    /* claim node immediately */
    ieee80211_free_node(ni);

    return error;
}

int wlan_mlme_assoc_resp(wlan_if_t vaphandle, u_int8_t *macaddr, IEEE80211_REASON_CODE reason, int reassoc,
                         struct ieee80211_app_ie_t* optie)
{
    struct ieee80211vap      *vap = vaphandle;
    struct ieee80211_node    *ni;
    int                      error = 0;

    IEEE80211_DPRINTF(vap, IEEE80211_MSG_MLME, "%s reason %d reassoc %d \n", __func__, reason, reassoc);

    ni = ieee80211_find_node(&vap->iv_ic->ic_sta, macaddr);
    if (ni == NULL) {
        error = -EIO;
        return error;
    }

    /* Send assoc frame */
    error = ieee80211_send_assocresp(ni, reassoc, reason, optie);
    
    if (error || (reason != IEEE80211_STATUS_SUCCESS)) {
        IEEE80211_DPRINTF(vap, IEEE80211_MSG_MLME, "%s assoc failed with status %d \n", __func__, reason);
        if ((!ieee80211_is_pmf_enabled(vap, ni)) || (reason != IEEE80211_STATUS_REJECT_TEMP)) {
            /* Remove the node from node table only in non-PMF assoc
             * or reason is other than REJECT_TEMP
             */
            IEEE80211_NODE_LEAVE(ni);
        } else {
            IEEE80211_DPRINTF(vap, IEEE80211_MSG_MLME, "%s PMF enabled with reason %d so not removing node\n",
                                 __func__, reason);
        }
    }

    /* claim node immediately */
    ieee80211_free_node(ni);

    return error;
}

/*
 * Public MLME APIs (external to UMAC, wlan_mlme_*)
 */

int wlan_mlme_deauth_request(wlan_if_t vaphandle, u_int8_t *macaddr, IEEE80211_REASON_CODE reason)
{
    struct ieee80211vap      *vap = vaphandle;
    struct ieee80211_node    *ni;
    int                      error = 0;

    IEEE80211_DPRINTF(vap, IEEE80211_MSG_MLME, "%s\n", __func__);

    /*
     * if a node exist with the given address already , use it.
     * if not use bss node.
     */
    ni = ieee80211_find_node(&vap->iv_ic->ic_sta, macaddr);
    if (ni == NULL) {
        if(vap->iv_opmode == IEEE80211_M_STA){   
            if(!wlan_vap_is_pmf_enabled(vap)){
                error = -ENOMEM;
                goto exit;
            }
        } else {
            if (!IEEE80211_ADDR_EQ(macaddr, IEEE80211_GET_BCAST_ADDR(vap->iv_ic)))
            {
                error = -EIO;
                goto exit;
            }
        }

        ni = ieee80211_ref_node(vap->iv_bss);

    }

    /* Send deauth frame */
    if(ni) {
        IEEE80211_DPRINTF(vap, IEEE80211_MSG_AUTH, "%s: sending DEAUTH to %s, mlme deauth reason %d\n", 
                __func__, ether_sprintf(ni->ni_macaddr), reason);
    }
    error = ieee80211_send_deauth(ni, reason);

    /* Node needs to be removed from table as well, do it only for AP/IBSS now */
#if ATH_SUPPORT_IBSS
    if ((vap->iv_opmode == IEEE80211_M_HOSTAP && ni != vap->iv_bss) || vap->iv_opmode == IEEE80211_M_IBSS) {
#else
    if (vap->iv_opmode == IEEE80211_M_HOSTAP && ni != vap->iv_bss) {
#if ATH_SUPPORT_AOW
        ieee80211_aow_join_indicate(ni->ni_ic, AOW_STA_DISCONNECTED, ni);
#endif  /* ATH_SUPPORT_AOW */
#endif  /* ATH_SUPPORT_IBSS */
        IEEE80211_NODE_LEAVE(ni);
    }        

    /* claim node immediately */
    ieee80211_free_node(ni);

    if (error) {
        goto exit;
    }

    /* 
     * Call MLME confirmation handler => mlme_deauth_complete 
     * This should reflect the tx completion status of the deauth frame,
     * but since we don't have per frame completion, we'll always indicate success here. 
     */
    IEEE80211_DELIVER_EVENT_MLME_DEAUTH_COMPLETE(vap,macaddr, IEEE80211_STATUS_SUCCESS); 

exit:
    return error;
}

#if ATH_SUPPORT_DEFERRED_NODE_CLEANUP
static void ieee80211_mlme_frame_complete_handler(wlan_if_t vap, wbuf_t wbuf,void *arg,
        u_int8_t *dst_addr, u_int8_t *src_addr, u_int8_t *bssid,
        ieee80211_xmit_status *ts)
{
    struct ieee80211_node *ni = (struct ieee80211_node *)arg;
    if(ni) {
        if(ni->ni_flags & IEEE80211_NODE_DELAYED_CLEANUP) 
        {
            ni->ni_flags &=~ IEEE80211_NODE_DELAYED_CLEANUP;
            IEEE80211_NODE_LEAVE(ni);
        }
    }
    return;
}
#endif
/*
 * Routine to transmit a Disassoc request frame.
 */
int wlan_mlme_disassoc_request(wlan_if_t vaphandle, u_int8_t *macaddr, IEEE80211_REASON_CODE reason)
{
    int retval;
    retval = wlan_mlme_disassoc_request_with_callback(vaphandle, macaddr, reason, NULL, NULL);
    return retval;
}

/*
 * Routine to transmit a Disassoc request frame with a completion callback when done.
 */
int wlan_mlme_disassoc_request_with_callback(
    wlan_if_t vaphandle, 
    u_int8_t *macaddr, 
    IEEE80211_REASON_CODE reason,
    wlan_vap_complete_buf_handler handler,
    void *arg
    )
{
    struct ieee80211vap      *vap = vaphandle;
    struct ieee80211_node    *ni;
    int                      error = 0;

    IEEE80211_DPRINTF(vap, IEEE80211_MSG_MLME, "%s\n", __func__);

    /* Broadcast Addr - disassociate all stations */
    if (IEEE80211_ADDR_EQ(macaddr, IEEE80211_GET_BCAST_ADDR(vap->iv_ic))) {
        if (vap->iv_opmode == IEEE80211_M_STA) {
            IEEE80211_DPRINTF(vap, IEEE80211_MSG_MLME,
                              "%s: unexpected station vap with all 0xff mac address", __func__);
            ASSERT(0);
            goto exit;
		} else {
            /* Iterate station list only when PMF is not enabled */
            if (!wlan_vap_is_pmf_enabled(vap)) {
                wlan_iterate_station_list(vap, sta_disassoc, NULL);
                goto exit;
            }
        }
    }

    /*
     * if a node exist with the given address already , use it.
     * if not use bss node.
     */
    ni = ieee80211_find_node(&vap->iv_ic->ic_sta, macaddr);
    if (ni == NULL) {
        if(vap->iv_opmode == IEEE80211_M_STA){   
            if(!wlan_vap_is_pmf_enabled(vap)){
                error = -ENOMEM;
                goto exit;
            }
        } else {
            if (!IEEE80211_ADDR_EQ(macaddr, IEEE80211_GET_BCAST_ADDR(vap->iv_ic)))
            {
                error = -EIO;
                goto exit;
            }
        }
        ni = ieee80211_ref_node(vap->iv_bss);
    }
#if ATH_SUPPORT_DEFERRED_NODE_CLEANUP
    if((ni->ni_flags & IEEE80211_NODE_DELAYED_CLEANUP)) {
        handler = ieee80211_mlme_frame_complete_handler;
        arg = (void *)ni;
    }
#endif
    /* Send disassoc frame */
    error = ieee80211_send_disassoc_with_callback(ni, reason, handler, arg);

    /* Node needs to be removed from table as well, do it only for AP now */
    if ((vap->iv_opmode == IEEE80211_M_HOSTAP  && ni != vap->iv_bss ) 
            || vap->iv_opmode == IEEE80211_M_IBSS) {
#if ATH_SUPPORT_AOW
        ieee80211_aow_join_indicate(ni->ni_ic, AOW_STA_DISCONNECTED, ni);
#endif  /* ATH_SUPPORT_AOW */
#if ATH_SUPPORT_DEFERRED_NODE_CLEANUP
        if(!(ni->ni_flags & IEEE80211_NODE_DELAYED_CLEANUP))
#endif
        {
            IEEE80211_NODE_LEAVE(ni);
        }
    }
    /* claim node immediately */
    ieee80211_free_node(ni);

    if (error) {
        goto exit;
    }

    /* 
     * Call MLME confirmation handler => mlme_disassoc_complete 
     * This should reflect the tx completion status of the disassoc frame,
     * but since we don't have per frame completion, we'll always indicate success here. 
     */
    IEEE80211_DELIVER_EVENT_MLME_DISASSOC_COMPLETE(vap, macaddr, reason, IEEE80211_STATUS_SUCCESS); 

exit:
    return error;
}


int wlan_mlme_start_bss(wlan_if_t vaphandle)
{
    struct ieee80211vap           *vap = vaphandle;
    struct ieee80211_mlme_priv    *mlme_priv = vap->iv_mlme_priv;
    int                           error = 0;

    IEEE80211_DPRINTF(vap, IEEE80211_MSG_MLME, "%s\n", __func__);

    switch(vap->iv_opmode) {
    case IEEE80211_M_IBSS:
        IEEE80211_DPRINTF(vap, IEEE80211_MSG_MLME, "%s: Create adhoc bss\n", __func__);
        /* Reset state */
        mlme_priv->im_connection_up = 0;

        error = mlme_create_adhoc_bss(vap);
        break;
    case IEEE80211_M_MONITOR:
    case IEEE80211_M_HOSTAP:
    case IEEE80211_M_BTAMP:
        /* 
         * start the AP . the channel/ssid should have been setup already.
         */
        IEEE80211_DPRINTF(vap, IEEE80211_MSG_MLME, "%s: Create infrastructure(AP) bss\n", __func__);
        error = mlme_create_infra_bss(vap);
        break;
    default:
        ASSERT(0);
    }

    return error;
}

bool wlan_coext_enabled(wlan_if_t vaphandle)
{
    struct ieee80211com    *ic = vaphandle->iv_ic;

    return (ic->ic_flags & IEEE80211_F_COEXT_DISABLE) ? FALSE : TRUE;
}

void wlan_determine_cw(wlan_if_t vaphandle, wlan_chan_t channel)
{
    struct ieee80211com    *ic = vaphandle->iv_ic;
    int is_chan_ht40 = channel->ic_flags & (IEEE80211_CHAN_11NG_HT40PLUS |
                                            IEEE80211_CHAN_11NG_HT40MINUS);

    if (is_chan_ht40 && (channel->ic_flags & IEEE80211_CHAN_HT40INTOL)) {
        ic->ic_bss_to20(ic);
    }
}


void
sta_deauth(void *arg, struct ieee80211_node *ni)
{
    struct ieee80211vap    *vap = ni->ni_vap;
    u_int8_t macaddr[6];

    IEEE80211_DPRINTF(vap, IEEE80211_MSG_MLME, "%s: deauth station %s \n",
                      __func__,ether_sprintf(ni->ni_macaddr));
    IEEE80211_ADDR_COPY(macaddr, ni->ni_macaddr);
    if (ni->ni_associd) {
        /*
         * if it is associated, then send disassoc.
         */
        IEEE80211_DPRINTF(vap, IEEE80211_MSG_AUTH, "%s: sending DEAUTH to %s, reason %d\n", 
                __func__, ether_sprintf(ni->ni_macaddr), IEEE80211_REASON_AUTH_LEAVE);
        ieee80211_send_deauth(ni, IEEE80211_REASON_AUTH_LEAVE);
    }
    IEEE80211_NODE_LEAVE(ni);
    IEEE80211_DELIVER_EVENT_MLME_DEAUTH_INDICATION(vap, macaddr, IEEE80211_REASON_AUTH_LEAVE);
}

static void
sta_disassoc(void *arg, struct ieee80211_node *ni)
{
    struct ieee80211vap    *vap = ni->ni_vap;
    u_int8_t macaddr[6];

    IEEE80211_DPRINTF(vap, IEEE80211_MSG_MLME, "%s: disassoc station %s \n",
                      __func__,ether_sprintf(ni->ni_macaddr));
    IEEE80211_ADDR_COPY(macaddr, ni->ni_macaddr);
    if (ni->ni_associd) {
        /*
         * if it is associated, then send disassoc.
         */
        ieee80211_send_disassoc(ni, IEEE80211_REASON_ASSOC_LEAVE);
#if ATH_SUPPORT_AOW
        ieee80211_aow_join_indicate(ni->ni_ic, AOW_STA_DISCONNECTED, ni);
#endif  /* ATH_SUPPORT_AOW */
    }
    IEEE80211_NODE_LEAVE(ni);
    IEEE80211_DELIVER_EVENT_MLME_DISASSOC_COMPLETE(vap, macaddr, 
                                                     IEEE80211_REASON_ASSOC_LEAVE, IEEE80211_STATUS_SUCCESS); 
}


int wlan_mlme_stop_bss(wlan_if_t vaphandle, int flags)
{
#define WAIT_RX_INTERVAL 10000
    u_int32_t                       elapsed_time = 0;
    struct ieee80211vap             *vap = vaphandle;
    struct ieee80211_mlme_priv      *mlme_priv;
    int                             error = 0;

	if ( vap == NULL ) {
		return EINVAL;
	}
	mlme_priv = vap->iv_mlme_priv;

    IEEE80211_DPRINTF(vap, IEEE80211_MSG_MLME, "%s flags = 0x%x\n", __func__, flags);

    /*
     * Wait for current rx path to finish. Assume only one rx thread.
     */
    if (flags & WLAN_MLME_STOP_BSS_F_WAIT_RX_DONE) {
        do {
            if (OS_ATOMIC_CMPXCHG(&vap->iv_rx_gate, 0, 1) == 0) {
                break;
            }

            OS_SLEEP(WAIT_RX_INTERVAL);
            elapsed_time += WAIT_RX_INTERVAL;

            if (elapsed_time > (100 * WAIT_RX_INTERVAL))
               ieee80211_note (vap,"%s: Rx pending count stuck. Investigate!!!\n", __func__);
        } while (1);
    }

    switch(vap->iv_opmode) {
#if UMAC_SUPPORT_IBSS
    case IEEE80211_M_IBSS:
        mlme_stop_adhoc_bss(vap, flags);
        break;
#endif
    case IEEE80211_M_HOSTAP:
    case IEEE80211_M_BTAMP:
         /* If vap is stopped in S_INIT state, resmgr_stop alone enough
            since vap didn't go into RUN state */
        if(vap->iv_state_info.iv_state == IEEE80211_S_INIT) {
           ieee80211_resmgr_vap_stop(vap->iv_ic->ic_resmgr,vap,MLME_REQ_ID);
        }
        /* disassoc/deauth all stations */
        IEEE80211_DPRINTF(vap, IEEE80211_MSG_MLME|IEEE80211_MSG_AUTH, "%s: disassocing/deauth all stations \n", __func__);
        if(vap->iv_send_deauth)
            wlan_iterate_station_list(vap, sta_deauth, NULL);
        else
            wlan_iterate_station_list(vap, sta_disassoc, NULL);
        break;

    case IEEE80211_M_STA:
        /* There should be no mlme requests pending */
        ASSERT(vap->iv_mlme_priv->im_request_type == MLME_REQ_NONE);

        /* Reset state variables */
        mlme_priv->im_connection_up = 0;
        mlme_sta_swbmiss_timer_stop(vap);
        ieee80211_sta_leave(vap->iv_bss);
        break;

    default:
        break;
    }

    if (flags & WLAN_MLME_STOP_BSS_F_FORCE_STOP_RESET) {
        /* put vap in init state */
        ieee80211_vap_stop(vap, TRUE);
    } else {
        /* put vap in stopping state */
        if (flags & WLAN_MLME_STOP_BSS_F_STANDBY)
            ieee80211_vap_standby(vap);
        else
            ieee80211_vap_stop(vap, FALSE);
    }

    if (!(flags & WLAN_MLME_STOP_BSS_F_NO_RESET))
        error = ieee80211_reset_bss(vap);

    /*
     * Release the rx mutex.
     */
    if (flags & WLAN_MLME_STOP_BSS_F_WAIT_RX_DONE) {
        (void) OS_ATOMIC_CMPXCHG(&vap->iv_rx_gate, 1, 0);
    }

    return error;
#undef WAIT_RX_INTERVAL
}

int wlan_mlme_pause_bss(wlan_if_t vaphandle)
{
    struct ieee80211vap     *vap = vaphandle;
    int                     error = 0;
    
    IEEE80211_DPRINTF(vap, IEEE80211_MSG_MLME, "%s\n", __func__);

    switch(vap->iv_opmode) {
#if UMAC_SUPPORT_IBSS
    case IEEE80211_M_IBSS:
        mlme_pause_adhoc_bss(vap);
        break;
#endif

    case IEEE80211_M_STA:
        mlme_sta_swbmiss_timer_stop(vap);
        break;

    default:
        ASSERT(0);
    }

    return error;
}

int wlan_mlme_resume_bss(wlan_if_t vaphandle)
{
    struct ieee80211vap    *vap = vaphandle;
    int                    error = 0;
    
    IEEE80211_DPRINTF(vap, IEEE80211_MSG_MLME, "%s\n", __func__);

    switch(vap->iv_opmode) {
    case IEEE80211_M_IBSS:
        error = mlme_resume_adhoc_bss(vap); 
        break;

    case IEEE80211_M_STA:
        mlme_sta_swbmiss_timer_restart(vap);
        break;

    default:
        ASSERT(0);
    }

    return error;
}

/* return true if an mlme operation is in progress */
bool wlan_mlme_operation_in_progress(wlan_if_t vaphandle)
{
    struct ieee80211vap           *vap = vaphandle;
    struct ieee80211_mlme_priv    *mlme_priv = vap->iv_mlme_priv;

    return (mlme_priv->im_request_type != MLME_REQ_NONE);
}


/* Cancel any pending MLME request */
int wlan_mlme_cancel(wlan_if_t vaphandle)
{
    struct ieee80211vap           *vap = vaphandle;
    struct ieee80211_mlme_priv    *mlme_priv = vap->iv_mlme_priv;

    IEEE80211_DPRINTF(vap, IEEE80211_MSG_MLME, "%s\n", __func__);

    /* Cancel pending timer */
    if (OS_CANCEL_TIMER(&mlme_priv->im_timeout_timer) && 
        (mlme_priv->im_request_type != MLME_REQ_NONE)) 
    {
        /* Invoke the timeout routine */
        IEEE80211_DPRINTF(vap, IEEE80211_MSG_MLME,"%s", "Trigger early timeout\n");
        mlme_timeout_callback(vap, IEEE80211_STATUS_CANCEL);

    }

    return 0;
}

/* Reset Connection */
int wlan_mlme_connection_reset(wlan_if_t vaphandle)
{
    struct ieee80211vap           *vap = vaphandle;
    struct ieee80211_mlme_priv    *mlme_priv = vap->iv_mlme_priv;
#if (UMAC_SUPPORT_TDLS == 1) && (ATH_TDLS_AUTO_CONNECT == 1)
    struct ieee80211com           *ic = vap->iv_ic;
    ic->ic_tdls_clean(vap);
#endif

    IEEE80211_DPRINTF(vap, IEEE80211_MSG_MLME, "%s\n", __func__);

    /* There should be no mlme requests pending */
    ASSERT(vap->iv_mlme_priv->im_request_type == MLME_REQ_NONE);

    /* Reset state variables */
    mlme_priv->im_connection_up = 0;

    /* Association failed, put underlying H/W back to init state. */
    ieee80211_vap_stop(vap, FALSE);

    /* Leave the BSS */
    if (vap->iv_bss)
        ieee80211_sta_leave(vap->iv_bss);

    switch(vap->iv_opmode) {
    case IEEE80211_M_STA:
        mlme_sta_connection_reset(vap);
    default:
        break;
    }
    return 0;
}

/* Start monitor mode */
int wlan_mlme_start_monitor(wlan_if_t vaphandle)
{
    struct ieee80211vap    *vap = vaphandle;
    struct ieee80211com    *ic  = vap->iv_ic;
    ieee80211_reset_request  req;
    int                         error = 0;

    ASSERT(vap->iv_opmode == IEEE80211_M_MONITOR);

    OS_MEMZERO(&req, sizeof(req));
    req.reset_hw = 1;
    req.type = IEEE80211_RESET_TYPE_INTERNAL;
    req.no_flush = 0;
    wlan_reset_start(vap, &req);
    wlan_reset(vap, &req);
    wlan_reset_end(vap, &req);

    if (vap->iv_des_chan[vap->iv_des_mode] != IEEE80211_CHAN_ANYC) {
        ieee80211_set_channel(ic, vap->iv_des_chan[vap->iv_des_mode]);
        vap->iv_bsschan = ic->ic_curchan;
    }

    error = ieee80211_resmgr_vap_start(ic->ic_resmgr,vap,ic->ic_curchan,MLME_REQ_ID,0);
    if (error == EOK) { /* no resource manager in place */
	/* In case of perf_offload, ieee80211_vap_start() is called from
           ieee80211_vap_resmgr_notification_handler()
        */
        ieee80211_vap_start(vap);
    }
    return 0;
}

#if ATH_SUPPORT_HS20
int wlan_mlme_parse_appie(struct ieee80211vap *vap, ieee80211_frame_type ftype, u_int8_t *buf, u_int16_t buflen)
{
    struct ieee80211_ie_header *ie = (struct ieee80211_ie_header *)buf;
    u_int8_t *val;
    int final_buflen = 0;
    if (ftype == IEEE80211_FRAME_TYPE_BEACON) {
        while ((u_int8_t *)ie < buf + buflen) {
            if (ie->element_id == IEEE80211_ELEMID_INTERWORKING) {
                val = (u_int8_t *)(ie + 1);
                vap->iv_access_network_type = val[0] & 0xF;
                if (ie->length == 7)
                    IEEE80211_ADDR_COPY(vap->iv_hessid, val + 1);
                if (ie->length == 9)
                    IEEE80211_ADDR_COPY(vap->iv_hessid, val + 3);
            }
            if (ie->element_id == IEEE80211_ELEMID_XCAPS) {
                /* copy xcaps and delete ie from appie */
                u_int8_t *delbuf = (u_int8_t *)ie;
                val = (u_int8_t *)(ie + 1);
                vap->iv_hotspot_xcaps = le32toh(*(u_int32_t *)val);
                buflen -= ie->length + 2;
                OS_MEMCPY(delbuf, delbuf + ie->length + 2, buflen - final_buflen);
                ie = (struct ieee80211_ie_header *)delbuf;
                continue;
            }
/*
            if (ie->element_id == IEEE80211_ELEMID_TIME_ADVERTISEMENT) {
                struct ieee80211com    *ic = vap->iv_ic;
                val = (u_int8_t *)(ie + 1);
                if (val[0] == 2 && ie->length > 10) {
                    ieee80211_vap_tsf_offset tsf_offset_info;
                    u_int64_t tsf = ic->ic_get_TSF64(ic);
                    u_int32_t ie_msecs, msecs;

                    ieee80211_vap_get_tsf_offset(vap, &tsf_offset_info);

                    if (tsf_offset_info.offset_negative) {
                        tsf -= tsf_offset_info.offset;
                    } else {
                        tsf += tsf_offset_info.offset;
                    }
#define MSECS_IN_HOUR (60 * 60 * 1000)
#define MSECS_IN_MIN  (60 * 1000)
#define MSECS_IN_SEC  (1000)
                    ie_msecs = val[5] * MSECS_IN_HOUR  + val[6] * MSECS_IN_MIN + val[7] * MSECS_IN_SEC + le16toh(*(u_int16_t *)(val + 8));
                    msecs = tsf / 1000;
                    if (ie_msecs > msecs) {
                        ie_msecs -= msecs;
                        val[5] = ie_msecs / MSECS_IN_HOUR;
                        ie_msecs -= val[5] * MSECS_IN_HOUR;
                        val[6] = ie_msecs / MSECS_IN_MIN;
                        ie_msecs -= val[6] * MSECS_IN_MIN;
                        val[7] = ie_msecs / MSECS_IN_SEC;
                        ie_msecs -= val[7] * MSECS_IN_SEC;
                        val[8] = htole16((u_int16_t)ie_msecs) >> 8;
                        val[9] = htole16((u_int16_t)ie_msecs) & 0xFF;
                    }
                    else {
                        printk("FIXME: Time Advt IE crossing day boundary\n");
                    }
#undef MSECS_IN_HOUR
#undef MSECS_IN_MIN
#undef MSECS_IN_SEC
                }
            }
*/
            final_buflen += ie->length + 2;
            ie = (struct ieee80211_ie_header *)((u_int8_t *)ie + ie->length + 2);
        }
    }
    else if (ftype == IEEE80211_FRAME_TYPE_PROBERESP) {
        while ((u_int8_t *)ie < buf + buflen) {
            if (ie->element_id == IEEE80211_ELEMID_XCAPS) {
                /* delete this ie from appie */
                u_int8_t *delbuf = (u_int8_t *)ie;
                buflen -= ie->length + 2;
                OS_MEMCPY(delbuf, delbuf + ie->length + 2, buflen - final_buflen);
                ie = (struct ieee80211_ie_header *)delbuf;
                continue;
            }
            final_buflen += ie->length + 2;
            ie = (struct ieee80211_ie_header *)((u_int8_t *)ie + ie->length + 2);
        }
    }
    else {
        final_buflen = buflen;
    }
    return final_buflen;
}
#endif

/* Set application defined IEs */
int wlan_mlme_set_appie(wlan_if_t vaphandle, ieee80211_frame_type ftype, u_int8_t *buf, u_int16_t buflen)
{
    struct ieee80211vap    *vap = vaphandle;
    struct ieee80211com    *ic = vap->iv_ic;
    int                    error = 0;
    u_int8_t               *iebuf = NULL;
    bool                   alloc_iebuf = FALSE;

    IEEE80211_DPRINTF(vap, IEEE80211_MSG_MLME, "%s, ftype=%x, ie_len=%x\n", __func__,ftype, buflen ) ;

    ASSERT(ftype < IEEE80211_FRAME_TYPE_MAX);

    if (ftype >= IEEE80211_FRAME_TYPE_MAX) {
        error = -EINVAL;
        goto exit;
    }

#if ATH_SUPPORT_HS20
    buflen = wlan_mlme_parse_appie(vap, ftype, buf, buflen);
#endif

    if (buflen > vap->iv_app_ie_maxlen[ftype]) {
        /* Allocate ie buffer */
        iebuf = OS_MALLOC(ic->ic_osdev, buflen, 0);

        if (iebuf == NULL) {
            error = -ENOMEM;
            goto exit;
        }

        alloc_iebuf = TRUE;
        vap->iv_app_ie_maxlen[ftype] = buflen;
    } else {
        iebuf = vap->iv_app_ie[ftype].ie;
    }

    IEEE80211_VAP_LOCK(vap);
    /* 
     * Temp: reduce window of race with beacon update in Linux AP.
     * In Linux AP, ieee80211_beacon_update is called in ISR, so
     * iv_lock is not acquired.
     */
    IEEE80211_VAP_APPIE_UPDATE_DISABLE(vap);

    /* Free existing buffer */
    if (alloc_iebuf == TRUE && vap->iv_app_ie[ftype].ie) {
        OS_FREE(vap->iv_app_ie[ftype].ie);
    }

    vap->iv_app_ie[ftype].ie = iebuf;
    vap->iv_app_ie[ftype].length = buflen;

    if (buflen) {
        ASSERT(buf);
        if (buf == NULL) {
            IEEE80211_VAP_UNLOCK(vap);
            error = -EINVAL;
            goto exit;
        }

        /* Copy app ie contents and save pointer/length */
        OS_MEMCPY(iebuf, buf, buflen);
    }

    /* Set appropriate flag so that the IE gets updated in the next beacon */
    IEEE80211_VAP_APPIE_UPDATE_ENABLE(vap);
    IEEE80211_VAP_UNLOCK(vap);
    
exit:
    return error;
}

/* Get application defined IEs */
int wlan_mlme_get_appie(wlan_if_t vaphandle, ieee80211_frame_type ftype, u_int8_t *buf, u_int32_t *ielen, u_int32_t buflen)
{
    struct ieee80211vap    *vap = vaphandle;
    int                    error = 0;

    IEEE80211_DPRINTF(vap, IEEE80211_MSG_MLME, "%s\n", __func__);

    ASSERT(ftype < IEEE80211_FRAME_TYPE_MAX);

    if (ftype >= IEEE80211_FRAME_TYPE_MAX) {
        error = -EINVAL;
        goto exit;
    }

    *ielen = vap->iv_app_ie[ftype].length;

    /* verify output buffer is large enough */
    if (buflen < vap->iv_app_ie[ftype].length) {
        error = -EOVERFLOW;
        goto exit;
    }

    IEEE80211_VAP_LOCK(vap);
    /* copy app ie contents to output buffer */
    if (*ielen) {
        OS_MEMCPY(buf, vap->iv_app_ie[ftype].ie, vap->iv_app_ie[ftype].length);
    }
    IEEE80211_VAP_UNLOCK(vap);
    
exit:
    return error;
}

/* Set optional application defined IEs */
int wlan_mlme_set_optie(wlan_if_t vaphandle, u_int8_t *buf, u_int16_t buflen)
{
    struct ieee80211vap    *vap = vaphandle;
    struct ieee80211com    *ic = vap->iv_ic;
    int                    error = 0;
    u_int8_t               *iebuf = NULL;
    bool                   alloc_iebuf = FALSE;

    IEEE80211_DPRINTF(vap, IEEE80211_MSG_MLME, "%s\n", __func__);

    if (buflen > vap->iv_opt_ie_maxlen) {
        /* Allocate ie buffer */
        iebuf = OS_MALLOC(ic->ic_osdev, buflen, 0);

        if (iebuf == NULL) {
            error = -ENOMEM;
            goto exit;
        }

        alloc_iebuf = TRUE;
        vap->iv_opt_ie_maxlen = buflen;
    } else {
        iebuf = vap->iv_opt_ie.ie;
    }

    IEEE80211_VAP_LOCK(vap);

    /* Free existing buffer */
    if (alloc_iebuf == TRUE && vap->iv_opt_ie.ie) {
        OS_FREE(vap->iv_opt_ie.ie);
    }

    vap->iv_opt_ie.ie = iebuf;
    vap->iv_opt_ie.length = buflen;

    if (buflen) {
        ASSERT(buf);
        if (buf == NULL) {
            IEEE80211_VAP_UNLOCK(vap);
            error = -EINVAL;
            goto exit;
        }

        /* Copy app ie contents and save pointer/length */
        OS_MEMCPY(iebuf, buf, buflen);
    }
    IEEE80211_VAP_UNLOCK(vap);

exit:
    return error;
}


/* Get optional application defined IEs */
int wlan_mlme_get_optie(wlan_if_t vaphandle, u_int8_t *buf, u_int32_t *ielen, u_int32_t buflen)
{
    struct ieee80211vap    *vap = vaphandle;
    int                    error = 0;

    IEEE80211_DPRINTF(vap, IEEE80211_MSG_MLME, "%s\n", __func__);

    *ielen = vap->iv_opt_ie.length;

    /* verify output buffer is large enough */
    if (buflen < vap->iv_opt_ie.length) {
        error = -EOVERFLOW;
        goto exit;
    }

    IEEE80211_VAP_LOCK(vap);
    /* copy opt ie contents to output buffer */
    if (*ielen) {
        OS_MEMCPY(buf, vap->iv_opt_ie.ie, vap->iv_opt_ie.length);
    }
    IEEE80211_VAP_UNLOCK(vap);

exit:
    return error;
}


/* Get linkrate (bps) */
void wlan_get_linkrate(wlan_if_t vaphandle, u_int32_t* rxlinkspeed, u_int32_t* txlinkspeed)
{
    mlme_get_linkrate(vaphandle->iv_bss, rxlinkspeed, txlinkspeed);
}


/* Notify connection state (up/down)
 *
 * Mlme will not indicate node assoc/disassoc until the connection state
 * is set to "up".
 *
 * For example, on Vista, the driver would indicate to the OS that the 
 * connection is "up" and then notify mlme that the connection is "up".
 * This prevents mlme from indicating node assoc, before the OS connection
 * is established.
 *
 */
void wlan_mlme_connection_up(wlan_if_t vaphandle)
{
    struct ieee80211vap           *vap = vaphandle;
    struct ieee80211_mlme_priv    *mlme_priv = vap->iv_mlme_priv;
    ieee80211_vap_event           evt;

    IEEE80211_DPRINTF(vap, IEEE80211_MSG_MLME, "%s\n", __func__);

    mlme_priv->im_connection_up = 1;
    
    if( vap->iv_opmode != IEEE80211_M_STA || !ieee80211_auth_mode_needs_upper_auth(vap) ){
        evt.type = IEEE80211_VAP_AUTH_COMPLETE;
        ieee80211_vap_deliver_event(vap, &evt);
    }
}

void wlan_mlme_connection_down(wlan_if_t vaphandle)
{
    struct ieee80211vap           *vap = vaphandle;
    struct ieee80211_mlme_priv    *mlme_priv = vap->iv_mlme_priv;

    IEEE80211_DPRINTF(vap, IEEE80211_MSG_MLME, "%s\n", __func__);

    mlme_priv->im_connection_up = 0;
}

u_int32_t wlan_get_disassoc_timeout(wlan_if_t vaphandle)
{
    struct ieee80211vap           *vap = vaphandle;
    struct ieee80211_mlme_priv    *mlme_priv = vap->iv_mlme_priv;

    return mlme_priv->im_disassoc_timeout;
}

void wlan_set_disassoc_timeout(wlan_if_t vaphandle, u_int32_t disassoc_timeout)
{
    struct ieee80211vap           *vap = vaphandle;
    struct ieee80211_mlme_priv    *mlme_priv = vap->iv_mlme_priv;

    mlme_priv->im_disassoc_timeout = disassoc_timeout;
}



void ieee80211_mlme_recv_auth(struct ieee80211_node *ni,
    u_int16_t algo, u_int16_t seq, u_int16_t status_code,
                              u_int8_t *challenge, u_int8_t challenge_length, wbuf_t wbuf)
{
    struct ieee80211vap           *vap = ni->ni_vap;

    switch (vap->iv_opmode) {
    case IEEE80211_M_STA:
        mlme_recv_auth_sta(ni,algo,seq,status_code,challenge,challenge_length,wbuf);
        break;
        
    case IEEE80211_M_IBSS:
        if(vap->iv_ic->ic_softap_enable)
            mlme_recv_auth_ap(ni,algo,seq,status_code,challenge,challenge_length,wbuf);
        else
            mlme_recv_auth_ibss(ni,algo,seq,status_code,challenge,challenge_length,wbuf);
        break;
        
    case IEEE80211_M_HOSTAP:
        mlme_recv_auth_ap(ni,algo,seq,status_code,challenge,challenge_length,wbuf);
        break;

    case IEEE80211_M_BTAMP:
        mlme_recv_auth_btamp(ni,algo,seq,status_code,challenge,challenge_length,wbuf);
        break;

    default:
        break;
    }

}




void ieee80211_mlme_recv_deauth(struct ieee80211_node *ni, u_int16_t reason_code)
{
    struct ieee80211vap           *vap = ni->ni_vap;
    struct ieee80211_mlme_priv    *mlme_priv = vap->iv_mlme_priv;
#if (UMAC_SUPPORT_TDLS == 1) && (ATH_TDLS_AUTO_CONNECT == 1)
    struct ieee80211com           *ic = vap->iv_ic;
    ic->ic_tdls_clean(vap);
#endif

    IEEE80211_DPRINTF(vap, IEEE80211_MSG_MLME, "%s\n", __func__);
#ifdef CONFIG_CS75XX_WFO_AR9580
	CS_AR9580_WFO_TX_mac_entry_delete(vap->iv_ic, ni);
	if (cs_wfo_rate_adjust)
		CS_AR9580_WFO_mac_entry_timer_delete(vap->iv_ic, ni);
#endif

    switch(vap->iv_opmode) {
    case IEEE80211_M_IBSS:

        /* IBSS must be up and running */
        if (!mlme_priv->im_connection_up) {
            break;
        }

        /* If the sender is not in our node table, drop deauth frame. */
        if (ni == vap->iv_bss) {
            break;
        }

        /* If node is not associated, drop deauth frame */
        if (ni->ni_assoc_state != IEEE80211_NODE_ADHOC_STATE_AUTH_ASSOC && !vap->iv_ic->ic_softap_enable) {
            break;
        }

        /*
         * This station is no longer associated. We assign IEEE80211_NODE_ADHOC_STATE_AUTH_ZERO
         * as its association state so that if we receive a beacon from it right away,
         * we would not re-associate it.
         */
        ni->ni_assoc_state = IEEE80211_NODE_ADHOC_STATE_ZERO;
        ni->ni_wait0_ticks = 0;
    
        /* Call MLME indication handler */
        if(!vap->iv_ic->ic_softap_enable){
	        IEEE80211_DELIVER_EVENT_MLME_DEAUTH_INDICATION(vap, ni->ni_macaddr, reason_code);
            break;
        }

    case IEEE80211_M_HOSTAP:
    case IEEE80211_M_BTAMP:
        if (ni != vap->iv_bss) {
#if ATH_SUPPORT_AOW
            ieee80211_aow_join_indicate(ni->ni_ic, AOW_STA_DISCONNECTED, ni);
#endif  /* ATH_SUPPORT_AOW */
            ieee80211_ref_node(ni);
            if(IEEE80211_NODE_LEAVE(ni)) {
                /* Call MLME indication handler if node is in associated state */
                IEEE80211_DELIVER_EVENT_MLME_DEAUTH_INDICATION(vap, ni->ni_macaddr, reason_code);
            }
            ieee80211_free_node(ni);
        }
        break;

    default:
        /* Call MLME indication handler */
        IEEE80211_DELIVER_EVENT_MLME_DEAUTH_INDICATION(vap, ni->ni_macaddr, reason_code);
    }
}

void ieee80211_mlme_recv_disassoc(struct ieee80211_node *ni, u_int32_t reason_code)
{
    struct ieee80211vap           *vap = ni->ni_vap;
    struct ieee80211_mlme_priv	  *mlme_priv = vap->iv_mlme_priv;

#if (UMAC_SUPPORT_TDLS == 1) && (ATH_TDLS_AUTO_CONNECT == 1)
    struct ieee80211com           *ic = vap->iv_ic;
    ic->ic_tdls_clean(vap);
#endif
#ifdef CONFIG_CS75XX_WFO_AR9580
    CS_AR9580_WFO_TX_mac_entry_delete(vap->iv_ic, ni);
	if (cs_wfo_rate_adjust)
		CS_AR9580_WFO_mac_entry_timer_delete(vap->iv_ic, ni);
#endif

    IEEE80211_DPRINTF(vap, IEEE80211_MSG_MLME, "%s\n", __func__);

    switch(vap->iv_opmode) {
    case IEEE80211_M_HOSTAP:
    case IEEE80211_M_BTAMP:
        if (ni != vap->iv_bss) {
#if ATH_SUPPORT_AOW
        ieee80211_aow_join_indicate(ni->ni_ic, AOW_STA_DISCONNECTED, ni);
#endif  /* ATH_SUPPORT_AOW */
            ieee80211_ref_node(ni);
            if(IEEE80211_NODE_LEAVE(ni)) {
                /* Call MLME indication handler if node is in associated state */
                IEEE80211_DELIVER_EVENT_MLME_DISASSOC_INDICATION(vap, ni->ni_macaddr, reason_code);
            }
            ieee80211_free_node(ni);
        }
        break;
	case IEEE80211_M_IBSS:
		if(vap->iv_ic->ic_softap_enable){
			/* IBSS must be up and running */
			if (!mlme_priv->im_connection_up) {
				break;
			}
			/* If the sender is not in our node table, drop deauth frame. */
			if (ni == vap->iv_bss) {
				break;
			}
			/*
			 * This station is no longer associated. We assign IEEE80211_NODE_ADHOC_STATE_AUTH_ZERO
			 * as its association state so that if we receive a beacon from it right away,
			 * we would not re-associate it.
			 */
			ni->ni_assoc_state = IEEE80211_NODE_ADHOC_STATE_ZERO;
			ni->ni_wait0_ticks = 0;
		}
    default:
        /* Call MLME indication handler */
        IEEE80211_DELIVER_EVENT_MLME_DISASSOC_INDICATION(vap, ni->ni_macaddr, reason_code);
    }
}

void ieee80211_mlme_recv_csa(struct ieee80211_node *ni, u_int32_t csa_delay, bool disconnect)
{
    struct ieee80211vap    *vap = ni->ni_vap;

    IEEE80211_DPRINTF(vap, IEEE80211_MSG_MLME, "%s\n", __func__);

    switch(vap->iv_opmode) {
    case IEEE80211_M_STA:
         IEEE80211_NODE_STATE_LOCK(ni);
        if (ni->ni_table) {
            IEEE80211_DELIVER_EVENT_MLME_RADAR_DETECTED(vap, csa_delay);

            /* Call MLME indication handler */
            IEEE80211_DELIVER_EVENT_MLME_DISASSOC_INDICATION(vap, ni->ni_macaddr, IEEE80211_STATUS_UNSPECIFIED);
        }
         IEEE80211_NODE_STATE_UNLOCK(ni);
        break;
    default:
        break;
    }
}

/*
 * heart beat timer to handle any timeouts.
 * called every IEEE80211_INACT_WAIT seconds. 
 */
void mlme_inact_timeout(struct ieee80211vap *vap) 
{
    /*
     * send keep alive packets (null frames) for station vap so that
     * the AP does not kick us out because of inactivity.
     */
    switch(vap->iv_opmode) {
    case IEEE80211_M_STA:
        ieee80211_inact_timeout_sta(vap);
        break;
    case IEEE80211_M_HOSTAP:
        ieee80211_inact_timeout_ap(vap);
        break;
    default:
        break;

    }
}

/*
 * Data structure and routine used for verifying whether any port has an
 * active connection involving the specified BSS entry.
 */
struct ieee80211_mlme_find_connection {
    struct ieee80211_scan_entry    *scan_entry;
    bool                           connection_found;
};

static void
ieee80211_vap_iter_find_connection(void *arg, struct ieee80211vap *vap, bool is_last_vap)
{
    struct ieee80211_mlme_find_connection    *pmlme_find_connection_data = arg;

    UNREFERENCED_PARAMETER(is_last_vap);

    /*
     * If we haven't found a connection yet, check to see if current VAP is 
     * connected to the specified AP.
     */
    if (! pmlme_find_connection_data->connection_found) {
        /*
         * Since ieee80211_mlme_get_bss_entry is not implemented, compare
         * iv_bss's and scan_entry's SSID and BSSID.
         */
        struct ieee80211_node    *bss_node = ieee80211vap_get_bssnode(vap);

        if (bss_node != NULL) {
            /* 
             * Check for BSSID match first; SSID matching is a more expensive
             * operation and should be checked last.
             */
            if (IEEE80211_ADDR_EQ(wlan_node_getbssid(bss_node), 
                                  wlan_scan_entry_bssid(pmlme_find_connection_data->scan_entry))) {
                ieee80211_ssid    bss_ssid;
                u_int8_t          scan_entry_ssid_len;
                u_int8_t          *scan_entry_ssid;

                /*
                 * BSSID matched, let's check the SSID
                 */
                wlan_get_bss_essid(vap, &bss_ssid);
                scan_entry_ssid  = 
                    wlan_scan_entry_ssid(pmlme_find_connection_data->scan_entry,
                                         &scan_entry_ssid_len);

                if (scan_entry_ssid != NULL) {
                    pmlme_find_connection_data->connection_found =                    
                        (scan_entry_ssid_len == bss_ssid.len)          &&
                        (OS_MEMCMP(scan_entry_ssid, bss_ssid.ssid, bss_ssid.len) == 0);
                }
            }
        }
    }
}

bool ieee80211_mlme_is_connected(struct ieee80211com *ic, struct ieee80211_scan_entry *bss_entry)
{
    struct ieee80211_mlme_find_connection    mlme_find_connection_data;
    int                                      vap_count;

    /*
     * Populate data structure used to query all VAPs for a connection 
     * involving the specified BSS entry
     */
    OS_MEMZERO(&mlme_find_connection_data, sizeof(mlme_find_connection_data));
    mlme_find_connection_data.scan_entry       = bss_entry;
    mlme_find_connection_data.connection_found = false;

    ieee80211_iterate_vap_list_internal(ic, ieee80211_vap_iter_find_connection, &mlme_find_connection_data, vap_count);

    return mlme_find_connection_data.connection_found;
}


/*
 * Local functions
 */

static OS_TIMER_FUNC(timeout_callback)
{
    struct ieee80211vap    *vap;
    OS_GET_TIMER_ARG(vap, struct ieee80211vap *);

    mlme_timeout_callback(vap, IEEE80211_STATUS_TIMEOUT);
}

static void mlme_timeout_callback(struct ieee80211vap *vap, IEEE80211_STATUS  ieeeStatus)
{
    struct ieee80211_mlme_priv    *mlme_priv = vap->iv_mlme_priv;
    int                           mlme_request_type = mlme_priv->im_request_type;

    IEEE80211_DPRINTF(vap, IEEE80211_MSG_MLME, "%s. Request type = %d\n",
                       __func__, mlme_request_type);

    /* Request complete */
    mlme_priv->im_request_type = MLME_REQ_NONE;

    switch(mlme_request_type) {
    case MLME_REQ_JOIN_INFRA:
        ASSERT(vap->iv_opmode != IEEE80211_M_IBSS);
        /*
         * Cancel the Join operation if it has not already completed
         */
        if (MLME_STOP_WAITING_FOR_JOIN(mlme_priv) == TRUE) {
            IEEE80211_DPRINTF(vap, IEEE80211_MSG_MLME,"%s", "Cancelled the Join Operation as it took too long\n");

            IEEE80211_DELIVER_EVENT_MLME_JOIN_COMPLETE_INFRA(vap, ieeeStatus); 
        }
        break;
   case MLME_REQ_JOIN_ADHOC:
        ASSERT(vap->iv_opmode == IEEE80211_M_IBSS);
        /*
         * Cancel the Join operation if it has not already completed
         */
        if (MLME_STOP_WAITING_FOR_JOIN(mlme_priv) == TRUE) {
            IEEE80211_DPRINTF(vap, IEEE80211_MSG_MLME,"%s", "Cancelled the Join Operation as it took too long\n");

            IEEE80211_DELIVER_EVENT_MLME_JOIN_COMPLETE_ADHOC(vap, ieeeStatus); 
        }
        break;
    case MLME_REQ_AUTH:
        /*
         * Cancel the auth operation if it has not already completed
         */
        IEEE80211_DPRINTF(vap, IEEE80211_MSG_MLME,"%s", "Cancelled the Auth Operation as it took too long\n");

        mlme_priv->im_expected_auth_seq_number = 0;
        IEEE80211_DELIVER_EVENT_MLME_AUTH_COMPLETE(vap, ieeeStatus); 
        break;
    case MLME_REQ_ASSOC:
        /*
         * Cancel the assoc operation if it has not already completed
         */
        IEEE80211_DPRINTF(vap, IEEE80211_MSG_MLME,"%s", "Cancelled the Assoc Operation as it took too long\n");

        IEEE80211_DELIVER_EVENT_MLME_ASSOC_COMPLETE(vap, ieeeStatus, 0, NULL); 
        break;
    case MLME_REQ_REASSOC:
        /*
         * Cancel the reassoc operation if it has not already completed
         */
        IEEE80211_DPRINTF(vap, IEEE80211_MSG_MLME,"%s", "Cancelled the Reassoc Operation as it took too long\n");

        IEEE80211_DELIVER_EVENT_MLME_REASSOC_COMPLETE(vap, ieeeStatus, 0, NULL); 
        break;
    case MLME_REQ_NONE:
        IEEE80211_DPRINTF(vap, IEEE80211_MSG_MLME,"%s", "mlme_request_type is MLME_REQ_NONE, do nothing.\n");
        break;
    default:
        ASSERT(0);
        break;
    }
}



u_int32_t mlme_dot11rate_to_bps(u_int8_t  rate)
{
    return 500000 * rate;
}

void
ieee80211_mlme_node_pwrsave(struct ieee80211_node *ni, int enable)
{
    if(ni->ni_vap->iv_opmode != IEEE80211_M_HOSTAP) return;
    ieee80211_mlme_node_pwrsave_ap(ni,enable);
}

void
ieee80211_mlme_node_leave(struct ieee80211_node *ni)
{
    if(ni->ni_vap->iv_opmode != IEEE80211_M_HOSTAP) return;
    ieee80211_mlme_node_leave_ap(ni);
}

/*
 * This routine will check if all nodes for this AP are asleep.
 */
bool
ieee80211_mlme_check_all_nodes_asleep(ieee80211_vap_t vap)
{
    if (vap->iv_ps_sta == vap->iv_sta_assoc) {
        return true;
    }
    else {
        ASSERT(vap->iv_sta_assoc > 0);
        return false;
    }
}

/* Return the number of associated stations */
int ieee80211_mlme_get_num_assoc_sta(ieee80211_vap_t vap)
{
    return(vap->iv_sta_assoc);
}

u_int32_t ieee80211_mlme_sta_swbmiss_timer_alloc_id(struct ieee80211vap *vap, int8_t *requestor_name)
{
    return mlme_sta_swbmiss_timer_alloc_id(vap,requestor_name);
}

int ieee80211_mlme_sta_swbmiss_timer_free_id(struct ieee80211vap *vap, u_int32_t id)
{
    return mlme_sta_swbmiss_timer_free_id(vap,id);
}

int ieee80211_mlme_sta_swbmiss_timer_enable(struct ieee80211vap *vap, u_int32_t id)
{
    return mlme_sta_swbmiss_timer_enable(vap,id);
}

int ieee80211_mlme_sta_swbmiss_timer_disable(struct ieee80211vap *vap, u_int32_t id)
{
    return mlme_sta_swbmiss_timer_disable(vap,id);
}

void ieee80211_mlme_sta_bmiss_ind(struct ieee80211vap *vap)
{
    mlme_sta_bmiss_ind(vap);
}

void ieee80211_mlme_reset_bmiss(struct ieee80211vap *vap)
{
    mlme_sta_reset_bmiss(vap);
}

/**
 * register a mlme  event handler.
 * @param vap        : handle to vap object
 * @param evhandler  : event handler function.
 * @param arg        : argument passed back via the event handler
 * @return EOK if success, EINVAL if failed, ENOMEM if runs out of memory.
 * allows more than one event handler to be registered.
 */
int ieee80211_mlme_register_event_handler(ieee80211_vap_t vap,ieee80211_mlme_event_handler evhandler, void *arg)
{
    int i;
    struct ieee80211_mlme_priv    *mlme_priv = vap->iv_mlme_priv;

    /* unregister if there exists one already */
    ieee80211_mlme_unregister_event_handler(vap,evhandler,arg);

    IEEE80211_VAP_LOCK(vap);
    for (i=0;i<IEEE80211_MAX_MLME_EVENT_HANDLERS; ++i) {
        if ( mlme_priv->im_event_handler[i] == NULL ) {
             mlme_priv->im_event_handler[i] = evhandler;
             mlme_priv->im_event_handler_arg[i] = arg;
             IEEE80211_VAP_UNLOCK(vap);
             return EOK;
        }
    }
    IEEE80211_VAP_UNLOCK(vap);
    return ENOMEM;
}

/**
 * unregister a mlme  event handler.
 * @param vap        : handle to vap object
 * @param evhandler  : event handler function.
 * @param arg        : argument passed back via the evnt handler
 * @return EOK if success, EINVAL if failed.
 */
int ieee80211_mlme_unregister_event_handler(ieee80211_vap_t vap,ieee80211_mlme_event_handler evhandler, void *arg)
{
    int i;
    struct ieee80211_mlme_priv    *mlme_priv = vap->iv_mlme_priv;

    IEEE80211_VAP_LOCK(vap);
    for (i=0;i<IEEE80211_MAX_MLME_EVENT_HANDLERS; ++i) {
        if ( mlme_priv->im_event_handler[i] == evhandler &&  mlme_priv->im_event_handler_arg[i] == arg ) {
             mlme_priv->im_event_handler[i] = NULL;
             mlme_priv->im_event_handler_arg[i] = NULL;
             IEEE80211_VAP_UNLOCK(vap);
             return EOK;
        }
    }
    IEEE80211_VAP_UNLOCK(vap);
    return EINVAL;
}

void ieee80211_mlme_deliver_event(struct ieee80211_mlme_priv *mlme_priv, ieee80211_mlme_event *event)
{
    int i;                                                                 
    void *arg;                                                                       
    ieee80211_mlme_event_handler evhandler;
    struct ieee80211vap    *vap = mlme_priv->im_vap;

    IEEE80211_VAP_LOCK(vap);
    for(i=0;i<IEEE80211_MAX_MLME_EVENT_HANDLERS; ++i) {                         
        if (mlme_priv->im_event_handler[i]) {                                   
            evhandler =  mlme_priv->im_event_handler[i];                                
            arg = mlme_priv->im_event_handler_arg[i];               
            IEEE80211_VAP_UNLOCK(vap);
            (* evhandler) (vap, event,arg);               
            IEEE80211_VAP_LOCK(vap);
        }                                                                 
    }                                                                     
    IEEE80211_VAP_UNLOCK(vap);
}

/*
 * Calculate maximum allowed scan_entry age, in ms.
 * Reference_time specifies the timestamp of the oldest accepted entry.
 */
u_int32_t ieee80211_mlme_maximum_scan_entry_age(wlan_if_t vaphandle, 
                                                systime_t reference_time)
{
#define IEEE80211_SCAN_LATENCY_TIME                 1000
    u_int32_t    maximum_age  = 0;
    systime_t    current_time = OS_GET_TIMESTAMP();

    if (reference_time == 0) {
        /* Make all entries old if there's no record of the last scan */
        maximum_age = 0;
    }
    else {
        maximum_age = CONVERT_SYSTEM_TIME_TO_MS(current_time - reference_time);

        /* 
         * Make all entries in the table "old" by setting the maximum age
         * to 0 if last scan occurred too long ago. This can happen when 
         * system is resuming from S3/S4.
         */
        if (maximum_age > IEEE80211_SCAN_ENTRY_EXPIRE_TIME) {
            maximum_age = IEEE80211_SCAN_ENTRY_EXPIRE_TIME;
        }
    }
    
    /* 
     * Add a latency time to account for the delay from the time the
     * maximum age is calculated to the time it's actually used.
     * Failing to account for this latency time can cause the oldest
     * entries in the scan list to be skipped.
     */
    if (maximum_age > 0) {
        maximum_age += IEEE80211_SCAN_LATENCY_TIME;
    }

    return maximum_age;
#undef IEEE80211_SCAN_LATENCY_TIME
}

