/*
 * Copyright (c) 2011 Qualcomm Atheros, Inc.
 * All Rights Reserved.
 * Qualcomm Atheros Confidential and Proprietary.
 */

#include <ol_htt_api.h>       
#include <ol_txrx_api.h>       
#include <ol_txrx_htt_api.h>   
#include <ol_htt_rx_api.h>     
#include <ol_txrx_types.h>     
#include <ol_rx_reorder.h>      
#include <ol_rx_pn.h>  
#include <ol_rx_fwd.h> 
#include <ol_rx.h>
#include <ol_txrx_internal.h>               
#include <ol_ctrl_txrx_api.h>
#include <ol_txrx_peer_find.h>
#include <adf_nbuf.h>  
#include <ieee80211.h>
#include <adf_os_util.h>
#include <athdefs.h>
#include <adf_os_mem.h> 
#include <ol_rx_defrag.h>
#include <adf_os_io.h>
#include <enet.h>
#include <adf_os_time.h>      /* adf_os_time */


#define	DEFRAG_IEEE80211_ADDR_EQ(a1, a2) \
    (adf_os_mem_cmp(a1, a2, IEEE80211_ADDR_LEN) == 0)

#define	DEFRAG_IEEE80211_ADDR_COPY(dst, src) \
    adf_os_mem_copy(dst, src, IEEE80211_ADDR_LEN)

#define DEFRAG_IEEE80211_QOS_HAS_SEQ(wh) \
    (((wh)->i_fc[0] & \
      (IEEE80211_FC0_TYPE_MASK | IEEE80211_FC0_SUBTYPE_QOS)) == \
      (IEEE80211_FC0_TYPE_DATA | IEEE80211_FC0_SUBTYPE_QOS))

#define DEFRAG_IEEE80211_QOS_GET_TID(_x) \
    ((_x)->i_qos[0] & IEEE80211_QOS_TID)
      
const struct ol_rx_defrag_cipher f_ccmp = {
    "AES-CCM",
    IEEE80211_WEP_IVLEN + IEEE80211_WEP_KIDLEN + IEEE80211_WEP_EXTIVLEN,
    IEEE80211_WEP_MICLEN,
    0,
};

const struct ol_rx_defrag_cipher f_tkip  = {
    "TKIP",
    IEEE80211_WEP_IVLEN + IEEE80211_WEP_KIDLEN + IEEE80211_WEP_EXTIVLEN,
    IEEE80211_WEP_CRCLEN,
    IEEE80211_WEP_MICLEN,
};

/*
 * Process incoming fragments
 */
void
ol_rx_frag_indication_handler(
    ol_txrx_pdev_handle pdev,
    adf_nbuf_t rx_frag_ind_msg,
    u_int16_t peer_id,
    u_int8_t tid)
{
    int seq_num, seq_num_start, seq_num_end;
    struct ol_txrx_vdev_t *vdev = NULL;
    struct ol_txrx_peer_t *peer;
    htt_pdev_handle htt_pdev;
    adf_nbuf_t head_msdu, tail_msdu;
    void *rx_mpdu_desc;

    htt_pdev = pdev->htt_pdev;
    peer = ol_txrx_peer_find_by_id(pdev, peer_id);
    if (peer) {
        vdev = peer->vdev;
    }

    if (htt_rx_ind_flush(rx_frag_ind_msg) && peer) {
        htt_rx_frag_ind_flush_seq_num_range(
            rx_frag_ind_msg, &seq_num_start, &seq_num_end);  
        /* 
         * Assuming flush indication for frags sent from target is seperate 
         * from normal frames 
         */
         ol_rx_reorder_flush_frag(htt_pdev, peer, tid, seq_num_start);
    }
    if (peer) { 
        htt_rx_amsdu_pop(htt_pdev, rx_frag_ind_msg, &head_msdu, &tail_msdu);
        adf_os_assert(head_msdu == tail_msdu);
        rx_mpdu_desc = htt_rx_mpdu_desc_list_next(htt_pdev, rx_frag_ind_msg);
        seq_num = htt_rx_mpdu_desc_seq_num(htt_pdev, rx_mpdu_desc);
        ol_rx_reorder_store_frag(pdev, peer, tid, seq_num, head_msdu);                                  
    } else {
        /* invalid frame - discard it */
        htt_rx_amsdu_pop(htt_pdev, rx_frag_ind_msg, &head_msdu, &tail_msdu);
        htt_rx_mpdu_desc_list_next(htt_pdev, rx_frag_ind_msg);
        htt_rx_desc_frame_free(htt_pdev, head_msdu);
    }
    /* request HTT to provide new rx MSDU buffers for the target to fill. */
    htt_rx_msdu_buff_replenish(htt_pdev);
}

/*
 * Flushing fragments
 */
void
ol_rx_reorder_flush_frag(
    htt_pdev_handle htt_pdev,
    struct ol_txrx_peer_t *peer,
    unsigned tid,
    int seq_num)
{
    struct ol_rx_reorder_array_elem_t *rx_reorder_array_elem;
    int seq;

    seq = seq_num & peer->tids_rx_reorder[tid].win_sz_mask;
    rx_reorder_array_elem = &peer->tids_rx_reorder[tid].array[seq];
    if (rx_reorder_array_elem->head) {
        ol_rx_frames_free(htt_pdev, rx_reorder_array_elem->head);
        rx_reorder_array_elem->head = NULL;
        rx_reorder_array_elem->tail = NULL;
    }
}

/*
 * Reorder and store fragments
 */
void
ol_rx_reorder_store_frag(
    ol_txrx_pdev_handle pdev,
    struct ol_txrx_peer_t *peer,
    unsigned tid,
    unsigned seq_num,
    adf_nbuf_t frag)
{
    struct ieee80211_frame *fmac_hdr, *mac_hdr;
    u_int8_t fragno, more_frag, all_frag_present = 0;
    struct ol_rx_reorder_array_elem_t *rx_reorder_array_elem;
    u_int16_t frxseq, rxseq, seq;
    htt_pdev_handle htt_pdev = pdev->htt_pdev;

    seq = seq_num & peer->tids_rx_reorder[tid].win_sz_mask;
    adf_os_assert(seq == 0); 
    rx_reorder_array_elem = &peer->tids_rx_reorder[tid].array[seq];

    mac_hdr = (struct ieee80211_frame *) adf_nbuf_data(frag);
    rxseq = adf_os_le16_to_cpu(*(u_int16_t *) mac_hdr->i_seq) >>
        IEEE80211_SEQ_SEQ_SHIFT; 
    fragno = adf_os_le16_to_cpu(*(u_int16_t *) mac_hdr->i_seq) &
        IEEE80211_SEQ_FRAG_MASK;
    more_frag = mac_hdr->i_fc[1] & IEEE80211_FC1_MORE_FRAG;

    if ((!more_frag) && (!fragno) && (!rx_reorder_array_elem->head)) {
        rx_reorder_array_elem->head = frag;
        rx_reorder_array_elem->tail = frag;
        adf_nbuf_set_next(frag, NULL);
        ol_rx_defrag(pdev, peer, tid, rx_reorder_array_elem->head);
        rx_reorder_array_elem->head = NULL;
        rx_reorder_array_elem->tail = NULL;
        return;
    }
    if (rx_reorder_array_elem->head) {
        fmac_hdr = (struct ieee80211_frame *)
            adf_nbuf_data(rx_reorder_array_elem->head);
        frxseq = adf_os_le16_to_cpu(*(u_int16_t *) fmac_hdr->i_seq) >>
            IEEE80211_SEQ_SEQ_SHIFT;
        if (rxseq != frxseq ||
            !DEFRAG_IEEE80211_ADDR_EQ(mac_hdr->i_addr1, fmac_hdr->i_addr1) || 
            !DEFRAG_IEEE80211_ADDR_EQ(mac_hdr->i_addr2, fmac_hdr->i_addr2)) 
        {                      
            ol_rx_frames_free(htt_pdev, rx_reorder_array_elem->head);
            rx_reorder_array_elem->head = NULL;
            rx_reorder_array_elem->tail = NULL;
            TXRX_PRINT(TXRX_PRINT_LEVEL_ERR,
                "\n ol_rx_reorder_store:  %s mismatch \n",
                (rxseq == frxseq) ? "address" : "seq number");
        }
    }    
    ol_rx_fraglist_insert(htt_pdev, &rx_reorder_array_elem->head, 
        &rx_reorder_array_elem->tail, frag, &all_frag_present);

    if (pdev->rx.flags.defrag_timeout_check) {
        ol_rx_defrag_waitlist_remove(peer, tid);
    }

    if (all_frag_present) {
        ol_rx_defrag(pdev, peer, tid, rx_reorder_array_elem->head);
        rx_reorder_array_elem->head = NULL;
        rx_reorder_array_elem->tail = NULL;
        peer->tids_rx_reorder[tid].defrag_timeout_ms = 0;
        peer->tids_last_seq[tid] = seq_num;
    } else if (pdev->rx.flags.defrag_timeout_check) {
        u_int32_t now_ms = adf_os_ticks_to_msecs(adf_os_ticks());

        peer->tids_rx_reorder[tid].defrag_timeout_ms = now_ms + pdev->rx.defrag.timeout_ms;
        ol_rx_defrag_waitlist_add(peer, tid);
    }
}

/*
 * Insert and store fragments
 */
void 
ol_rx_fraglist_insert(
    htt_pdev_handle htt_pdev,
    adf_nbuf_t *head_addr, 
    adf_nbuf_t *tail_addr, 
    adf_nbuf_t frag, 
    u_int8_t *all_frag_present)
{
    adf_nbuf_t next, prev = NULL, cur = *head_addr;
    struct ieee80211_frame *mac_hdr, *cmac_hdr, *next_hdr, *lmac_hdr;
    u_int8_t fragno, cur_fragno, lfragno, next_fragno;
    u_int8_t last_morefrag = 1, count = 0;

    adf_os_assert(frag);
    mac_hdr = (struct ieee80211_frame *) adf_nbuf_data(frag);
    fragno = adf_os_le16_to_cpu(*(u_int16_t *) mac_hdr->i_seq) &
        IEEE80211_SEQ_FRAG_MASK;

    if (!(*head_addr)) {
        *head_addr = frag;
        *tail_addr = frag;
        adf_nbuf_set_next(*tail_addr, NULL);
        return;
    } 
    /* For efficiency, compare with tail first */
    lmac_hdr = (struct ieee80211_frame *) adf_nbuf_data(*tail_addr);
    lfragno = adf_os_le16_to_cpu(*(u_int16_t *) lmac_hdr->i_seq) &
        IEEE80211_SEQ_FRAG_MASK;
    if (fragno > lfragno) {
        adf_nbuf_set_next(*tail_addr, frag);
        *tail_addr = frag; 
        adf_nbuf_set_next(*tail_addr, NULL);      
    } else {
        do {	
            cmac_hdr = (struct ieee80211_frame *) adf_nbuf_data(cur);
            cur_fragno = adf_os_le16_to_cpu(*(u_int16_t *) cmac_hdr->i_seq) &
                IEEE80211_SEQ_FRAG_MASK;
            prev = cur;
            cur = adf_nbuf_next(cur);
        } while (fragno > cur_fragno);

        if (fragno == cur_fragno) {
            htt_rx_desc_frame_free(htt_pdev, frag);
            *all_frag_present = 0;
            return;
        } else {
            adf_nbuf_set_next(prev, frag);
            adf_nbuf_set_next(frag, cur);
        }
    }	
    next = adf_nbuf_next(*head_addr);
    lmac_hdr = (struct ieee80211_frame *) adf_nbuf_data(*tail_addr);  
    last_morefrag = lmac_hdr->i_fc[1] & IEEE80211_FC1_MORE_FRAG;
    if (!last_morefrag) {
        do {
            next_hdr = (struct ieee80211_frame *) adf_nbuf_data(next);
            next_fragno = adf_os_le16_to_cpu(*(u_int16_t *) next_hdr->i_seq) &
                IEEE80211_SEQ_FRAG_MASK;
            count++;
            if (next_fragno != count) {
                break;
            }  
            next = adf_nbuf_next(next);  
        } while (next);
        
        if (!next) {
            *all_frag_present = 1;
            return;
        }        
    }
    *all_frag_present = 0;
}

/*
 * add tid to pending fragment wait list
 */
void
ol_rx_defrag_waitlist_add(
    struct ol_txrx_peer_t *peer,
    unsigned tid)
{
    struct ol_txrx_pdev_t *pdev = peer->vdev->pdev;
    struct ol_rx_reorder_t *rx_reorder = &peer->tids_rx_reorder[tid];

    TAILQ_INSERT_TAIL(&pdev->rx.defrag.waitlist, rx_reorder,
            defrag_waitlist_elem);
}

/*
 * remove tid from pending fragment wait list
 */
void
ol_rx_defrag_waitlist_remove(
    struct ol_txrx_peer_t *peer,
    unsigned tid)
{
    struct ol_txrx_pdev_t *pdev = peer->vdev->pdev;
    struct ol_rx_reorder_t *rx_reorder = &peer->tids_rx_reorder[tid];

    if (rx_reorder->defrag_waitlist_elem.tqe_next != NULL ||
        rx_reorder->defrag_waitlist_elem.tqe_prev != NULL) {

        TAILQ_REMOVE(&pdev->rx.defrag.waitlist, rx_reorder,
                defrag_waitlist_elem);

        rx_reorder->defrag_waitlist_elem.tqe_next = NULL;
        rx_reorder->defrag_waitlist_elem.tqe_prev = NULL;
    }
}

#ifndef container_of
#define container_of(ptr, type, member) ((type *)( \
                (char *)(ptr) - (char *)(&((type *)0)->member) ) )
#endif

/*
 * flush stale fragments from the waitlist
 */
void
ol_rx_defrag_waitlist_flush(
    struct ol_txrx_pdev_t *pdev)
{
    struct ol_rx_reorder_t *rx_reorder, *tmp;
    u_int32_t now_ms = adf_os_ticks_to_msecs(adf_os_ticks());

    TAILQ_FOREACH_SAFE(rx_reorder, &pdev->rx.defrag.waitlist,
            defrag_waitlist_elem, tmp) {
        struct ol_txrx_peer_t *peer;
        struct ol_rx_reorder_t *rx_reorder_base;
        unsigned tid;

        if (rx_reorder->defrag_timeout_ms > now_ms) {
            break;
        }

        tid = rx_reorder->tid;
        /* get index 0 of the rx_reorder array */
        rx_reorder_base = rx_reorder - tid;
        peer = container_of(rx_reorder_base, struct ol_txrx_peer_t, tids_rx_reorder[0]);

        ol_rx_defrag_waitlist_remove(peer, tid);
        ol_rx_reorder_flush_frag(pdev->htt_pdev, peer, tid, 0 /* fragments always stored at seq 0*/);
    }
}

/*
 * Handling security checking and processing fragments
 */
void 
ol_rx_defrag(
    ol_txrx_pdev_handle pdev,
    struct ol_txrx_peer_t *peer,
    unsigned tid,
    adf_nbuf_t frag_list)
{
    struct ol_txrx_vdev_t *vdev = NULL;
    adf_nbuf_t tmp_next, msdu, prev = NULL, cur = frag_list; 
    u_int8_t index, tkip_demic = 0;
    u_int16_t hdr_space; 
    void *rx_desc; 
    struct ieee80211_frame *wh;
    u_int8_t key[DEFRAG_IEEE80211_KEY_LEN];

    htt_pdev_handle htt_pdev = pdev->htt_pdev;
    vdev = peer->vdev;

    /* bypass defrag for safe mode */
    if (vdev->safemode) {
        ol_rx_deliver(vdev, peer, tid, frag_list);
        return;
    }
    
    while (cur) {
        tmp_next = adf_nbuf_next(cur);
        adf_nbuf_set_next(cur, NULL);
        if (!ol_rx_pn_check_base(vdev, peer, tid, cur)) {
            /* PN check failed,discard frags */ 
            if (prev) {
                adf_nbuf_set_next(prev, NULL);
                ol_rx_frames_free(htt_pdev, frag_list);
            }     
            ol_rx_frames_free(htt_pdev, tmp_next);  
            TXRX_PRINT(TXRX_PRINT_LEVEL_ERR, "ol_rx_defrag: PN Check failed\n");
            return;
        }
        /* remove FCS from each fragment */
        adf_nbuf_trim_tail(cur, DEFRAG_IEEE80211_FCS_LEN);
        prev = cur; 
        adf_nbuf_set_next(cur, tmp_next); 
        cur = tmp_next;
    }
    cur = frag_list;
    wh = (struct ieee80211_frame *) adf_nbuf_data(cur);
    hdr_space = ol_rx_frag_hdrsize(wh);  
    rx_desc = htt_rx_msdu_desc_retrieve(htt_pdev, frag_list);
    adf_os_assert(htt_rx_msdu_has_wlan_mcast_flag(htt_pdev, rx_desc));
    index = htt_rx_msdu_is_wlan_mcast(htt_pdev, rx_desc) ?
        txrx_sec_mcast : txrx_sec_ucast;
    
    switch (peer->security[index].sec_type) {
    case htt_sec_type_tkip:
        tkip_demic = 1;
        /* fall-through to rest of tkip ops */
    case htt_sec_type_tkip_nomic: 
        while (cur) {
            tmp_next = adf_nbuf_next(cur);
            if (!ol_rx_frag_tkip_decap(cur, hdr_space)) { 
                /* TKIP decap failed, discard frags */
                ol_rx_frames_free(htt_pdev, frag_list); 
                TXRX_PRINT(TXRX_PRINT_LEVEL_ERR,
                    "\n ol_rx_defrag: TKIP decap failed\n");
                return;
            } 
            cur = tmp_next;
        }
        break;

    case htt_sec_type_aes_ccmp:
        while (cur) {
            tmp_next = adf_nbuf_next(cur);
            if (!ol_rx_frag_ccmp_demic(cur, hdr_space)) {
                /* CCMP demic failed, discard frags */
                ol_rx_frames_free(htt_pdev, frag_list);
                TXRX_PRINT(TXRX_PRINT_LEVEL_ERR,
                    "\n ol_rx_defrag: CCMP demic failed\n");
                return;
            }
            if (!ol_rx_frag_ccmp_decap(cur, hdr_space)) {
                /* CCMP decap failed, discard frags */
                ol_rx_frames_free(htt_pdev, frag_list); 
                TXRX_PRINT(TXRX_PRINT_LEVEL_ERR,
                    "\n ol_rx_defrag: CCMP decap failed\n");
                return;
            }
            cur = tmp_next;
        }
        break;

    default:
        break;
    }

    msdu = ol_rx_defrag_decap_recombine(htt_pdev, frag_list, hdr_space);
    if (!msdu) {
        return;
    }

    if (tkip_demic) {
        adf_os_mem_copy(
            key, 
            peer->security[index].michael_key, 
            sizeof(peer->security[index].michael_key));
        if (!ol_rx_frag_tkip_demic(key, msdu, hdr_space)) {
            htt_rx_desc_frame_free(htt_pdev, msdu);
            ol_rx_err(
                pdev->ctrl_pdev,
                vdev->vdev_id, peer->mac_addr.raw, tid, 0, OL_RX_DEFRAG_ERR,
                msdu);
            TXRX_PRINT(TXRX_PRINT_LEVEL_ERR,
                "\n ol_rx_defrag: TKIP demic failed\n");
        }
    }
    wh = (struct ieee80211_frame *)adf_nbuf_data(msdu);
    if (DEFRAG_IEEE80211_QOS_HAS_SEQ(wh)) {
        ol_rx_defrag_qos_decap(msdu, hdr_space);
    }
    if (ol_cfg_frame_type(pdev->ctrl_pdev) == wlan_frm_fmt_802_3) {
       ol_rx_defrag_nwifi_to_8023(msdu);   
    } 
    ol_rx_fwd_check(vdev, peer, tid, msdu);
}

/*
 * Handling TKIP processing for defragmentation
 */
int
ol_rx_frag_tkip_decap(adf_nbuf_t msdu, u_int16_t hdrlen)
{
    struct ieee80211_frame *wh;
    u_int8_t *ivp, *origHdr;

    /* Header should have extended IV */
    origHdr = (u_int8_t*) adf_nbuf_data(msdu);
    wh = (struct ieee80211_frame *) origHdr;
    ivp = origHdr + hdrlen;
    if (!(ivp[IEEE80211_WEP_IVLEN] & IEEE80211_WEP_EXTIV)) {
        return OL_RX_DEFRAG_ERR;
    }
    adf_os_mem_move(origHdr + f_tkip.ic_header, origHdr, hdrlen);
    adf_nbuf_pull_head(msdu, f_tkip.ic_header);
    adf_nbuf_trim_tail(msdu, f_tkip.ic_trailer);

    return OL_RX_DEFRAG_OK;
}

/*
 * Verify and strip MIC from the frame.
 */
int
ol_rx_frag_tkip_demic(const u_int8_t *key, adf_nbuf_t msdu, u_int16_t hdrlen)
{
    int status;
    u_int16_t pktlen;
    struct ieee80211_frame *wh;
    u_int8_t mic[IEEE80211_WEP_MICLEN];
    u_int8_t mic0[IEEE80211_WEP_MICLEN];

    wh = (struct ieee80211_frame *)adf_nbuf_data(msdu);
    pktlen = ol_rx_defrag_len(msdu);   
    status = ol_rx_defrag_mic(
        key, msdu, hdrlen, pktlen - (hdrlen + f_tkip.ic_miclen), mic);
    if (status != OL_RX_DEFRAG_OK) {  
        return OL_RX_DEFRAG_ERR;
    }
    ol_rx_defrag_copydata(
        msdu, pktlen - f_tkip.ic_miclen, f_tkip.ic_miclen, (caddr_t) mic0);
    if (adf_os_mem_cmp(mic, mic0, f_tkip.ic_miclen)) {
        return OL_RX_DEFRAG_ERR;
    }    
    adf_nbuf_trim_tail(msdu, f_tkip.ic_miclen);
  
    return OL_RX_DEFRAG_OK;
}

/*
 * Handling CCMP processing for defragmentation
 */
int
ol_rx_frag_ccmp_decap(
    adf_nbuf_t nbuf, 
    u_int16_t hdrlen)
{
    struct ieee80211_frame *wh;
    u_int8_t *ivp, *origHdr;

    origHdr = (u_int8_t *) adf_nbuf_data(nbuf);
    wh = (struct ieee80211_frame *) origHdr;
    ivp = origHdr + hdrlen;
    if (!(ivp[IEEE80211_WEP_IVLEN] & IEEE80211_WEP_EXTIV)) {
        return OL_RX_DEFRAG_ERR;
    }
    adf_os_mem_move(origHdr + f_ccmp.ic_header, origHdr, hdrlen);
    adf_nbuf_pull_head(nbuf, f_ccmp.ic_header);

    return OL_RX_DEFRAG_OK;
}

/*
 * Verify and strip MIC from the frame.
 */
int
ol_rx_frag_ccmp_demic(
    adf_nbuf_t wbuf, 
    u_int16_t hdrlen)
{
    struct ieee80211_frame *wh;
    u_int8_t *ivp, *origHdr;

    origHdr = (u_int8_t *) adf_nbuf_data(wbuf);
    wh = (struct ieee80211_frame *) origHdr;
    ivp = origHdr + hdrlen;
    if (!(ivp[IEEE80211_WEP_IVLEN] & IEEE80211_WEP_EXTIV)) {
        return OL_RX_DEFRAG_ERR;
    }
    adf_nbuf_trim_tail(wbuf, f_ccmp.ic_trailer);  

    return OL_RX_DEFRAG_OK;
}

/*
 * Craft pseudo header used to calculate the MIC.
 */
void
ol_rx_defrag_michdr(
    const struct ieee80211_frame *wh0, 
    u_int8_t hdr[])
{
    const struct ieee80211_frame_addr4 *wh =
        (const struct ieee80211_frame_addr4 *) wh0;

    switch (wh->i_fc[1] & IEEE80211_FC1_DIR_MASK) {
    case IEEE80211_FC1_DIR_NODS:
        DEFRAG_IEEE80211_ADDR_COPY(hdr, wh->i_addr1); /* DA */
        DEFRAG_IEEE80211_ADDR_COPY(hdr + IEEE80211_ADDR_LEN, wh->i_addr2);
        break;
    case IEEE80211_FC1_DIR_TODS:
        DEFRAG_IEEE80211_ADDR_COPY(hdr, wh->i_addr3); /* DA */
        DEFRAG_IEEE80211_ADDR_COPY(hdr + IEEE80211_ADDR_LEN, wh->i_addr2);
        break;
    case IEEE80211_FC1_DIR_FROMDS:
        DEFRAG_IEEE80211_ADDR_COPY(hdr, wh->i_addr1); /* DA */
        DEFRAG_IEEE80211_ADDR_COPY(hdr + IEEE80211_ADDR_LEN, wh->i_addr3);
        break;
    case IEEE80211_FC1_DIR_DSTODS:
        DEFRAG_IEEE80211_ADDR_COPY(hdr, wh->i_addr3); /* DA */
        DEFRAG_IEEE80211_ADDR_COPY(hdr + IEEE80211_ADDR_LEN, wh->i_addr4);
        break;
    }
    /*
     * Bit 7 is IEEE80211_FC0_SUBTYPE_QOS for data frame, but
     * it could also be set for deauth, disassoc, action, etc. for 
     * a mgt type frame. It comes into picture for MFP.
     */
    if (wh->i_fc[0] & IEEE80211_FC0_SUBTYPE_QOS) {
        const struct ieee80211_qosframe *qwh =
            (const struct ieee80211_qosframe *) wh;
        hdr[12] = qwh->i_qos[0] & IEEE80211_QOS_TID;
    } else {
        hdr[12] = 0;
    }
    hdr[13] = hdr[14] = hdr[15] = 0; /* reserved */
}

/*
 * Michael_mic for defragmentation
 */
int
ol_rx_defrag_mic(
    const u_int8_t *key,
    adf_nbuf_t wbuf, 
    u_int8_t off, 
    u_int16_t data_len,
    u_int8_t mic[])
{
    u_int8_t hdr[16];
    u_int32_t l, r;
    const u_int8_t *data;
    u_int32_t space;

    ol_rx_defrag_michdr((struct ieee80211_frame *) adf_nbuf_data(wbuf), hdr);
    l = get_le32(key);
    r = get_le32(key + 4);

    /* Michael MIC pseudo header: DA, SA, 3 x 0, Priority */
    l ^= get_le32(hdr);
    michael_block(l, r);
    l ^= get_le32(&hdr[4]);
    michael_block(l, r);
    l ^= get_le32(&hdr[8]);
    michael_block(l, r);
    l ^= get_le32(&hdr[12]);
    michael_block(l, r);

    /* first buffer has special handling */
    data = (u_int8_t *)adf_nbuf_data(wbuf) + off;
    space = ol_rx_defrag_len(wbuf) - off;
    for (;;) {
        if (space > data_len) {
            space = data_len;
        }
        /* collect 32-bit blocks from current buffer */
        while (space >= sizeof(u_int32_t)) {
            l ^= get_le32(data);
            michael_block(l, r);
            data += sizeof(u_int32_t); 
            space -= sizeof(u_int32_t);
            data_len -= sizeof(u_int32_t);
        }
        if (data_len < sizeof(u_int32_t)) {
            break;
        }
        wbuf = adf_nbuf_next(wbuf);
        if (wbuf == NULL) {    
            return OL_RX_DEFRAG_ERR;
        }
        if (space != 0) {
            const u_int8_t *data_next;
            /*
             * Block straddles buffers, split references.
             */
            data_next = (u_int8_t *)adf_nbuf_data(wbuf);
            if (ol_rx_defrag_len(wbuf) < sizeof(u_int32_t) - space) {
                return OL_RX_DEFRAG_ERR;
            }
            switch (space) {
            case 1:
                l ^= get_le32_split(
                    data[0], data_next[0], data_next[1], data_next[2]);
                data = data_next + 3;
                space = ol_rx_defrag_len(wbuf) - 3;
                break;
            case 2:
                l ^= get_le32_split(
                    data[0], data[1], data_next[0], data_next[1]);
                data = data_next + 2;
                space = ol_rx_defrag_len(wbuf) - 2;
                break;
            case 3:
                l ^= get_le32_split(
                    data[0], data[1], data[2], data_next[0]);
                data = data_next + 1;
                space = ol_rx_defrag_len(wbuf) - 1;
                break;
            }
            michael_block(l, r);
            data_len -= sizeof(u_int32_t);
        } else {
            /*
             * Setup for next buffer.
             */
            data = (u_int8_t*) adf_nbuf_data(wbuf);
            space = ol_rx_defrag_len(wbuf);
        }
    }
    /* Last block and padding (0x5a, 4..7 x 0) */
    switch (data_len) {
    case 0:
        l ^= get_le32_split(0x5a, 0, 0, 0);
        break;
    case 1:
        l ^= get_le32_split(data[0], 0x5a, 0, 0);
        break;
    case 2:
        l ^= get_le32_split(data[0], data[1], 0x5a, 0);
        break;
    case 3:
        l ^= get_le32_split(data[0], data[1], data[2], 0x5a);
        break;
    }
    michael_block(l, r);
    michael_block(l, r);
    put_le32(mic, l);
    put_le32(mic + 4, r);

    return OL_RX_DEFRAG_OK;
}

/*
 * Calculate headersize
 */
int
ol_rx_frag_hdrsize(const void *data)
{
    const struct ieee80211_frame *wh = (const struct ieee80211_frame *) data;
    int size = sizeof(struct ieee80211_frame);

    if ((wh->i_fc[1] & IEEE80211_FC1_DIR_MASK) == IEEE80211_FC1_DIR_DSTODS) {
        size += IEEE80211_ADDR_LEN;
    }   
    if (DEFRAG_IEEE80211_QOS_HAS_SEQ(wh)) {
        size += sizeof(u_int16_t);
        if (wh->i_fc[1] & IEEE80211_FC1_ORDER) {
            size += sizeof(struct ieee80211_htc);
        }
    }
    return size;
}

/*
 * Recombine and decap fragments
 */
adf_nbuf_t 
ol_rx_defrag_decap_recombine(
    htt_pdev_handle htt_pdev, 
    adf_nbuf_t frag_list, 
    u_int16_t hdrsize)
{
    adf_nbuf_t tmp;
    adf_nbuf_t msdu = frag_list;
    adf_nbuf_t rx_nbuf = frag_list;
    struct ieee80211_frame* wh;

    msdu = adf_nbuf_next(msdu);
    adf_nbuf_set_next(rx_nbuf, NULL);
    while (msdu) {
        htt_rx_msdu_desc_free(htt_pdev, msdu);
        tmp = adf_nbuf_next(msdu);
        adf_nbuf_set_next(msdu, NULL);
        adf_nbuf_pull_head(msdu, hdrsize);
        if (!ol_rx_defrag_concat(rx_nbuf, msdu)) {
            ol_rx_frames_free(htt_pdev, tmp);
            htt_rx_desc_frame_free(htt_pdev, rx_nbuf); 
            adf_nbuf_free(msdu); /* msdu rx desc already freed above */
            return NULL;
        }
        msdu = tmp;     
    }
    wh = (struct ieee80211_frame *) adf_nbuf_data(rx_nbuf);  
    wh->i_fc[1] &= ~IEEE80211_FC1_MORE_FRAG; 
    *(u_int16_t *) wh->i_seq &= ~IEEE80211_SEQ_FRAG_MASK; 
   
    return rx_nbuf;
}

void
ol_rx_defrag_nwifi_to_8023(adf_nbuf_t msdu)
{
    struct ieee80211_frame wh;
    a_uint8_t type,subtype;
    a_uint32_t hdrsize;
    struct llc_snap_hdr_t llchdr;
    struct ethernet_hdr_t *eth_hdr;

    adf_os_mem_copy(&wh, adf_nbuf_data(msdu), sizeof(wh));
    type = wh.i_fc[0] & IEEE80211_FC0_TYPE_MASK;    
    subtype = wh.i_fc[0] & IEEE80211_FC0_SUBTYPE_MASK;
    /* Native Wifi header is 80211 non-QoS header */
    hdrsize = sizeof(struct ieee80211_frame);

    adf_os_mem_copy(&llchdr, ((a_uint8_t *) adf_nbuf_data(msdu)) + hdrsize,
        sizeof(struct llc_snap_hdr_t));

    /* 
     * Now move the data pointer to the beginning of the mac header : 
     * new-header = old-hdr + (wifhdrsize + llchdrsize - ethhdrsize) 
     */
    adf_nbuf_pull_head(msdu, (hdrsize + 
        sizeof(struct llc_snap_hdr_t) - sizeof(struct ethernet_hdr_t)));
    eth_hdr = (struct ethernet_hdr_t *)(adf_nbuf_data(msdu));
    switch (wh.i_fc[1] & IEEE80211_FC1_DIR_MASK) {
    case IEEE80211_FC1_DIR_NODS:
        adf_os_mem_copy(eth_hdr->dest_addr, wh.i_addr1, IEEE80211_ADDR_LEN);
        adf_os_mem_copy(eth_hdr->src_addr, wh.i_addr2, IEEE80211_ADDR_LEN);
        break;
    case IEEE80211_FC1_DIR_TODS:
        adf_os_mem_copy(eth_hdr->dest_addr, wh.i_addr3, IEEE80211_ADDR_LEN);
        adf_os_mem_copy(eth_hdr->src_addr, wh.i_addr2, IEEE80211_ADDR_LEN);
        break;
    case IEEE80211_FC1_DIR_FROMDS:
        adf_os_mem_copy(eth_hdr->dest_addr, wh.i_addr1, IEEE80211_ADDR_LEN);
        adf_os_mem_copy(eth_hdr->src_addr, wh.i_addr3, IEEE80211_ADDR_LEN);
        break;
    case IEEE80211_FC1_DIR_DSTODS:
        break;
    }
    adf_os_mem_copy(
        eth_hdr->ethertype, llchdr.ethertype, sizeof(llchdr.ethertype));
}

/*
 * Handling QOS for defragmentation
 */       
void
ol_rx_defrag_qos_decap(
    adf_nbuf_t nbuf, 
    u_int16_t hdrlen)
{
    struct ieee80211_frame *wh;
    u_int16_t qoslen;
    u_int8_t *qos;

    wh = (struct ieee80211_frame *) adf_nbuf_data(nbuf);
    if (DEFRAG_IEEE80211_QOS_HAS_SEQ(wh)) {
        qoslen = sizeof(struct ieee80211_qoscntl);
        /* Qos frame with Order bit set indicates a HTC frame */
        if (wh->i_fc[1] & IEEE80211_FC1_ORDER) {
            qoslen += sizeof(struct ieee80211_htc);
        }
        if ((wh->i_fc[1] & IEEE80211_FC1_DIR_MASK) == IEEE80211_FC1_DIR_DSTODS)
        {
            qos = &((struct ieee80211_qosframe_addr4 *) wh)->i_qos[0];
        } else {
            qos = &((struct ieee80211_qosframe *) wh)->i_qos[0];
        }
        /* remove QoS filed from header */
        hdrlen -= qoslen;
        adf_os_mem_move((u_int8_t *) wh + qoslen, wh, hdrlen);
        wh = (struct ieee80211_frame *) adf_nbuf_pull_head(nbuf, qoslen);
        /* clear QoS bit */
        wh->i_fc[0] &= ~IEEE80211_FC0_SUBTYPE_QOS;
    } 
}
