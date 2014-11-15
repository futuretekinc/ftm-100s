#include <osdep.h>
#include "adf_nbuf_pvt.h"
#include "athdefs.h"
#include "osif_private.h"
#include "if_athvar.h"
#include "ah.h"
#include "ath_internal.h"
#include "cs_atheros_11n_wfo.h"
#include "ar9300/ar9300desc.h"
#include <linux/proc_fs.h>
#include "ratectrl.h"


#if 0
#include "ah_internal.h"
#else
/*
 * the following structure is defined in "ah_internal.h"
 * but we cannot include it due to some conflict definition with ath_dev.h
 */
#include "ah_osdep.h"
//typedef unsigned int u_int;

struct ath_hal_private {
    struct ath_hal  h;          /* public area */

    /* NB: all methods go first to simplify initialization */
    bool    (*ah_get_channel_edges)(struct ath_hal*,
                u_int16_t channel_flags,
                u_int16_t *lowChannel, u_int16_t *highChannel);
    u_int       (*ah_get_wireless_modes)(struct ath_hal*);
    bool    (*ah_eeprom_read)(struct ath_hal *, u_int off,
                u_int16_t *data);
    bool    (*ah_eeprom_write)(struct ath_hal *, u_int off,
                u_int16_t data);
    u_int       (*ah_eeprom_dump)(struct ath_hal *ah, void **pp_e);
    bool    (*ah_get_chip_power_limits)(struct ath_hal *,
                HAL_CHANNEL *, u_int32_t);
    int16_t     (*ah_get_nf_adjust)(struct ath_hal *,
                const /*HAL_CHANNEL_INTERNAL*/void *);

    u_int16_t   (*ah_eeprom_get_spur_chan)(struct ath_hal *, u_int16_t, bool);
    /*
     * Device revision information.
     */
    HAL_ADAPTER_HANDLE  ah_osdev;           /* back pointer to OS adapter handle */
    HAL_BUS_TAG         ah_st;              /* params for register r+w */
    HAL_BUS_HANDLE      ah_sh;              /* back pointer to OS bus handle */
    HAL_SOFTC           ah_sc;              /* back pointer to driver/os state */
    u_int32_t           ah_magic;           /* HAL Magic number*/
    u_int16_t           ah_devid;           /* PCI device ID */
    u_int32_t           ah_mac_version;      /* MAC version id */
    u_int16_t           ah_mac_rev;          /* MAC revision */
    u_int16_t           ah_phy_rev;          /* PHY revision */
    u_int16_t           ah_analog_5ghz_rev;   /* 2GHz radio revision */
    u_int16_t           ah_analog2GhzRev;   /* 5GHz radio revision */
    u_int32_t           ah_flags;           /* misc flags */
#if 0
	/*WFO don't need the follow information */
#endif
};
#define AH_PRIVATE(_ah) ((struct ath_hal_private *)(_ah))
#endif

extern int cs_pni_unregister_callback(u8 *tx_base, void* adapter);
extern int cs_pni_get_free_pid();

extern int cs_pni_register_chip_callback_xmit(u8 chip_type, int instance,
	void* adapter, u16 (*cb) , u16 (*cb_8023) , u16 (*cb_xmit_done));
extern void cs_pni_xmit_ar988x(u8 pe_id, u8 voq, u32 buf0, int len0, u32 buf1, int len1, struct sk_buff *skb);

extern int cs_hw_accel_wfo_clean_fwd_path_by_mac(char * mac);
extern wfo_mac_entry_status_e cs_wfo_set_mac_entry(wfo_mac_entry_s *mac_entry);
extern int cs_wfo_ipc_wait_send_complete(u8 pe_id, u8 msg_type, u8 *pmsg, u8 payload_size);

extern int ath_rx_handler(ath_dev_t dev, int flush, HAL_RX_QUEUE qtype);
extern void cs_wfo_del_hash_by_mac_da(u8 *mac);

struct ieee80211_node	*cs_local_sc_keyixmap[ATH_KEYMAX];/* key ix->node map */



/* Object relatiion
.... scn to sc
		struct ath_softc_net80211 *scn;
		struct ath_softc *sc == scn->sc_dev == ATH_DEV_TO_SC(dev);

.... sc to scn

		struct ath_softc *sc;

		struct ath_softc_net80211 *scn == ATH_SOFTC_NET80211(sc->sc_ieee) == sc->sc_ieee;

		ieee80211_handle_t ieee == ATH_SOFTC_NET80211(sc->sc_ieee);
		struct ieee80211com *ic = NET80211_HANDLE(ieee);
	    struct ath_softc_net80211 *scn = ATH_SOFTC_NET80211(ic);
*/
void cs_wfo_11n_dump_skb(struct sk_buff *skb)
{
	int len = skb->len;
	int i;
	if (len > 64)
		len = 64;
	for (i = 0; i < len; i++){
		printk("%02X ", skb->data[i]);
		if ((i % 32) == 31)
			printk("\n");
	}
	printk("\n");

}


/*
 * proc tools
 */
#define CS752X_QCA_11n_PWR_SAVING_ENABLE		"wfo_qca_11n_pwr_saving_enable"
extern int cs752x_add_proc_handler(char *name,
			    read_proc_t * hook_func_read,
			    write_proc_t * hook_func_write,
			    struct proc_dir_entry *parent);

extern struct proc_dir_entry *proc_driver_cs752x_wfo;

u8 cs_ar9580_power_saving_enable = 0;
/* file handler for WFO_RATE_ADJUST */
static int CS_AR9580_proc_pwr_saving_enable_read_proc(char *buf, char **start, off_t offset,
				   int count, int *eof, void *data)
{
	u32 len = 0;

	len += sprintf(buf + len, "Purpose: Enable QCA 11n WFO Power saving  ");
	len += sprintf(buf + len, "\n%s = 0x%08x\n", CS752X_QCA_11n_PWR_SAVING_ENABLE, cs_ar9580_power_saving_enable);
	*eof = 1;

	return len;
}

static int CS_AR9580_proc_pwr_saving_enable_write_proc(struct file *file, const char *buffer,
				    unsigned long count, void *data)
{
	char buf[32];
	unsigned long mask;
	ssize_t len;

	len = min(count, (unsigned long)(sizeof(buf) - 1));
	if (copy_from_user(buf, buffer, len))
		goto WFO_DEBUG_INVAL_EXIT;

	buf[len] = '\0';
	if (strict_strtoul(buf, 0, &mask))
		goto WFO_DEBUG_INVAL_EXIT;

	if (mask > 1)
		goto WFO_DEBUG_INVAL_EXIT;

	cs_ar9580_power_saving_enable = mask;
	printk(KERN_WARNING "Set %s as 0x%08x\n", CS752X_QCA_11n_PWR_SAVING_ENABLE, cs_ar9580_power_saving_enable);

	return count;

WFO_DEBUG_INVAL_EXIT:
	printk(KERN_WARNING "Invalid argument\n");
	printk(KERN_WARNING "%s should be 0 or 1 \n", CS752X_QCA_11n_PWR_SAVING_ENABLE);
	/* if we return error code here, PROC fs may retry up to 3 times. */
	return count;
}


void CS_AR9580_proc_init_module(void) {
	cs752x_add_proc_handler(CS752X_QCA_11n_PWR_SAVING_ENABLE,
			CS_AR9580_proc_pwr_saving_enable_read_proc,
			CS_AR9580_proc_pwr_saving_enable_write_proc,
			proc_driver_cs752x_wfo);
}

void CS_AR9580_proc_exit_module(void) {

	remove_proc_entry(CS752X_QCA_11n_PWR_SAVING_ENABLE, proc_driver_cs752x_wfo);
}


bool CS_AR9580_WFO_send_reset_tx(struct ath_softc_net80211 *scn)
{
	if (scn->wfo_enabled) {
		cs_ar9580_wfo_ipc_update_msg_t    ar9580_ipc_msg;

		printk("%s \n", __func__);
    	memset(&ar9580_ipc_msg, 0, sizeof(cs_ar9580_wfo_ipc_update_msg_t));
    	ar9580_ipc_msg.ipc_msg_hdr.pe_id = scn->pid;
	    ar9580_ipc_msg.ipc_msg_hdr.hdr.pe_msg.wfo_cmd = CS_WFO_IPC_MSG_CMD_RESET_TX;

		uint32_t * pcie_mem = CS_A9580_A9_PCIE_PADDR;
		memset(pcie_mem, 0, sizeof(uint32_t * ) * HAL_NUM_TX_QUEUES * HAL_TXFIFO_DEPTH);
		printk("\t %s set mem %p size %d to 0 \n", __func__, pcie_mem, sizeof(uint32_t * ) * HAL_NUM_TX_QUEUES * HAL_TXFIFO_DEPTH);
		cs_wfo_ipc_wait_send_complete(scn->pid, CS_WFO_IPC_PE_MESSAGE, &ar9580_ipc_msg, sizeof(cs_ar9580_wfo_ipc_update_msg_t));
	}
	return true;
}

bool CS_AR9580_WFO_send_reset_rx(struct ath_softc_net80211 *scn)
{
	if (scn->wfo_enabled) {
		cs_ar9580_wfo_ipc_update_msg_t ar9580_ipc_msg;

		printk("%s \n", __func__);
    	memset(&ar9580_ipc_msg, 0, sizeof(cs_ar9580_wfo_ipc_update_msg_t));
    	ar9580_ipc_msg.ipc_msg_hdr.pe_id = scn->pid;
	    ar9580_ipc_msg.ipc_msg_hdr.hdr.pe_msg.wfo_cmd = CS_WFO_IPC_MSG_CMD_RESET_RX;

		cs_wfo_ipc_wait_send_complete(scn->pid, CS_WFO_IPC_PE_MESSAGE, &ar9580_ipc_msg, sizeof(cs_ar9580_wfo_ipc_update_msg_t));

	}
	return true;
}


bool CS_AR9580_WFO_ath_hal_reset(struct ath_hal *ah, HAL_OPMODE opmode, HAL_CHANNEL *chan,
    HAL_HT_MACMODE macmode, u_int8_t txchainmask, u_int8_t rxchainmask,
    HAL_HT_EXTPROTSPACING extprotspacing, bool b_channel_change,
    HAL_STATUS *pstatus, int is_scan)
{
	struct ath_softc *sc = AH_PRIVATE(ah)->ah_sc;

	if (CS_AR9580_WFO_enabled(sc->sc_ieee)) {
		printk("%s sc=%p ah=%p \n", __func__, sc, ah);
		CS_AR9580_WFO_send_reset_tx(sc->sc_ieee);
	}

	return ((*(ah)->ah_reset)((ah), (opmode), (chan), (macmode), (txchainmask), (rxchainmask), (extprotspacing), (b_channel_change), (pstatus), (is_scan)));
}

EXPORT_SYMBOL(CS_AR9580_WFO_ath_hal_reset);

bool CS_AR9580_WFO_ath_hal_puttxbuf(struct ath_hal *ah, u_int q, u_int32_t txdp)
{
	struct ath_softc *sc = AH_PRIVATE(ah)->ah_sc;

	if (CS_AR9580_WFO_enabled(sc->sc_ieee)) {
		CS_AR9580_WFO_TX_80211n(sc->sc_ieee, q, txdp, NULL);
		return true;
	} else
		return ((*(ah)->ah_set_tx_dp)((ah), (q), (txdp)));
}
EXPORT_SYMBOL(CS_AR9580_WFO_ath_hal_puttxbuf);

bool CS_AR9580_WFO_enabled(struct ath_softc_net80211 *scn)
{
	return scn->wfo_enabled;
}

u8 CS_AR9580_HandleRxFrameFromPNI_80211(
	u8 rx_voq,
	struct ath_softc_net80211 *scn,
	struct sk_buff *skb)
{
	int voq_idx;
	struct ath_softc *sc = scn->sc_dev;
	struct ath_buf *bf, *tbf;
    struct ath_rx_edma *rxedma;
	wbuf_t wbuf;
	voq_idx = rx_voq - CPU_PORT4_VOQ_BASE;
	int qtype;

	qtype = (voq_idx == 0) ?  HAL_RX_QUEUE_HP:  HAL_RX_QUEUE_LP;

	if (qtype == HAL_RX_QUEUE_HP) {
		/*DEBUG purpose*/
		printk("\n%s voq=%d skb->len=%d scn=%p\n", __func__, rx_voq, skb->len, scn);
		cs_wfo_11n_dump_skb(skb);
	}
	ATH_RXBUF_LOCK(sc);

	if (TAILQ_EMPTY(&sc->sc_rxbuf)) {
		ATH_RXBUF_UNLOCK(sc);
		printk("%s[%d]: Out of buffers\n", __func__, __LINE__);
		dev_kfree_skb(skb);
		return -1;
	}
	/*
	 * 1. get a free bf from sc_rxbuff, refer to ath_rx_addbuffer()
	 */

	bf = TAILQ_FIRST(&sc->sc_rxbuf) ;
	TAILQ_REMOVE(&sc->sc_rxbuf, bf, bf_list);
	ATH_RXBUF_UNLOCK(sc);

	if (bf == NULL) {
		printk("%s[%d]: Out of buffers for bf\n", __func__, __LINE__);
	}
	rxedma = &sc->sc_rxedma[qtype];

	/*
     * 2. release wbuff in bf, refer to ath_rx_edma_cleanup()
	 */
	wbuf = bf->bf_mpdu;
	if (wbuf) {
		dev_kfree_skb(wbuf);
	}

	/*
	 * 3. initialize wbuff in bf, refer to ath_rx_edma_init() or ath_rx_indicate()
	 */
	wbuf = skb;
	bf->bf_mpdu = wbuf;
	bf->bf_buf_addr[0] = virt_to_phys(wbuf->data);
	ATH_SET_RX_CONTEXT_BUF(wbuf, bf);
	skb->tail = skb->data;
	skb->len = 0;

	/*
	 * 4. parse rx status(descriptor), refer to ath_rx_intr()
	 */
	struct ath_rx_status *rxs;
	HAL_STATUS retval;
	struct ath_hal *ah = sc->sc_ah;
	bf->bf_status |= ATH_BUFSTATUS_SYNCED;
	rxs = bf->bf_desc;
	/* ath_hal_rxprocdescfast() == ar9300_proc_rx_desc_fast()*/
    retval = ath_hal_rxprocdescfast(ah, NULL, 0, NULL, rxs, wbuf_raw_data(wbuf));
	if (HAL_EINVAL == retval) {
		printk("%s this should not happen ??? HAL_EINVAL == retval\n", __func__);
		cs_wfo_11n_dump_skb(skb);
		dev_kfree_skb(skb);
		ATH_RXBUF_LOCK(sc);
		bf->bf_mpdu = NULL;
		TAILQ_INSERT_TAIL(&sc->sc_rxbuf, bf, bf_list);
		ATH_RXBUF_UNLOCK(sc);
		return -1;
	}

	if (HAL_EINPROGRESS == retval) {
		printk("%s this should not happen ??? HAL_EINPROGRESS == retval\n", __func__);

		dev_kfree_skb(skb);
		ATH_RXBUF_LOCK(sc);
		bf->bf_mpdu = NULL;
		TAILQ_INSERT_TAIL(&sc->sc_rxbuf, bf, bf_list);
		ATH_RXBUF_UNLOCK(sc);
		return -1;
	}

#ifdef ATH_SUPPORT_UAPSD
#if !ATH_OSPREY_UAPSDDEFERRED
	/* Process UAPSD triggers */
	/* Skip frames with error - except HAL_RXERR_KEYMISS since
	 * for static WEP case, all the frames will be marked with HAL_RXERR_KEYMISS,
	 * since there is no key cache entry added for associated station in that case
	 */
	if ((rxs->rs_status & ~HAL_RXERR_KEYMISS) == 0)
	{
		/* UAPSD frames being processed from ISR context */
		ath_rx_process_uapsd(sc, qtype, wbuf, rxs, true);
	}
#endif /* ATH_OSPREY_UAPSDDEFERRED */
#else
		 rxs->rs_isapsd = 0;
#endif /* ATH_SUPPORT_UAPSD */


	/* add this ath_buf for deferred processing */
	ATH_RXQ_LOCK(rxedma);
    TAILQ_INSERT_TAIL(&rxedma->rxqueue, bf, bf_list);
	ATH_RXQ_UNLOCK(rxedma);

	/*
	 * 5. send to LMAC layer
	 */
	ath_rx_handler(sc, 0, qtype);

	return 0;
}


u8 CS_AR9580_HandleRxFrameFromPNI_8023(
	u8 rx_voq,
	struct ath_softc_net80211 *scn,
	struct sk_buff *skb_list)
{
	struct ath_softc *sc = scn->sc_dev;
	struct ieee80211com *ic = &scn->sc_ic; /*scn == &scn->sc_ic*/
	struct ieee80211vap *vap;
	os_if_t osifp;
	wbuf_t wbuf_cpy = NULL;

	vap = TAILQ_FIRST(&ic->ic_vaps);
	if (vap != NULL ) {
		//osifp = wlan_vap_get_registered_handle(vap);
		osifp = vap->iv_ifp;
#if 0
		printk("%s voq=%d skb->len=%d osifp=%p\n", __func__, rx_voq, skb_list->len, osifp);
		cs_wfo_11n_dump_skb(skb_list);
#endif
		cs_hw_accel_wfo_wifi_rx(CS_WFO_CHIP_AR9580, scn->pid, skb_list);
		int b_same_vap;
		/*
		 * Check if destination is associated with the
		 * same vap and authorized to receive traffic.
		 * Beware of traffic destined for the vap itself;
		 * sending it will not work; just let it be
		 * delivered normally.
		 */
		/*
		 * because the needed functions (such as ieee80211_find_node ) in umac.ko,
		 * but our wfo driver is in ath_dev.ko. So we need to use func ptr
		 * to call functions in umac.ko
		 */
		b_same_vap = sc->sc_ieee_ops->cs_wfo_check_send_back_to_same_vap(vap, skb_list);

		if (b_same_vap == 1) {
			/*
			 * for uni-cast packet
			 */
			cs_kernel_accel_cb_t *cs_cb = CS_KERNEL_SKB_CB(skb_list);
			if (cs_cb != NULL) {
				cs_cb->common.module_mask |= CS_MOD_MASK_BRIDGE;
				cs_cb->common.sw_only = CS_SWONLY_HW_ACCEL;
			}
			/*
			 * send the frame copy back to the interface.
			 * this frame is either multicast frame. or unicast frame
			 * to one of the stations.
			 */

			vap->iv_evtable->wlan_vap_xmit_queue(vap->iv_ifp, skb_list);

		} else if (b_same_vap == 2) {
			/*
			 * for multicast packet
			 */
			wbuf_cpy = wbuf_clone(vap->iv_ic->ic_osdev, skb_list);
#if ATH_RXBUF_RECYCLE
				wbuf_set_cloned(wbuf_cpy);
#endif
			vap->iv_evtable->wlan_vap_xmit_queue(vap->iv_ifp, wbuf_cpy);
			vap->iv_evtable->wlan_receive(vap->iv_ifp, skb_list, IEEE80211_FC0_TYPE_DATA, 0, 0);
		} else {
			/*
			 * send to linux via
			 *   osif_pltfrm_receive(osifp ,skb_list, IEEE80211_FC0_TYPE_DATA, 0, 0);
			 */
			vap->iv_evtable->wlan_receive(vap->iv_ifp, skb_list, IEEE80211_FC0_TYPE_DATA, 0, 0);
		}
	} else {
		printk("%s vap == NULL \n", __func__);
		dev_kfree_skb(skb_list);
	}
	return 0;
}

bool CS_AR9580_WFO_TX_mac_entry_delete(struct ath_softc_net80211 *scn, struct ieee80211_node *ni)
{
	if (CS_AR9580_WFO_enabled(scn) == 0)
		return false;

	printk("%s:: %pM ni_flags = %x. cs_wfo_status = %d.\n", __func__, ni->ni_macaddr, ni->ni_flags, ni->cs_wfo_status);
	cs_hw_accel_wfo_clean_fwd_path_by_mac(ni->ni_macaddr);
	if (ni->cs_wfo_status != CS_WFO_NI_ADD_HASH) {
		if (ni->pe_key.wk_keyix < ATH_KEYMAX)
			cs_local_sc_keyixmap[ni->pe_key.wk_keyix] = 0;
	}
	ni->cs_wfo_status = CS_WFO_NI_NEW;

	return true;
}

bool CS_AR9580_WFO_TX_mac_entry_update(struct ath_softc_net80211 *scn, int type, struct ieee80211_node *ni
 	, struct ar9300_txc *ads, ieee80211_tx_control_t *txctl, struct ath_rc_series *rcs)
{

	if (CS_AR9580_WFO_enabled(scn) == 0)
		return false;
   	/*
	 * need to inform PE for node update by CS_WFO_IPC_MSG_CMD_UPDATED_TXWI
	 */
	cs_ar9580_wfo_ipc_update_msg_t    ar9580_ipc_msg;
	//printk("%s ni %pM type=%d\n", __func__, ni->ni_macaddr, type);
	//DPRINTF(scn, ATH_DEBUG_TX99, "%s ni %pM type=%d\n", __func__, ni->ni_macaddr, type);

    memset(&ar9580_ipc_msg, 0, sizeof(cs_ar9580_wfo_ipc_update_msg_t));
    ar9580_ipc_msg.ipc_msg_hdr.pe_id = scn->pid;
    ar9580_ipc_msg.ipc_msg_hdr.hdr.pe_msg.wfo_cmd = CS_WFO_IPC_MSG_CMD_UPDATED_TXWI;
	ar9580_ipc_msg.field_mask = type;
	memcpy(&ar9580_ipc_msg.mac_address[0], ni->ni_macaddr, 6);
	if (type & NI_FIELD_KEY) {
		//ar9580_ipc_msg.dest_idx = (ads->ds_ctl12 & AR_dest_idx)  >> AR_dest_idx_S;
		//ar9580_ipc_msg.encrypt_type = (ads->ds_ctl17 & AR_encr_type) >> AR_encr_type_S;
		/* because keyix will be used for ctrl_11 and ctrl_12*/
		ar9580_ipc_msg.dest_idx = txctl->keyix;
		ar9580_ipc_msg.encrypt_type = txctl->keytype;
		ar9580_ipc_msg.frame_type = (ads->ds_ctl12 & AR_frame_type) >> AR_frame_type_S;
		struct ieee80211vap *vap = ni->ni_vap;
		//if (IEEE80211_VAP_IS_PRIVACY_ENABLED(vap)) {
			struct ieee80211_key *k = NULL;
            unsigned char isBSS = 0;
            if ((unsigned long)ni == (unsigned long)vap->iv_bss) {
                isBSS = 1;
            }
//			if (txctl->keytype != HAL_KEY_TYPE_WEP)
			if ( (!isBSS) &&
			     (txctl->keytype != HAL_KEY_TYPE_WEP) ) {
				k = &ni->ni_ucastkey;
			} else {
        		//keyid = vap->iv_def_txkey;
        		printk("\t vap->iv_def_txkey=%d \n", vap->iv_def_txkey);
		        k = &vap->iv_nw_keys[vap->iv_def_txkey];
				if (k) {
					printk("\t wk_valid =%d keyidx=%hd k->ic_cipher=%d k->wk_flags=0x%hhx  ni[0]=%p\n",
						k->wk_valid, k->wk_keyix, (k->wk_cipher) ? k->wk_cipher->ic_cipher : IEEE80211_CIPHER_NONE, k->wk_flags, scn->sc_keyixmap[vap->iv_def_txkey]);

					if (k->wk_cipher) {
//						if (k->wk_cipher->ic_cipher != IEEE80211_CIPHER_WEP) {
//							k = NULL;
//						}
					} else
						k = NULL;
				}
			}

			if ((k) && (k->wk_valid)) {
				if (txctl->keyix != k->wk_keyix) {
					printk("%s ???? why txctl->keyix(%d) != k->wk_keyix(%d) ???\n", __func__, txctl->keyix, k->wk_keyix);
					ni->cs_wfo_status = CS_WFO_NI_SW_ONLY;
					return false;
				}
				if ((k->wk_cipher) && (k->wk_cipher->ic_cipher == IEEE80211_CIPHER_WEP)) {
					if (k->wk_keyix >= IEEE80211_WEP_NKID) {
						printk("%s ???? why  k->wk_keyix(%d) >= IEEE80211_WEP_NKID ???\n", __func__, k->wk_keyix, IEEE80211_WEP_NKID);
						ni->cs_wfo_status = CS_WFO_NI_SW_ONLY;
						return false;
					}
				}
				if ( (k->wk_flags & IEEE80211_KEY_SWMIC) ||
					 (k->wk_flags & IEEE80211_KEY_MFP) ||
					 (k->wk_flags & IEEE80211_KEY_SWCRYPT) ) {
					/* for SW MIC , we don't offload to PE*/
					printk("\t (k->wk_flags=0x%x has  IEEE80211_KEY_SWMIC(0x%x) or IEEE80211_KEY_MFP(0x%x) or IEEE80211_KEY_SWCRYPT(0x%x) \
					\n",
						k->wk_flags, IEEE80211_KEY_SWMIC, IEEE80211_KEY_MFP, IEEE80211_KEY_SWCRYPT);
					CS_AR9580_WFO_TX_mac_entry_delete(scn, ni);
					ni->cs_wfo_status = CS_WFO_NI_SW_ONLY;
					return false;
				}

				struct cs_ar9580_wfo_ieee80211_key * pe_key;// = CS_A9580_KEY_CACHE_MEM_PADDR;
#if 0
				pe_key += ar9580_ipc_msg.dest_idx;
				printk("\t pe_key=%p size=%d",pe_key, sizeof(struct cs_ar9580_wfo_ieee80211_key));
				pe_key = phys_to_virt(pe_key);
#endif
				pe_key = &(ni->pe_key);
				ar9580_ipc_msg.key_ptr = virt_to_phys(pe_key);

				printk("\t pe_key virtual=%p  physical=%p\n", pe_key , virt_to_phys(pe_key));
				pe_key->wk_valid = k->wk_valid;
				pe_key->wk_keylen = k->wk_keylen;
				pe_key->wk_flags = k->wk_flags;
				pe_key->wk_keyix = k->wk_keyix;
				pe_key->wk_keyglobal = k->wk_keyglobal;
				pe_key->wk_keytsc = k->wk_keytsc;
				if (k->wk_cipher) {
					pe_key->ic_cipher = k->wk_cipher->ic_cipher;

				} else
					pe_key->ic_cipher = IEEE80211_CIPHER_NONE;

				if ((ar9580_ipc_msg.encrypt_type != HAL_KEY_TYPE_CLEAR) &&
					(pe_key->ic_cipher >= IEEE80211_CIPHER_MAX)) {
					printk("%s invalid key txctl->keytype=%hd (!=0) pe_key->ic_cipher=%d\n",
					ar9580_ipc_msg.encrypt_type, pe_key->ic_cipher);
					return false;
				}

				int i;
				printk("\twk_keylen=%hhd wk_flags=%hhd wk_keyglobal=0x%llx wk_keytsc=0x%llx pe_key->ic_cipher=%d\n",
					k->wk_keylen, k->wk_flags, k->wk_keyix, k->wk_keyglobal, k->wk_keytsc, pe_key->ic_cipher);
				printk("\t");
				for (i = 0; i < WFO_IEEE80211_TID_SIZE; i++) {
					pe_key->wk_keyrsc[i] = k->wk_keyrsc[i];
					printk("wk_keyrsc[%d]=0x%llx ", i, k->wk_keyrsc[i]);
					if ((i % 4) == 3)
						printk("\n\t");
				}
				printk("\n\t");
				for (i = 0; i < WFO_IEEE80211_TID_SIZE; i++) {
					pe_key->wk_keyrsc_suspect[i] = k->wk_keyrsc_suspect[i];
					printk("wk_keyrsc_suspect[%d]=0x%llx ", i, k->wk_keyrsc_suspect[i]);
					if ((i % 4) == 3)
						printk("\n\t");
				}
				printk("\n");
				dma_map_single(NULL, (void *)pe_key, sizeof(struct cs_ar9580_wfo_ieee80211_key), DMA_TO_DEVICE);
			} else {
                if (isBSS) {
                     ar9580_ipc_msg.field_mask |= NI_FIELD_GROUP_KEY;
                     struct cs_ar9580_wfo_ieee80211_key * pe_key_group;
                     pe_key_group = &ni->pe_key;
                     ar9580_ipc_msg.key_ptr = virt_to_phys(pe_key_group);
                     pe_key_group->ic_cipher = IEEE80211_CIPHER_NONE;
                     ar9580_ipc_msg.dest_idx = vap->iv_unit; //vap_idx 0 ..N
                     //pe_key_group->wk_keyix = vap->iv_unit; //vap_idx 0 ..N
                     printk("\t pe_key virtual=%p  physical=%p\n", pe_key_group , virt_to_phys(pe_key_group));
                     printk("\t vap->iv_unit=%d k->wk_keyix=%d\n", vap->iv_unit,k->wk_keyix);
                     dma_map_single(NULL, (void *)pe_key_group, sizeof(struct cs_ar9580_wfo_ieee80211_key), DMA_TO_DEVICE);
                } else {
				return false;
				}
				
			}
			cs_local_sc_keyixmap[ni->pe_key.wk_keyix] = ni;
			printk("\t setup cs_local_sc_keyixmap[ni->pe_key.wk_keyix=%d]=%p (ni=%p) cs_local_sc_keyixmap=%p k->wk_keyix=%hd\n", ni->pe_key.wk_keyix, cs_local_sc_keyixmap[ni->pe_key.wk_keyix], ni, cs_local_sc_keyixmap, k->wk_keyix);

//		printk("\t update frame_type=%d dest_idx=%d encrypt_type=%d \n",
//			ar9580_ipc_msg.frame_type, ar9580_ipc_msg.dest_idx, ar9580_ipc_msg.encrypt_type	);
		//DPRINTF(scn, ATH_DEBUG_TX99, "\t update frame_type=%d dest_idx=%d encrypt_type=%d \n",
		//	ar9580_ipc_msg.frame_type, ar9580_ipc_msg.dest_idx, ar9580_ipc_msg.encrypt_type	);
	}
	if (type & NI_FIELD_NI_INFO) {
		ar9580_ipc_msg.ni_flags = ni->ni_flags;
		memcpy(&ar9580_ipc_msg.ni_bssid[0], ni->ni_bssid, 6);
#if 0
		ar9580_ipc_msg.power = ni->ni_txpower;
		printk("\t update ni_flags=%d ni_bssid=%pM ni_power=%d \n",
			ar9580_ipc_msg.ni_flags, &ar9580_ipc_msg.ni_bssid[0], ar9580_ipc_msg.power);
#endif
		//DPRINTF(scn, ATH_DEBUG_TX99, "\t update ni_flags=%d ni_bssid=%pM ni_power=%d \n",
		//	ar9580_ipc_msg.ni_flags, &ar9580_ipc_msg.ni_bssid[0], ar9580_ipc_msg.power);

	}

	if (type & NI_FIELD_TXPWR) {
		if (ads == NULL)
			return false;
		if (txctl == NULL)
			return false;
		//ar9580_ipc_msg.dest_idx = (ads->ds_ctl12 & AR_dest_idx)  >> AR_dest_idx_S;
		//ar9580_ipc_msg.encrypt_type = (ads->ds_ctl17 & AR_encr_type) >> AR_encr_type_S;
		//ar9580_ipc_msg.frame_type = (ads->ds_ctl12 & AR_frame_type) >> AR_frame_type_S;
		ar9580_ipc_msg.power = (ads->ds_ctl11 & AR_xmit_power0) >> AR_xmit_power0_S;
#if 0
		printk("\t update ni_flags=%d ni_bssid=%pM ni_power=%x \n",
			ar9580_ipc_msg.ni_flags, &ar9580_ipc_msg.ni_bssid[0], ar9580_ipc_msg.power);
#endif
		ar9580_ipc_msg.txctl_flags = txctl->flags;
		ar9580_ipc_msg.pad_delim = (ads->ds_ctl17 & AR_pad_delim ) >> AR_pad_delim_S; /* this could not be real len???*/

		ar9580_ipc_msg.tx_tries = ads->ds_ctl13;
		ar9580_ipc_msg.tx_rates = ads->ds_ctl14;
		ar9580_ipc_msg.rts_cts_0_1 = ads->ds_ctl15;
		ar9580_ipc_msg.rts_cts_2_3 = ads->ds_ctl16;
		ar9580_ipc_msg.chain_sel = ads->ds_ctl18;
		ar9580_ipc_msg.ness_0 = ads->ds_ctl19;
		ar9580_ipc_msg.ness_1 = ads->ds_ctl20;
		ar9580_ipc_msg.ness_2 = ads->ds_ctl21;
		ar9580_ipc_msg.ness_3 = ads->ds_ctl22;
		if (rcs) {
			ar9580_ipc_msg.rc_series_flags[0] = rcs[0].flags;
			ar9580_ipc_msg.rc_series_flags[1] = rcs[1].flags;
			ar9580_ipc_msg.rc_series_flags[2] = rcs[2].flags;
			ar9580_ipc_msg.rc_series_flags[3] = rcs[3].flags;
		}

		ni->cs_wfo_ds_ctl13 = ads->ds_ctl13;
		ni->cs_wfo_ds_ctl14 = ads->ds_ctl14;
		ni->cs_wfo_ds_ctl15 = ads->ds_ctl15;
		ni->cs_wfo_ds_ctl16 = ads->ds_ctl16;
		ni->cs_wfo_ds_ctl18 = ads->ds_ctl18;
		ni->cs_wfo_ds_ctl19 = ads->ds_ctl19;
		ni->cs_wfo_ds_ctl20 = ads->ds_ctl20;
		ni->cs_wfo_ds_ctl21 = ads->ds_ctl21;
		ni->cs_wfo_ds_ctl22 = ads->ds_ctl22;
#if 0
		printk("\t update txctl_flags=%08x pad_delim=%d. rc_series_flags=%x-%x-%x-%x.\n",
			ar9580_ipc_msg.txctl_flags, ar9580_ipc_msg.pad_delim,
			ar9580_ipc_msg.rc_series_flags[0], ar9580_ipc_msg.rc_series_flags[1],
			ar9580_ipc_msg.rc_series_flags[2], ar9580_ipc_msg.rc_series_flags[3]);
		printk("\t dsc ctl13=0x%08x ctl14=0x%08x ctl15=0x%08x ctl16=0x%08x \n\t     ctl18=0x%08x ctl19=0x%08x ctl20=0x%08x ctl21=0x%08x ctl22=0x%08x\n",
			ads->ds_ctl13, ads->ds_ctl14, ads->ds_ctl15, ads->ds_ctl16,
			ads->ds_ctl18, ads->ds_ctl19, ads->ds_ctl20, ads->ds_ctl21, ads->ds_ctl22);
#endif
		//DPRINTF(scn, ATH_DEBUG_TX99,"\t update txctl_flags=%08x pad_delim=%d\n",
		//	ar9580_ipc_msg.txctl_flags,ar9580_ipc_msg.pad_delim);
		//DPRINTF(scn, ATH_DEBUG_TX99,"\t dsc ctl13=0x%08x ctl14=0x%08x ctl15=0x%08x ctl16=0x%08x \n\t     ctl18=0x%08x ctl19=0x%08x ctl20=0x%08x ctl21=0x%08x ctl22=0x%08x\n",
		//	ads->ds_ctl13, ads->ds_ctl14, ads->ds_ctl15, ads->ds_ctl16,
		//	ads->ds_ctl18, ads->ds_ctl19, ads->ds_ctl20, ads->ds_ctl21, ads->ds_ctl22);
	}

    cs_wfo_ipc_wait_send_complete(scn->pid, CS_WFO_IPC_PE_MESSAGE, (u8*)&ar9580_ipc_msg, sizeof(cs_ar9580_wfo_ipc_update_msg_t));
	return true;
}

bool CS_AR9580_WFO_mac_entry_update_key(struct ath_softc_net80211 *scn, struct ieee80211_node *ni)
{
	if (CS_AR9580_WFO_enabled(scn) == 0)
		return false;

	/*
     * need to inform PE for node association by CS_WFO_IPC_MSG_CMD_ADD_LOOKUP_802_11
	 */
	printk("%s ni->ni_ucastkey.wk_keyix=%d ni_bssid=%pM ni_macaddr=%pM ni->ni_flags=0x%x\n",
	 	__func__,	ni->ni_ucastkey.wk_keyix, ni->ni_bssid, ni->ni_macaddr , ni->ni_flags);

	if (CS_AR9580_WFO_TX_mac_entry_update(scn, NI_FIELD_KEY, ni, NULL, NULL, NULL)) {
		ni->cs_wfo_status = CS_WFO_NI_ADD_HASH;
		return true;
	} else
		return false;
}

bool CS_AR9580_WFO_TX_mac_entry_add(struct ath_softc_net80211 *scn, struct ieee80211_node *ni)
{
	if (CS_AR9580_WFO_enabled(scn) == 0)
		return false;

	/*
     * need to inform PE for node association by CS_WFO_IPC_MSG_CMD_ADD_LOOKUP_802_11
	 */
	printk("%s ni->ni_ucastkey.wk_keyix=%d ni_bssid=%pM ni_macaddr=%pM ni->ni_flags=0x%x\n",
	 	__func__,	ni->ni_ucastkey.wk_keyix, ni->ni_bssid, ni->ni_macaddr , ni->ni_flags);

	CS_AR9580_WFO_TX_mac_entry_delete(scn, ni);

	int i;
	for (i = 0; i< IEEE80211_TID_SIZE; i++ ) {
		printk("\t tid[%02d] seq= %d ",i ,  ni->ni_txseqs[i]);
		if ((i % 4) ==3)
			printk("\n");
	}
	printk("\n");
	ni->cs_wfo_ds_ctl13 = ni->cs_wfo_ds_ctl14 = 0;
	ni->cs_wfo_ds_ctl15 = ni->cs_wfo_ds_ctl16 = 0;
	ni->cs_wfo_ds_ctl18 = ni->cs_wfo_ds_ctl19 = 0;
	ni->cs_wfo_ds_ctl20 = ni->cs_wfo_ds_ctl21 = 0;
	ni->cs_wfo_status = CS_WFO_NI_ADD_ENTRY;
	/*
	 */
	wfo_mac_entry_s mac_entry;
	header_802_11 msg;
	memset(&mac_entry, 0, sizeof(mac_entry));
	memset(&msg, 0, sizeof(header_802_11));
	msg.fc.toDs = 0;
	msg.fc.frDs = 1;
	memcpy(&msg.addr1[0], ni->ni_macaddr, 6);

	msg.sequence = ni->ni_txseqs[IEEE80211_NON_QOS_SEQ];

	mac_entry.mac_da = ni->ni_macaddr;
	mac_entry.da_type = WFO_MAC_TYPE_802_11;
	mac_entry.pe_id = scn->pid;
	mac_entry.p802_11_hdr = &msg;
	mac_entry.len = sizeof(header_802_11);
	mac_entry.frame_type = 0x4;

	cs_wfo_set_mac_entry(&mac_entry);

	CS_AR9580_WFO_TX_mac_entry_update(scn, NI_FIELD_NI_INFO, ni, NULL, NULL, NULL);
	ni->cs_wfo_status = CS_WFO_NI_UPDATE_KEY;
	return true;
}

bool CS_AR9580_WFO_TX_add_hash(struct ath_softc_net80211 *scn, int qnum, struct ath_buf *bf
	, ieee80211_tx_control_t *txctl)
{
	struct sk_buff *skb = bf->bf_mpdu;
	int qid = 0;
	struct ar9300_txc *ads = AR9300TXC(bf->bf_desc);
	struct ieee80211_node *ni = wbuf_get_node(skb);

	if (scn->wfo_enabled) {
		if ((ni->cs_wfo_status == CS_WFO_NI_NEW) || (ni->cs_wfo_status == CS_WFO_NI_SW_ONLY))
			return false;
		qid = scn->pni_tx_qid + 7 - qnum;
		cs_kernel_accel_cb_t *cs_cb = CS_KERNEL_SKB_CB(skb);
		if (qnum >= 4) {
			if ((cs_cb != NULL) && (cs_cb->common.tag == CS_CB_TAG))
				printk("%s why xmit packet at qnum(%d) > 4???\n", __func__, qnum);
			return -1;
		}
		struct ieee80211_frame *wh;
	    int type, subtype;
		wh = (struct ieee80211_frame *)wbuf_header(skb);
		type = wh->i_fc[0] & IEEE80211_FC0_TYPE_MASK;

		if (type != IEEE80211_FC0_TYPE_DATA) {
			if (cs_cb != NULL)
				printk("%s why xmit packet at qnum(%d) > 4 and type %d is not data(0x8) ???\n", __func__, qnum, type);
			return -1;
		}

#if 0
		if (cs_cb == NULL)
			return -1;
#endif

		if (ni == NULL) {
			printk("%s why xmit packet with ni == NULL ???\n", __func__);
			return -1;
		}

#if 0
		if ((cs_cb->common.tag != CS_CB_TAG) ||
			(cs_cb->common.sw_only & (CS_SWONLY_DONTCARE |
					  CS_SWONLY_STATE))) {
			/*drop rate change event*/
#if 0
		  if ((0 != ads->ds_ctl13) && (0 != ads->ds_ctl14) &&
		 	(0 != ads->ds_ctl15) && (0 != ads->ds_ctl16) &&
			(0 != ads->ds_ctl18) && (0 != ads->ds_ctl19) &&
			(0 != ads->ds_ctl20) && (0 != ads->ds_ctl21) && (0 != ads->ds_ctl22) ) {

			if ((ni->cs_wfo_ds_ctl14 != ads->ds_ctl14) ||
				(ni->cs_wfo_status == CS_WFO_NI_UPDATE_KEY)) {
				/*Send IPC to update ctl*/
				printk("******* drop rate change \n");
				//DPRINTF(scn, ATH_DEBUG_TX99, "******* rate change \n");

				printk("\t dsc ctl13=0x%08x ctl14=0x%08x ctl15=0x%08x ctl16=0x%08x \n\t     ctl18=0x%08x ctl19=0x%08x ctl20=0x%08x ctl21=0x%08x ctl22=0x%08x\n",
					ads->ds_ctl13, ads->ds_ctl14, ads->ds_ctl15, ads->ds_ctl16,
					ads->ds_ctl18, ads->ds_ctl19, ads->ds_ctl20, ads->ds_ctl21, ads->ds_ctl22);

			}
		  }
#endif
			return -1;
		}
#endif
#if 0 //DEBUG

		printk("\n");
		printk("\t ni=%p ni_flags=%x ni->ni_txpower=%d\n", ni, ni->ni_flags,ni->ni_txpower);
		int i;
		for (i = 0; i< IEEE80211_TID_SIZE; i++ ) {
			printk("\t\t tid[%02d] seq=%d",i ,  ni->ni_txseqs[i]);
			if ((i % 4) ==3)
				printk("\n");
		}
		printk("\n");
		printk("\t txctl ht=%d atype=%d key_ix=%d keytype=%d isqosdata=%d (==1) flags=%d use_minrate=%d\n",
			txctl->ht,  txctl->atype, txctl->keyix, txctl->keytype, txctl->isqosdata, txctl->flags, txctl->use_minrate );
		struct ath_rc_series * rcs;
		rcs = bf->bf_rcs;
		for (i = 0; i< 4 ; i++) {
			printk("\t bf->bf_rcs[%d] rix=%d tries=%d flags=%d max4msframelen=%d \n", i, rcs[i].rix, rcs[i].tries, rcs[i].flags, rcs[i].max4msframelen);
		}


		struct ath_node *an = txctl->an;
		struct ath_atx_tid *ath_tid = ATH_AN_2_TID(an, txctl->tidno);
		printk("\t ath_aggr_query(tid)=%d txctl->tidno=%d\n", ath_aggr_query(ath_tid), txctl->tidno);

		printk("\t dsc ds_info=0x%08x ds_link=0x%08x ds_data0=0x%08x ctl3=0x%08x \n\t 	ds_data1=0x%08x ctl5=0x%08x ds_data2=0x%08x ctl7=0x%08x ds_data3=0x%08x ctl9=0x%08x\n",
					ads->ds_info, ads->ds_link, ads->ds_data0, ads->ds_ctl3,
					ads->ds_data1, ads->ds_ctl5, ads->ds_data2, ads->ds_ctl7, ads->ds_data3, ads->ds_ctl9);
		printk("\t dsc ctl10=0x%08x ctl11=0x%08x ctl12=0x%08x \n",
					ads->ds_ctl10, ads->ds_ctl11, ads->ds_ctl12);


		printk("\t dsc ctl13=0x%08x ctl14=0x%08x ctl15=0x%08x ctl16=0x%08x \n\t     ctl18=0x%08x ctl19=0x%08x ctl20=0x%08x ctl21=0x%08x ctl22=0x%08x\n",
			ads->ds_ctl13, ads->ds_ctl14, ads->ds_ctl15, ads->ds_ctl16,
			ads->ds_ctl18, ads->ds_ctl19, ads->ds_ctl20, ads->ds_ctl21, ads->ds_ctl22);
//#endif


		printk("\t bf->bf_frmlen=%d bf->bf_buf_len=%d \n",bf->bf_frmlen, bf->bf_buf_len[0]	);

		printk("\t %s receive 802.11 packet=%p at lspid=%d, input da %pM sa %pM, output da %pM sa %pM, sw_only=%d ingress_port_id=%d module_mask=0x%x cs_cb->fill_ouput_done=%d tx_qnum=%d voq=%d cs_cb->output_mask=%llx\n",
					__func__, skb, cs_cb->key_misc.orig_lspid, cs_cb->input.raw.da, cs_cb->input.raw.sa, cs_cb->output.raw.da, cs_cb->output.raw.sa,
				cs_cb->common.sw_only, cs_cb->common.ingress_port_id, cs_cb->common.module_mask , cs_cb->fill_ouput_done, qnum, qid, cs_cb->output_mask);
#endif
		/*
		 * check the TXCTL change
		 */
		if ((0 != ads->ds_ctl13) && (0 != ads->ds_ctl14) &&
		 	(0 != ads->ds_ctl15) && (0 != ads->ds_ctl19) ) {

			struct ieee80211vap *vap = ni->ni_vap;
			u8 update_txctl = 0;

			if (ni->cs_wfo_status == CS_WFO_NI_UPDATE_KEY)
				update_txctl = 1;
			else if (((unsigned long)ni == (unsigned long)vap->iv_bss) &&
					  (ni->cs_wfo_ds_ctl14 != ads->ds_ctl14))
				update_txctl = 1;
			else if ((0 != ads->ds_ctl16) && (0 != ads->ds_ctl18) &&
		 			 (0 != ads->ds_ctl20) && (0 != ads->ds_ctl21) && (0 != ads->ds_ctl22) &&
					 (ni->cs_wfo_ds_ctl14 != ads->ds_ctl14))
				update_txctl = 1;

			if (update_txctl == 1) {
				/*Send IPC to update ctl*/
#if 0
				printk("******* rate change \n");
				//DPRINTF(scn, ATH_DEBUG_TX99, "******* rate change \n");

				printk("\t dsc ctl13=0x%08x ctl14=0x%08x ctl15=0x%08x ctl16=0x%08x \n\t     ctl18=0x%08x ctl19=0x%08x ctl20=0x%08x ctl21=0x%08x ctl22=0x%08x\n",
					ads->ds_ctl13, ads->ds_ctl14, ads->ds_ctl15, ads->ds_ctl16,
					ads->ds_ctl18, ads->ds_ctl19, ads->ds_ctl20, ads->ds_ctl21, ads->ds_ctl22);
#endif

				if (CS_AR9580_WFO_TX_mac_entry_update(scn, NI_FIELD_TXPWR | ((ni->cs_wfo_status == CS_WFO_NI_UPDATE_KEY)? NI_FIELD_KEY : 0), ni, ads, txctl, bf? bf->bf_rcs: 0)
					 == false)
					 return 0;
				if (bf) {
					OS_MEMCPY(&ni->ni_rcs, bf->bf_rcs, sizeof(bf->bf_rcs));
				}
				ni->ni_txctl_flags = txctl->flags;
				ni->ni_shortPreamble = txctl->shortPreamble;
				ni->cs_wfo_status = CS_WFO_NI_ADD_HASH;

			}
		}

		if ((cs_cb != NULL) && (ni->cs_wfo_status != CS_WFO_NI_ADD_HASH))
			return 0;
		if (cs_hw_accel_wfo_wifi_tx_voq(CS_WFO_CHIP_AR9580, scn->pid, skb, qid, NULL) == 0) {
			/*create hash successfully*/
		//	cs_wfo_11n_dump_skb(bf->bf_mpdu );

		};
	}
	return 1;
}

bool CS_AR9580_WFO_setup_power_saving(struct ath_softc_net80211 *scn, struct ieee80211_node *ni)

{
	if (CS_AR9580_WFO_enabled(scn) == 0)
		return false;
	if (ni->cs_wfo_status == CS_WFO_NI_SW_ONLY)
		return false;

	/*
	 * need to inform PE for node delete by CS_WFO_IPC_MSG_CMD_DEL_LOOKUP_802_11
	 */

	if (cs_ar9580_power_saving_enable &&
		(ni->cs_wfo_status != CS_WFO_NI_SW_ONLY) &&
		((ni->ni_flags & IEEE80211_NODE_PWR_MGT) ||
		 (ni->ni_flags & IEEE80211_NODE_UAPSD_TRIG))) {
			CS_AR9580_WFO_TX_mac_entry_update(scn, NI_FIELD_NI_INFO, ni, NULL, NULL, NULL);
			ni->cs_wfo_status = CS_WFO_NI_SW_ONLY;
			cs_wfo_del_hash_by_mac_da(ni->ni_macaddr);
            printk("%s:: %pM ni_flags = %x. cs_wfo_status = %d.\n", __func__, ni->ni_macaddr, ni->ni_flags, ni->cs_wfo_status);
			printk("***** WFO disable OFFLOAD mode *******\n");
    }

    return true;

}


bool CS_AR9580_WFO_TX_80211n(struct ath_softc_net80211 *scn, int qnum, void * txs, struct ath_buf *bf)
{
	struct ath_softc *sc = scn->sc_dev;
	//struct ath_buf *bf;
	int qid = 0;
	uint32_t paddr = 0;
	uint32_t len = 0;
	struct sk_buff *skb;

#if 1
	struct ath_txq *txq;
	struct ath_buf *orig_bf;
	uint16_t idex = 0;
	txq = &sc->sc_txq[qnum];
	if (txq->axq_headindex == 0)
		idex = HAL_TXFIFO_DEPTH - 1;
	else
		idex = txq->axq_headindex - 1;

	if (qnum != sc->sc_bhalq) {
		orig_bf = TAILQ_FIRST(&txq->axq_fifo[idex]);
		struct ar9300_txc *ads = AR9300TXC(orig_bf->bf_desc);
		while ((orig_bf) && (ads) && (orig_bf->bf_mpdu)) {
			uint16_t txq_index = (ads->ds_info & AR_tx_qcu_num) >> AR_tx_qcu_num_S;
			struct ieee80211_frame *verify_wh = (struct ieee80211_frame *)
				wbuf_header(orig_bf->bf_mpdu);
			if ((txq_index >= 0) && (txq_index <=3))
				if ((verify_wh->i_fc[0] & IEEE80211_FC0_TYPE_MASK) == IEEE80211_FC0_TYPE_DATA) {
					adf_nbuf_t nbf = orig_bf->bf_mpdu;
					if (nbf->head_pa == 0) {
						dma_map_single(sc->sc_osdev->bdev, (void *)nbf->data, sizeof(struct ieee80211_frame), DMA_FROM_DEVICE);
					}
					if (orig_bf->bf_retries != 0) {
						//ads->ds_pad[0] = orig_bf->bf_seqno;
						ads->ds_pad[0] = 0x123;
#if 0
						printk("%s get i_fc[1]=%x frame orig_bf->bf_retries=%d orig_bf->bf_seqno=%x\n",
								__func__, verify_wh->i_fc[1], orig_bf->bf_retries, orig_bf->bf_seqno);
						int k;
						char * temp = verify_wh;
						for (k =0; k < 32; k++) {
									printk("%02X ", temp[k]);
						}
						printk("\n");
#endif
						//dma_map_single(sc->sc_osdev->bdev, (void *)ads, sizeof(struct ar9300_txc), DMA_TO_DEVICE);

					}
				}
				orig_bf = orig_bf->bf_next;
				if (orig_bf)
					ads = AR9300TXC(orig_bf->bf_desc);

		}
	}



#if 0
	if (qnum >= HAL_NUM_TX_QUEUES)
		printk("%s qnum(%d)  > HAL_NUM_TX_QUEUES(%d) \n", qnum, HAL_NUM_TX_QUEUES);
	if (txq->axq_headindex >= HAL_TXFIFO_DEPTH)
		printk("%s txq->axq_headindex (%d)  > HAL_TXFIFO_DEPTH(%d) \n", txq->axq_headindex, HAL_TXFIFO_DEPTH);
	if ((qnum == HAL_NUM_TX_QUEUES -1) && (txq->axq_headindex != 0))
			printk("%s qnum(%d)  txq->axq_headindex(%d) is not 0\n", qnum, txq->axq_headindex);
#endif

	uint32_t * pcie_mem = CS_A9580_A9_PCIE_PADDR;
	uint32_t * fifo_location = pcie_mem + qnum * HAL_TXFIFO_DEPTH + idex;
	*fifo_location = txs;
#else
	if (qnum == sc->sc_bhalq)
		qid = scn->pni_tx_qid;
	else
	    qid = scn->pni_tx_qid + 1;

	cs_pni_xmit_ar988x(scn->pid, qid, txs, sc->sc_txdesclen, paddr, len, bf);
#endif

	return true;
}

u8 CS_AR9580_WFO_TX_80211n_Done(struct ath_softc_net80211 *scn, struct ath_buf *bf)
{
	return 0;
}

u8 CS_AR9580_WFO_PNI_init(struct ath_softc_net80211 *scn, u32 phy_addr_start, u32 phy_addr_end)
{
	//int pid = cs_pni_get_free_pid();
	int pid = CS_WFO_IPC_PE1_CPU_ID;
	scn->wfo_enabled = 0;

	if (pid == -1) {
		printk("%s no available PE \n", __func__ );
		return 0;
	}
	/*
	 * PE#1 will handle TX and RX
	 */
	scn->pni_tx_qid = ENCAPSULATION_VOQ_BASE;
	scn->pid = pid;

	scn->wfo_enabled = cs_pni_register_chip_callback_xmit(CS_WFO_CHIP_AR9580, pid - CS_WFO_IPC_PE0_CPU_ID,
		scn, &CS_AR9580_HandleRxFrameFromPNI_80211,	&CS_AR9580_HandleRxFrameFromPNI_8023,
		&CS_AR9580_WFO_TX_80211n_Done);

	printk("%s::pni_tx_qid %d\n", __func__, scn->pni_tx_qid);
	if (scn->wfo_enabled) {
		u32 pcie_phy_addr_start[6], pcie_phy_addr_end[6];
		memset(pcie_phy_addr_start, 0, sizeof(pcie_phy_addr_start));
		memset(pcie_phy_addr_end, 0, sizeof(pcie_phy_addr_end));
		pcie_phy_addr_start[0] =  phy_addr_start/*dev->mem_start*/;
		pcie_phy_addr_end[0] = phy_addr_end/*dev->mem_end*/;
		scn->phy_addr_start = phy_addr_start;
		scn->phy_addr_end = phy_addr_end;
		printk("%s phy_addr start=%x end=%x\n", __func__, pcie_phy_addr_start[0], pcie_phy_addr_end[0]);

		cs_wfo_ipc_send_pcie_phy_addr(pid, 0x01, pcie_phy_addr_start, pcie_phy_addr_end);
	}
	printk("%s done scn->wfo_enabled=%d \n", __func__, scn->wfo_enabled);
	if (scn->wfo_enabled == 1) {
		CS_AR9580_proc_init_module();
	}
	memset(cs_local_sc_keyixmap, 0, sizeof(cs_local_sc_keyixmap));
	//scn->wfo_enabled = 0;

	return scn->wfo_enabled;
}

u8 CS_AR9580_WFO_PNI_exit(struct ath_softc_net80211 *scn)
{

	printk("%s::pni_tx_qid %d\n", __func__, scn->pni_tx_qid);

	scn->wfo_enabled = cs_pni_unregister_callback(&scn->pni_tx_qid, scn);
	scn->pni_tx_qid = 0;
	CS_AR9580_proc_exit_module();

	return scn->wfo_enabled;

}

#define WFO_RC_FRAMELEN 512
#define    IS_CHAN_2GHZ(_c)    (((_c)->channel_flags & CHANNEL_2GHZ) != 0)

void CS_AR9580_WFO_ath_buf_set_rate(struct ath_softc *sc, struct ieee80211_node *ni, struct ath_node *an, struct ath_rc_series *rcs, void *ads, void *lastds)
{
    struct ath_hal       *ah = sc->sc_ah;
    const HAL_RATE_TABLE *rt;
    void                 *ds = ads;
    HAL_11N_RATE_SERIES  series[4];
    int                  i, flags, rtsctsena = 0, dynamic_mimops = 0;
    u_int8_t             rix = 0, cix, ctsrate = 0;
    u_int                ctsduration = 0;
    u_int32_t            aggr_limit_with_rts = sc->sc_rtsaggrlimit;
    u_int                txpower;
#if ATH_SUPPORT_IQUE && ATH_SUPPORT_IQUE_EXT
    u_int               retry_duration = 0;
#endif

    u_int32_t smartantenna = 0;
    bool duration_update_en = 1;
    /*
     * get the cix for the lowest valid rix.
     */
    rt = sc->sc_currates;

    for (i = 4; i--;) {
        if (rcs[i].tries) {
            rix = rcs[i].rix;
            break;
        }
    }

    flags = (ni->ni_txctl_flags & (HAL_TXDESC_RTSENA | HAL_TXDESC_CTSENA));
    cix = rt->info[rix].controlRate;


    if (flags & (HAL_TXDESC_RTSENA | HAL_TXDESC_CTSENA)) {
        rtsctsena = 1;
    }
    /*
     * If 802.11g protection is enabled, determine whether
     * to use RTS/CTS or just CTS.  Note that this is only
     * done for OFDM/HT unicast frames.
     */
    else if (sc->sc_protmode != PROT_M_NONE &&
            (rt->info[rix].phy == IEEE80211_T_OFDM ||
             rt->info[rix].phy == IEEE80211_T_HT) &&
            (ni->ni_txctl_flags & HAL_TXDESC_NOACK) == 0)
    {
        if (sc->sc_protmode == PROT_M_RTSCTS)
            flags = HAL_TXDESC_RTSENA;
        else if (sc->sc_protmode == PROT_M_CTSONLY)
            flags = HAL_TXDESC_CTSENA;

        cix = rt->info[sc->sc_protrix].controlRate;
        sc->sc_stats.ast_tx_protect++;
        rtsctsena = 1;
    }

    /* For 11n, the default behavior is to enable RTS for
     * hw retried frames. We enable the global flag here and
     * let rate series flags determine which rates will actually
     * use RTS.
     */
    if (sc->sc_hashtsupport) {
        KASSERT(an != NULL, ("an == null"));
        /*
         * 802.11g protection not needed, use our default behavior
         */
        if (!rtsctsena)
            flags = HAL_TXDESC_RTSENA;
        /*
         * For dynamic MIMO PS, RTS needs to precede the first aggregate
         * and the second aggregate should have any protection at all.
         */
        if (an->an_smmode == ATH_SM_PWRSAV_DYNAMIC) {
            if (1) {
                flags = HAL_TXDESC_RTSENA;
                dynamic_mimops = 1;
            } else {
                flags = 0;
            }
        }
    }

    /*
     * Set protection if aggregate protection on
     */
    if (sc->sc_config.ath_aggr_prot)
    {
        flags = HAL_TXDESC_RTSENA;
        cix = rt->info[sc->sc_protrix].controlRate;
        rtsctsena = 1;
    }

    /*
     * CTS transmit rate is derived from the transmit rate
     * by looking in the h/w rate table.  We must also factor
     * in whether or not a short preamble is to be used.
     */
    /* NB: cix is set above where RTS/CTS is enabled */
    KASSERT(cix != 0xff, ("cix not setup"));
    ctsrate = rt->info[cix].rate_code |
        (ni->ni_shortPreamble ? rt->info[cix].shortPreamble : 0);
    /*
     * Setup HAL rate series
     */
#if !ATH_TX_COMPACT
    OS_MEMZERO(series, sizeof(HAL_11N_RATE_SERIES) * 4);
#endif
    txpower = IS_CHAN_2GHZ(&sc->sc_curchan) ?
        sc->sc_config.txpowlimit2G :
        sc->sc_config.txpowlimit5G;

    for (i = 0; i < 4; i++) {
        int max_tx_numchains;

        if (!rcs[i].tries) {
            series[i].Tries = 0;
            continue;
        }

        rix = rcs[i].rix;
        series[i].rate_index = rix;

            series[i].tx_power_cap = txpower;

        series[i].Rate = rt->info[rix].rate_code |
            			 (ni->ni_shortPreamble ? rt->info[rix].shortPreamble : 0);

	        series[i].Tries = rcs[i].tries;

        series[i].RateFlags = (
                (rcs[i].flags & ATH_RC_RTSCTS_FLAG) ? HAL_RATESERIES_RTS_CTS : 0) |
            ((rcs[i].flags & ATH_RC_CW40_FLAG) ? HAL_RATESERIES_2040 : 0)     |
            ((rcs[i].flags & ATH_RC_SGI_FLAG) ? HAL_RATESERIES_HALFGI : 0)    |
            ((rcs[i].flags & ATH_RC_TX_STBC_FLAG) ? HAL_RATESERIES_STBC: 0);
#if ATH_SUPPORT_IQUE && ATH_SUPPORT_IQUE_EXT
        retry_duration += series[i].PktDuration * series[i].Tries;
#endif

            /*
             * Check whether fewer than the full number of chains should
             * be used, e.g. due to the dynamic tx chainmask feature's
             * limitation that the number of chains should not exceed the
             * number of 64-QAM MIMO streams, or the CDD feature's limitation
             * to a single chain on legacy channels.
             */
            max_tx_numchains = ath_rate_max_tx_chains(sc, rix, rcs[i].flags);
            if (sc->sc_tx_numchains > max_tx_numchains) {
                static uint8_t tx_reduced_chainmasks[] = {
                    0x0 /* n/a  never have 0 chains */,
                    0x1 /* single chain (0) for single stream */,
                    0x5 /* 2 chains (0+2) for 2 streams */,
                };
                ASSERT(max_tx_numchains > 0);
                ASSERT(max_tx_numchains < ARRAY_LEN(tx_reduced_chainmasks));
                series[i].ch_sel = ath_txchainmask_reduction(sc,
                        tx_reduced_chainmasks[max_tx_numchains], series[i].Rate);
            } else {
                if ((an->an_smmode == ATH_SM_PWRSAV_STATIC) &&
                    ((rcs[i].flags & (ATH_RC_DS_FLAG | ATH_RC_TS_FLAG)) == 0))
                {
                    /*
                    * When sending to an HT node that has enabled static
                    * SM/MIMO power save, send at single stream rates but use
                    * maximum allowed transmit chains per user, hardware,
                    * regulatory, or country limits for better range.
                    */
                    series[i].ch_sel = ath_txchainmask_reduction(sc, sc->sc_tx_chainmask,
                        series[i].Rate);
                } else {
#ifdef ATH_CHAINMASK_SELECT
                    if (bf->bf_ht)
                        series[i].ch_sel = ath_txchainmask_reduction(sc,
                                ath_chainmask_sel_logic(sc, an), series[i].Rate);
                    else
                        series[i].ch_sel = ath_txchainmask_reduction(sc,
                                sc->sc_tx_chainmask, series[i].Rate);
#else
#if ATH_SUPPORT_MCI
                if (sc->sc_hasbtcoex && sc->sc_btinfo.mciSharedConcurTx) {
                    series[i].ch_sel = ath_bt_coex_mci_tx_chainmask(sc, sc->sc_tx_chainmask,
                                                                series[i].Rate);
                }
                else {
                    series[i].ch_sel = ath_txchainmask_reduction(sc, sc->sc_tx_chainmask,
                                                                series[i].Rate);
                }
#else
                series[i].ch_sel = ath_txchainmask_reduction(sc, sc->sc_tx_chainmask,
                        series[i].Rate);
#endif
#endif
                }
            }

        if (rtsctsena)
            series[i].RateFlags |= HAL_RATESERIES_RTS_CTS;

        /*
         * Set RTS for all rates if node is in dynamic powersave
         * mode and we are using dual stream rates.
         */
        if (dynamic_mimops && 
                (rcs[i].flags & (ATH_RC_DS_FLAG | ATH_RC_TS_FLAG))) 
        {
            series[i].RateFlags |= HAL_RATESERIES_RTS_CTS;
        }
    }

    /*
     * For non-HT devices, calculate RTS/CTS duration in software
     * and disable multi-rate retry.
     */
    if (flags && !sc->sc_hashtsupport) {
        /*
         * Compute the transmit duration based on the frame
         * size and the size of an ACK frame.  We call into the
         * HAL to do the computation since it depends on the
         * characteristics of the actual PHY being used.
         *
         * NB: CTS is assumed the same size as an ACK so we can
         *     use the precalculated ACK durations.
         */
        if (flags & HAL_TXDESC_RTSENA) {    /* SIFS + CTS */
            ctsduration += ni->ni_shortPreamble?
                rt->info[cix].spAckDuration : rt->info[cix].lpAckDuration;
        }
        ctsduration += series[0].PktDuration;
        if ((ni->ni_txctl_flags & HAL_TXDESC_NOACK) == 0) {  /* SIFS + ACK */
            ctsduration += ni->ni_shortPreamble ?
                rt->info[rix].spAckDuration : rt->info[rix].lpAckDuration;
        }
        /*
         * Disable multi-rate retry when using RTS/CTS by clearing
         * series 1, 2 and 3.
         */
        OS_MEMZERO(&series[1], sizeof(HAL_11N_RATE_SERIES) * 3);
    }

    if(ni->ni_txctl_flags& HAL_TXDESC_ENABLE_DURATION){
        duration_update_en = 0;
    }

    /*
     * set dur_update_en for l-sig computation except for PS-Poll frames
     */
    ath_hal_set11n_ratescenario(ah, ds, lastds,
                                duration_update_en,
                                ctsrate,
                                ctsduration,
                                series, 4, flags, smartantenna);
    
    if (sc->sc_config.ath_aggr_prot && flags)
        ath_hal_set11n_burstduration(ah, ds, sc->sc_config.ath_aggr_prot_duration);
}

int CS_AR9580_WFO_rc_update_rate(struct ieee80211_node *ni)
{
	struct ath_rc_series tx_rcs[4];
	struct ath_node *an;
	int isProbe = 0;
	struct ath_rc_series *rcs;
	struct ar9300_txc ads, lastds;
	ieee80211_tx_control_t txctl;
	rcs = tx_rcs;
	OS_MEMZERO(rcs, sizeof(struct ath_rc_series) * 4);
	an = (ATH_NODE_NET80211(ni))->an_sta;
	struct ieee80211vap *vap = ni->ni_vap;
	struct ath_softc_net80211 *scn = vap->iv_ic;
	struct ath_softc *sc = scn->sc_dev;
	const HAL_RATE_TABLE    *rt = sc->sc_currates;
	struct ath_hal *ah = sc->sc_ah;
	struct atheros_node   *asn = ATH_NODE_ATHEROS(an);
	TX_RATE_CTRL          *pRc = (TX_RATE_CTRL *)(asn);

	if (pRc->probeRate)
		return;
	/*refer to __ath_tx_prepare to get rate*/
	ath_rate_findrate(sc, an, ni->ni_shortPreamble , WFO_RC_FRAMELEN ,
								  ATH_11N_TXMAXTRY, ATH_RC_PROBE_ALLOWED,
								  TID_TO_WME_AC(0),
								  rcs, &isProbe, AH_FALSE, ni->ni_txctl_flags, NULL);
	/* Ratecontrol sometimes returns invalid rate index */
	if (rcs[0].rix != 0xff) {
		an->an_prevdatarix = rcs[0].rix;
		sc->sc_lastdatarix = rcs[0].rix;
		sc->sc_lastrixflags = rcs[0].flags;
	} else {
		rcs[0].rix = an->an_prevdatarix;
	}

	OS_MEMCPY(&ni->ni_rcs, rcs, sizeof(struct ath_rc_series) * 4);

	/*use ar9300_set_11n_rate_scenario to fill ads */
	OS_MEMZERO(&ads, sizeof(struct ar9300_txc));
	CS_AR9580_WFO_ath_buf_set_rate(sc, ni, an, rcs, &ads, &lastds);
	txctl.flags = ni->ni_txctl_flags;

	if ((0 != ads.ds_ctl13) && (0 != ads.ds_ctl14) &&
		(0 != ads.ds_ctl15) && (0 != ads.ds_ctl19) &&
		(0 != ads.ds_ctl16) && (0 != ads.ds_ctl18) &&
		(0 != ads.ds_ctl20) && (0 != ads.ds_ctl21) && (0 != ads.ds_ctl22) &&
		((ni->cs_wfo_ds_ctl14 != ads.ds_ctl14) || (ni->cs_wfo_ds_ctl18 != ads.ds_ctl18))) {

		if (CS_AR9580_WFO_TX_mac_entry_update(scn, NI_FIELD_TXPWR, ni, &ads, &txctl, rcs)
						 == true) {
			ni->ni_shortPreamble = txctl.shortPreamble;
			ni->ni_txctl_flags = txctl.flags;
		}
	}
	return 0;
}


int CS_AR9580_WFO_rc_report_rate(struct ath_softc *sc ,struct ath_tx_status * ts,
	struct ath_txq *txq)
{
	struct ieee80211_node *ni;
	struct ath_node *an;
	struct ieee80211vap *vap;
	const HAL_RATE_TABLE    *rt = sc->sc_currates;
	int nFrames = 0;
	int nbad = 0;
	struct ath_rc_pp        bf_pp_rcs;
	uint16_t keyix = ts->ni_keyidx;
	uint16_t ac_no= ts->queue_id;
	uint16_t prevRateCode;
	struct ath_softc_net80211 *scn = ATH_SOFTC_NET80211(sc->sc_ieee);
	struct atheros_node   *asn = NULL;
	TX_RATE_CTRL          *pRc = NULL;

	ni = (keyix != HAL_RXKEYIX_INVALID) ? cs_local_sc_keyixmap[keyix] : NULL;

	if (ni == NULL) {
		printk("%s:: can't find ni(%d)\n", __func__, keyix);
		return 0;
	}

	an = (ATH_NODE_NET80211(ni))->an_sta;
	vap = ni->ni_vap;
	scn = vap->iv_ic;

	asn = ATH_NODE_ATHEROS(an);
	pRc = (TX_RATE_CTRL *)(asn);

	nFrames = (ts->ba_low & 0xffff0000) >> 16;
	nbad = (ts->ba_low & 0x0000ffff);
	prevRateCode = pRc->rateMaxPhy;

	bf_pp_rcs.rate = 0;
	bf_pp_rcs.tries = 0;
#if ATH_SUPPORT_VOWEXT
	uint8_t n_tail_fail = (nbad & 0xFF);
	uint8_t n_head_fail = ((nbad >> 8) & 0xFF);
	nbad = ((nbad >> 16) & 0xFF);
#endif

#if 0
	printk("	ni[%02x:%02x:%02x:%02x:%02x:%02x]. nFrames = %d. nbad = %d. txs = %08x.\n", ni->ni_macaddr[0], ni->ni_macaddr[1], ni->ni_macaddr[2],
		ni->ni_macaddr[3], ni->ni_macaddr[4], ni->ni_macaddr[5], nFrames, nbad, ts->ts_status);

	if (0)
	{
		uint16_t i;
		for (i=0; i<4; i++)
		{
			printk("rcs[%d]:: rix = 0x%x. tries = 0x%x. flags = 0x%x. max4msframelen = %d.\n", 
				i, ni->ni_rcs[i].rix, ni->ni_rcs[i].tries, ni->ni_rcs[i].flags, ni->ni_rcs[i].max4msframelen);
			printk("rt[%d]:: phy = %d. rate_code = 0x%x. rateKbps = %d.\n", 
				i, rt->info[ni->ni_rcs[i].rix].phy, rt->info[ni->ni_rcs[i].rix].rate_code, rt->info[ni->ni_rcs[i].rix].rateKbps);
		}
	}
#endif

#ifdef ATH_SUPPORT_VOWEXT

	ath_rate_tx_complete_11n(sc,
		an,
		ts,
		&ni->ni_rcs,
		ac_no /*TID_TO_WME_AC(bf->bf_tidno)*/,
		nFrames
		nbad, n_head_fail, n_tail_fail,
		ath_tx_get_rts_retrylimit(sc, txq),
		&bf_pp_rcs);
#else
	ath_rate_tx_complete_11n(sc,
		an,
		ts,
		&ni->ni_rcs,
		ac_no /*TID_TO_WME_AC(bf->bf_tidno)*/,
		nFrames,
		nbad,
		ath_tx_get_rts_retrylimit(sc, txq),
		&bf_pp_rcs);
#endif
	if (prevRateCode != pRc->rateMaxPhy) {
		//printk("	%s:: rate change %d -> %d.\n", __func__, prevRateCode, pRc->rateMaxPhy);
		CS_AR9580_WFO_rc_update_rate(ni);
	}
	an->an_txratecode = ts->ts_ratecode;
	return 0;
}




EXPORT_SYMBOL(CS_AR9580_WFO_ath_buf_set_rate);
EXPORT_SYMBOL(CS_AR9580_WFO_rc_report_rate);
EXPORT_SYMBOL(CS_AR9580_WFO_rc_update_rate);



EXPORT_SYMBOL(CS_AR9580_WFO_PNI_init);
EXPORT_SYMBOL(CS_AR9580_WFO_PNI_exit);
EXPORT_SYMBOL(CS_AR9580_WFO_enabled);
EXPORT_SYMBOL(CS_AR9580_WFO_TX_80211n);
EXPORT_SYMBOL(CS_AR9580_WFO_TX_mac_entry_add);
EXPORT_SYMBOL(CS_AR9580_WFO_TX_mac_entry_delete);
EXPORT_SYMBOL(CS_AR9580_WFO_TX_mac_entry_update);
EXPORT_SYMBOL(CS_AR9580_WFO_setup_power_saving);

