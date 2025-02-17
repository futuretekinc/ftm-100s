/*
 * Copyright (c) 2010, Atheros Communications Inc. 
 * All Rights Reserved.
 * 
 * Copyright (c) 2011 Qualcomm Atheros, Inc.
 * All Rights Reserved.
 * Qualcomm Atheros Confidential and Proprietary.
 * 
 */

/*****************************************************************************/
/*! \file ath_edma_xmit.c
**  \brief ATH Enhanced DMA Transmit Processing
**
**  This file contains the functionality for management of descriptor queues
**  in the ATH object.
**
*/

#include "ath_internal.h"
#include "ath_edma.h"
#include "if_athrate.h"

#ifdef ATH_SUPPORT_TxBF
#include "ratectrl11n.h"
#endif

#ifndef REMOVE_PKT_LOG
#include "pktlog.h"
extern struct ath_pktlog_funcs *g_pktlog_funcs;
#endif

#ifdef CONFIG_CS75XX_WFO_AR9580
extern u32 cs_wfo_rate_adjust;
extern int CS_AR9580_WFO_rc_report_rate(struct ath_softc *sc ,struct ath_tx_status * ts,
               struct ath_txq *txq);
#include "cs_atheros_11n_wfo.h"
#endif

#if UMAC_SUPPORT_SMARTANTENNA
static inline uint32_t ath_update_sa_train_stats( struct ath_softc *sc, struct ath_node *an,struct ath_buf *bf, int nBad, struct ath_tx_status *ts);
#else
static inline uint32_t ath_update_sa_train_stats( struct ath_softc *sc, struct ath_node *an,struct ath_buf *bf, int nBad, struct ath_tx_status *ts)
{
    return 0;
}
#endif

#if ATH_SUPPORT_EDMA

int
ath_tx_edma_process(ath_dev_t dev)
{
    struct ath_softc *sc = ATH_DEV_TO_SC(dev);
    int txok, nacked=0, qdepth = 0, nbad = 0;
#ifdef CONFIG_CS75XX_WFO_AR9580
       int nFrames = 0;
#endif
    struct ath_txq *txq;
    struct ath_tx_status ts;
    HAL_STATUS status;
    ath_bufhead bf_head;
    struct ath_buf *bf;
    struct ath_node *an;
#ifndef REMOVE_PKT_LOG
    u_int32_t txs_desc[9];
    u_int32_t is_training = 0;
#endif
#if ATH_SUPPORT_VOWEXT
    u_int8_t n_head_fail = 0;
    u_int8_t n_tail_fail = 0;
#endif
#ifdef ATH_SWRETRY
    struct ieee80211_frame *wh;
    bool istxfrag;
#endif

    for (;;) {

        /* hold lock while accessing tx status ring */
        ATH_TXSTATUS_LOCK(sc);

#ifndef REMOVE_PKT_LOG
        ath_hal_getrawtxdesc(sc->sc_ah, txs_desc);
#endif

        /*
         * Process a completion event.
         */
        status = ath_hal_txprocdesc(sc->sc_ah, (void *)&ts);

        ATH_TXSTATUS_UNLOCK(sc);

        if (status == HAL_EINPROGRESS)
            break;

        if (status == HAL_EIO) {
            DPRINTF(sc, ATH_DEBUG_XMIT, "%s: error processing status\n", __func__);
            break;
        }

        /* Skip beacon completions */
        if (ts.queue_id == sc->sc_bhalq) {
            /* Do the Beacon completion callback (if enabled) */
            if (atomic_read(&sc->sc_has_tx_bcn_notify)) {
                /* Notify that a beacon has completed */
                ath_tx_bcn_notify(sc);
            }
            continue;
        }

        /* Make sure the event came from an active queue */
        ASSERT(ATH_TXQ_SETUP(sc, ts.queue_id));

        /* Get the txq for the completion event */
        txq = &sc->sc_txq[ts.queue_id];
#ifdef CONFIG_CS75XX_WFO_AR9580
               if (ts.ts_wfo_flags & HAL_TX_WFO_RATE_REPORT) {

                       CS_AR9580_WFO_rc_report_rate(sc ,&ts, txq);
                       continue;
               }
#endif
        ATH_TXQ_LOCK(txq);

        txq->axq_intrcnt = 0; /* reset periodic desc intr count */
#if ATH_HW_TXQ_STUCK_WAR
        txq->tx_done_stuck_count = 0;
#endif
        bf = TAILQ_FIRST(&txq->axq_fifo[txq->axq_tailindex]);

        if (bf == NULL) {
            /*
             * Remove printk for UAPSD as bug in UAPSD when processing burst of
             * frames linked via LINK in TXBD.
             * Each frame has txstatus coresponding. However since we put only
             * 1 TXBD to the queue FIFO for all the frames, the code process the
             * first txstatus - the others txstatus will get here without a bf
             * as the first bf we pullout from
             * bf = TAILQ_FIRST(&txq->axq_fifo[txq->axq_tailindex])
             * is the parent of all the other frames.
             */
            if (txq != sc->sc_uapsdq) {
                DPRINTF(sc, ATH_DEBUG_XMIT, "%s: TXQ[%d] tailindex %d\n",
                        __func__, ts.queue_id, txq->axq_tailindex);
            }
            ATH_TXQ_UNLOCK(txq);
            return -1;
        }

        if (txq == sc->sc_cabq || txq == sc->sc_uapsdq) {
            ATH_EDMA_MCASTQ_MOVE_HEAD_UNTIL(txq, &bf_head, bf->bf_lastbf, bf_list);
        } else {
            ATH_EDMA_TXQ_MOVE_HEAD_UNTIL(txq, &bf_head, bf->bf_lastbf, bf_list);
        }

        if (bf->bf_isaggr) {
            txq->axq_aggr_depth--;
        }

#if ATH_C3_WAR
        if (txq->axq_burst_time) { 
            sc->sc_txop_burst = 1;
        } else {
            sc->sc_txop_burst = 0;
        }
#endif
        bf->bf_tx_ratecode = ts.ts_ratecode;

#ifdef ATH_SWRETRY
        txok = (ts.ts_status == 0);

        wh = (struct ieee80211_frame *)wbuf_header(bf->bf_mpdu);
        istxfrag = (wh->i_fc[1] & IEEE80211_FC1_MORE_FRAG) ||
                   (((le16toh(*((u_int16_t *)&(wh->i_seq[0]))) >>
                   IEEE80211_SEQ_FRAG_SHIFT) & IEEE80211_SEQ_FRAG_MASK) > 0);

        /* 
         * Only enable the sw retry when the following conditions are met:
         * 1. transmission failure
         * 2. swretry is enabled at this time
         * 3. non-ampdu data frame (not under protection of BAW)
         * 4. not for frames from UAPSD queue
         * 5. not for fragments
         * Otherwise, complete the TU
         */
        if (txok || (ath_check_swretry_req(sc, bf) == AH_FALSE)
            || bf->bf_isampdu || bf->bf_isaggr || !bf->bf_isdata
            || txq == sc->sc_uapsdq || istxfrag) {
            /* Change the status of the frame and complete
             * this frame as normal frame
             */
            bf->bf_status &= ~ATH_BUFSTATUS_MARKEDSWRETRY;

        } else {
            /* This frame is going through SW retry mechanism
             */
            bf->bf_status |= ATH_BUFSTATUS_MARKEDSWRETRY;
            ath_hal_setdesclink(sc->sc_ah, bf->bf_desc, 0);
        }
#endif

        ATH_TXQ_UNLOCK(txq);

#if ATH_SUPPORT_WIFIPOS
        if ((ts.ts_flags & HAL_TX_FAST_TS) ) {
            ieee80211_wifiposdata_t wifiposdata;
            u_int32_t retries;
            wbuf_t wbuf;
            ieee80211_wifipos_reqdata_t *req_data;
            u_int32_t wifipos_req_id;
            u_int8_t *req_mac_addr;

            memset(&wifiposdata, 0, sizeof(wifiposdata));
#ifdef ATH_SWRETRY
            if (bf->bf_isswretry)
                retries = bf->bf_totaltries;
            else
                retries = bf->bf_retries;
#else
            retries = bf->bf_retries;
#endif
            wbuf = bf->bf_mpdu;
            if (wbuf != NULL) {
                req_data = (ieee80211_wifipos_reqdata_t *)wbuf_get_wifipos(wbuf);
                if (req_data != NULL) {
                    wifiposdata.tod = ts.ts_tstamp;
                    wifipos_req_id = wbuf_get_wifipos_req_id(wbuf);
                    req_mac_addr = ((struct ieee80211_frame *)wbuf_header(wbuf))->i_addr1;
                    memcpy(wifiposdata.sta_mac_addr, req_mac_addr, ETH_ALEN);
                    wifiposdata.request_id = wifipos_req_id;
                    if (ts.ts_status == 0) {
                        wifiposdata.flags |= ATH_WIFIPOS_TX_STATUS;
                    }
                    wifiposdata.retries = retries;
                    wifiposdata.flags |= ATH_WIFIPOS_TX_UPDATE;
                    if (wifiposdata.flags & ATH_WIFIPOS_TX_STATUS)
                        sc->sc_ieee_ops->update_wifipos_stats(&wifiposdata);
                }
            }
        }
#endif
        an = bf->bf_node;

#ifdef ATH_SUPPORT_TxBF
        if (an != NULL) {
            struct atheros_node *oan = ATH_NODE_ATHEROS(an);
            if (oan->txbf && (ts.ts_status == 0) &&
                VALID_TXBF_RATE(ts.ts_ratecode, oan->usedNss))
            {
                if (ts.ts_txbfstatus & ATH_TXBF_stream_missed) {
                    __11nstats(sc, bf_stream_miss);
                }
                if (ts.ts_txbfstatus & ATH_TxBF_BW_mismatched) {
                    __11nstats(sc, bf_bandwidth_miss);
                }
                if (ts.ts_txbfstatus & ATH_TXBF_Destination_missed ) {
                    __11nstats(sc, bf_destination_miss);
                }
            }
        }
#endif
     
        if (an != NULL) {
            int noratectrl;
#ifdef ATH_SWRETRY
            /* If the frame is sent due to responding to PS-Poll,
             * do not retry this frame.
             */
            if ((an->an_flags & ATH_NODE_PWRSAVE) && an->an_pspoll_pending) {
                bf->bf_status &= ~ATH_BUFSTATUS_MARKEDSWRETRY;
            }
#endif
            noratectrl = an->an_flags & (ATH_NODE_CLEAN | ATH_NODE_PWRSAVE);

			OS_SYNC_SINGLE(sc->sc_osdev, bf->bf_daddr, sc->sc_txdesclen, BUS_DMA_FROMDEVICE, NULL);
            ath_hal_gettxratecode(sc->sc_ah, bf->bf_desc, (void *)&ts);

#ifdef ATH_SWRETRY            
            ath_tx_dec_eligible_frms(sc, bf, txq->axq_qnum, &ts);
#endif

            ath_tx_update_stats(sc, bf, txq->axq_qnum, &ts);

            txok = (ts.ts_status == 0);

            /*
             * Hand the descriptor to the rate control algorithm
             * if the frame wasn't dropped for filtering or sent
             * w/o waiting for an ack.  In those cases the rssi
             * and retry counts will be meaningless.
             */
            if (!bf->bf_isampdu) {
                /*
                 * This frame is sent out as a single frame. Use hardware retry
                 * status for this frame.
                 */
                bf->bf_retries = ts.ts_longretry;
                if (ts.ts_status & HAL_TXERR_XRETRY) {
                    __11nstats(sc,tx_sf_hw_xretries);
                    bf->bf_isxretried = 1;
                }
                nbad = 0;
#if ATH_SUPPORT_VOWEXT
                n_head_fail = n_tail_fail = 0;
#endif
            } else {
//#ifdef CONFIG_CS75XX_WFO_AR9580
#if 0
                               if ((ts.ts_wfo_flags & HAL_TX_WFO_RATE_REPORT) == 0)
#endif
                nbad = ath_tx_num_badfrms(sc, bf, &ts, txok);
#if ATH_SUPPORT_VOWEXT
                n_tail_fail = (nbad & 0xFF);
                n_head_fail = ((nbad >> 8) & 0xFF);
                nbad = ((nbad >> 16) & 0xFF);
#endif
            }
//#ifdef CONFIG_CS75XX_WFO_AR9580
#if 0
                       if (ts.ts_wfo_flags & HAL_TX_WFO_RATE_REPORT) {
                               nFrames = (ts.ba_low & 0xffff0000) >> 16;
                               nbad = (ts.ba_low & 0x0000ffff);
                       }
#endif

            if ((ts.ts_status & HAL_TXERR_FILT) == 0 &&
                (bf->bf_flags & HAL_TXDESC_NOACK) == 0)
            {
                /*
                 * If frame was ack'd update the last rx time
                 * used to workaround phantom bmiss interrupts.
                 */
                if (ts.ts_status == 0)
                    nacked++;

                if (bf->bf_isdata && !noratectrl &&
                            likely(!bf->bf_useminrate)) {
#ifdef ATH_SUPPORT_VOWEXT
                    /* FIXME do not care Ospre related issues as on today, keep
                       this pending until we get to that
                     */
                    ath_rate_tx_complete_11n(sc,
                            an,
                            &ts,
                            bf->bf_rcs,
                            TID_TO_WME_AC(bf->bf_tidno),
                            bf->bf_nframes,
                            nbad, n_head_fail, n_tail_fail,
                            ath_tx_get_rts_retrylimit(sc, txq),
#ifdef ATH_SUPPORT_UAPSD
                            (txq == sc->sc_uapsdq) ? NULL: &bf->bf_pp_rcs);
#else
                                                 &bf->bf_pp_rcs);
#endif
#else
                     ath_rate_tx_complete_11n(sc,
                            an,
                            &ts,
                            bf->bf_rcs,
                            TID_TO_WME_AC(bf->bf_tidno),
                            bf->bf_nframes,
                            nbad,
                            ath_tx_get_rts_retrylimit(sc, txq),
#ifdef ATH_SUPPORT_UAPSD
                            (txq == sc->sc_uapsdq) ? NULL: &bf->bf_pp_rcs);
#else
                                                 &bf->bf_pp_rcs);
#endif
#endif

#ifndef REMOVE_PKT_LOG
                is_training = ath_update_sa_train_stats(sc, an, bf, nbad, &ts);
#else
                ath_update_sa_train_stats(sc, an, bf, nbad, &ts);
#endif
                }
            }

#ifdef ATH_SWRETRY
            if ((CHK_SC_DEBUG(sc, ATH_DEBUG_SWR)) &&
                (ts.ts_status || bf->bf_isswretry) && (bf->bf_status & ATH_BUFSTATUS_MARKEDSWRETRY))
            {
                struct ieee80211_frame * wh;
                wh = (struct ieee80211_frame *)wbuf_header(bf->bf_mpdu);
                DPRINTF(sc, ATH_DEBUG_SWR,
                        "%s: SeqCtrl0x%02X%02X --> status %08X rate %02X, swretry %d retrycnt %d totaltries %d\n",
                        __func__, wh->i_seq[0], wh->i_seq[1], ts.ts_status, ts.ts_ratecode,
                        (bf->bf_isswretry)?1:0, bf->bf_swretries, bf->bf_totaltries +
                        ts.ts_longretry + ts.ts_shortretry);

                DPRINTF(sc, ATH_DEBUG_SWR, "%s, %s, type=0x%x, subtype=0x%x\n",
                        (ts.ts_status & HAL_TXERR_FILT) != 0?"IS FILT":"NOT FILT",
                        (ts.ts_status & HAL_TXERR_XRETRY) != 0?"IS XRETRY":"NOT XRETRY",
                        wh->i_fc[0] & IEEE80211_FC0_TYPE_MASK,
                        wh->i_fc[0] & IEEE80211_FC0_SUBTYPE_MASK);
            }

            if (bf->bf_status & ATH_BUFSTATUS_MARKEDSWRETRY) {
#ifndef REMOVE_PKT_LOG
                /* do pktlog */
                {
                    struct log_tx log_data;
                    struct ath_buf *tbf;
    
                    TAILQ_FOREACH(tbf, &bf_head, bf_list) {
                        log_data.firstds = tbf->bf_desc;
                        log_data.bf = tbf;
                        ath_log_txctl(sc, &log_data, 0);
                    }
                }
            	{
                	struct log_tx log_data;
                	log_data.lastds = &txs_desc;
                	ath_log_txstatus(sc, &log_data, 0);
            	}
#endif
                /* Put the sw retry frame back to tid queue */
                ath_tx_mpdu_requeue(sc, txq, &bf_head, ts);

                /* We have completed the buf in resend in case of
                 * failure and hence not needed and will be fatal
                 * if we fall through this
                 */
               continue;
            }
#endif
            /*
             * Complete this transmit unit
             *
             * Node cannot be referenced past this point since it can be freed
             * here.
             */
            if (bf->bf_isampdu) {
                if (ts.ts_flags & HAL_TX_DESC_CFG_ERR)
                    __11nstats(sc, txaggr_desc_cfgerr);
                if (ts.ts_flags & HAL_TX_DATA_UNDERRUN) {
                    __11nstats(sc, txaggr_data_urun);
#if ATH_C3_WAR
                    sc->sc_fifo_underrun = 1;
#endif
                }
                if (ts.ts_flags & HAL_TX_DELIM_UNDERRUN) {
                    __11nstats(sc, txaggr_delim_urun);
#if ATH_C3_WAR
                    sc->sc_fifo_underrun = 1;
#endif
                }
                ath_tx_complete_aggr_rifs(sc, txq, bf, &bf_head, &ts, txok);
            } else {
#ifndef REMOVE_PKT_LOG
                /* do pktlog */
                {
                    struct log_tx log_data;
                    struct ath_buf *tbf;

                    TAILQ_FOREACH(tbf, &bf_head, bf_list) {
                        log_data.firstds = tbf->bf_desc;
                        log_data.bf = tbf;
                        ath_log_txctl(sc, &log_data, 0);
                    }
                }
#endif

#ifdef ATH_SUPPORT_UAPSD
                if (txq == sc->sc_uapsdq)
                {
#ifdef ATH_SUPPORT_TxBF
                    ath_tx_uapsd_complete(sc, an, bf, &bf_head, txok, ts.ts_txbfstatus, ts.ts_tstamp);
#else
                    ath_tx_uapsd_complete(sc, an, bf, &bf_head, txok);
#endif
                }
                else
#endif
                {
#ifdef  ATH_SUPPORT_TxBF
                    ath_tx_complete_buf(sc, bf, &bf_head, txok, ts.ts_txbfstatus, ts.ts_tstamp);
#else
                    ath_tx_complete_buf(sc, bf, &bf_head, txok);
#endif
                }
            }
#ifdef __NetBSD__
            if (txok && !(bf->bf_flags & HAL_TXDESC_NOACK))
                    sc->rchk_txack_counter++;
#endif
#ifndef REMOVE_PKT_LOG
            /* do pktlog */
            {
                struct log_tx log_data;
                log_data.lastds = &txs_desc;
                /* Misc data to store training packet details*/
                log_data.misc[0] = is_training;
                ath_log_txstatus(sc, &log_data, 1);
            }
#endif
        } else {
           /* PAPRD has NULL an */
            if (bf->bf_state.bfs_ispaprd) {
                ath_tx_paprd_complete(sc, bf, &bf_head);
                //printk("%s[%d]: ath_tx_paprd_complete called txok %d\n", __func__, __LINE__, txok);
                return -1;
            }
        }

        /*
         * schedule any pending packets if aggregation is enabled
         */

        ATH_TXQ_LOCK(txq);
        ath_txq_schedule(sc, txq);
        ATH_TXQ_UNLOCK(txq);

        qdepth += ath_txq_depth(sc, txq->axq_qnum);

#if defined(ATH_SWRETRY) && defined(ATH_SWRETRY_MODIFY_DSTMASK) 
		ATH_TXQ_LOCK(txq);
        if (ath_txq_depth(sc, txq->axq_qnum) == 0)
            if (sc->sc_swRetryEnabled)
                txq->axq_destmask = AH_TRUE;
		ATH_TXQ_UNLOCK(txq);
#endif
    }

    return qdepth;
}

/******************************************************************************/
/*!
**  \brief updating smart antenna train stats to umac
**
**  \param sc Pointer to sc object
**  \param an pointer to node object
**  \param bf pointer to buffer
**  \param nbad number of failed frames
**  \param tx tx status from hardware
**  \output returns training packet status
*/

#if UMAC_SUPPORT_SMARTANTENNA
static inline uint32_t ath_update_sa_train_stats(struct ath_softc *sc,
                                                 struct ath_node *an,
                                                 struct ath_buf *bf,
                                                 int nbad,
                                                 struct ath_tx_status *ts)
{
#ifndef REMOVE_PKT_LOG
    u_int32_t is_training = 0;
#endif

    if(unlikely(wbuf_is_sa_train_packet(bf->bf_mpdu))) {

#ifndef REMOVE_PKT_LOG
        is_training = 1;
#endif                       

        if(an->train_status) {
            an->train_data.nFrames += bf->bf_nframes;

            if(ts->ts_rateindex) {
                an->train_data.nBad += bf->bf_nframes;
            } else {
                /* Update RSSI when programed train rateidx trasmited */
                an->train_data.nBad += nbad;
                if ((ts->ts_rssi_ctl0 > 0) && (ts->ts_rssi_ctl0 < 127)) {
                    an->train_data.rssi[0][an->train_data.samples] = ts->ts_rssi_ctl0;
                    an->train_data.rssi[1][an->train_data.samples] = ts->ts_rssi_ctl1;
                    an->train_data.rssi[2][an->train_data.samples] = ts->ts_rssi_ctl2;
                    an->train_data.samples++; 
                    if (an->train_data.samples >= SA_MAX_RSSI_SAMPLES)
                        an->train_data.samples=0; 
                }
            }
            if ((an->train_data.nFrames > an->train_data.numpkts) ||
                    ((an->train_data.nFrames > (an->train_data.numpkts >> 1)) && 
                     ((100*an->train_data.nBad/an->train_data.nFrames) > SA_TRAIN_PER_THRESHOLD))) {
                an->train_status = 0;

#if (SA_DEBUG == 2)
                DPRINTF(sc, ATH_DEBUG_XMIT,"%s : nFrames: %d  nBad:%d Ratecode:0x%02x : antenna: %d \n", __func__, an->train_data.nFrames,an->train_data.nBad
                        ,an->train_data.ratecode
                        ,an->train_data.antenna
                      );  
#endif
                sc->sc_ieee_ops->update_sa_pertable(an->an_node, (void *)&an->train_data);
                an->train_data.nFrames = 0;
                an->train_data.nBad = 0;
                memset(&an->train_data.rssi[0][0], 0, (SA_MAX_RSSI_SAMPLES * SA_MAX_RECV_CHAINS));
                an->train_data.samples = 0;
            }
        }
        wbuf_sa_unset_train_packet(bf->bf_mpdu);
    }
#ifndef REMOVE_PKT_LOG
    return is_training;
#else
    return 0;
#endif
}
#endif

/******************************************************************************/
/*!
**  \brief Transmit Tasklet
**
**  Deferred processing of transmit interrupt.
**
**  \param dev Pointer to ATH_DEV object
**
*/

/*
 * Deferred processing of transmit interrupt.
 * Tx Interrupts need to be disabled before entering this.
 */
void
ath_tx_edma_tasklet(ath_dev_t dev)
{
    struct ath_softc *sc = ATH_DEV_TO_SC(dev);
    int qdepth;

    ath_vap_pause_txq_use_inc(sc);
    qdepth = ath_tx_edma_process(dev);
    ath_vap_pause_txq_use_dec(sc);

    if (sc->sc_ieee_ops->notify_txq_status && (qdepth == 0))
        sc->sc_ieee_ops->notify_txq_status(sc->sc_ieee, qdepth);
}

int
ath_tx_edma_init(struct ath_softc *sc)
{
    int error = 0;

    if (sc->sc_enhanceddmasupport) {
        ATH_TXSTATUS_LOCK_INIT(sc);

        /* allocate tx status ring */
        error = ath_txstatus_setup(sc, &sc->sc_txsdma, "txs", ATH_TXS_RING_SIZE);
        if (error == 0) {
            ath_hal_setuptxstatusring(sc->sc_ah, sc->sc_txsdma.dd_desc,
                                  sc->sc_txsdma.dd_desc_paddr, ATH_TXS_RING_SIZE);
        }
    }

    return error;
}

void
ath_tx_edma_cleanup(struct ath_softc *sc)
{
    if (sc->sc_enhanceddmasupport) {
        /* cleanup tx status descriptors */
        if (sc->sc_txsdma.dd_desc_len != 0)
            ath_txstatus_cleanup(sc, &sc->sc_txsdma);

        ATH_TXSTATUS_LOCK_DESTROY(sc);
    }
}
#endif /* ATH_SUPPORT_EDMA */
