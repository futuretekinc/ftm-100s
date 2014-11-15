#include <osdep.h>
//++BUG#39672: 1. Separate STA in same SSID
#include <linux/proc_fs.h>
//#include <mach/cs75xx_pni.h>
//#include <mach/cs75xx_ipc_wfo.h>
//#include <cs_core_logic.h>
//--BUG#39672

//++BUG#39672: 2. QoS
#include <mach/cs75xx_qos.h>
//--BUG#39672

#include "adf_nbuf_pvt.h"
#include "ath_pci.h"
#include "hif_msg_based.h"
#include "ol_if_athvar.h"  //for struct ol_ath_softc_net80211
#include "osif_private.h"
#include "athdefs.h"
#include "htc.h"
#include "ol_txrx_api.h"
#include "ol_txrx_htt_api.h"

#include "../../include/htt.h"
#include "cs_atheros_11ac_wfo.h"
#include "copy_engine_api.h"
#include "copy_engine_internal.h"

#define ETH_P_EAPOL	    0x888E      //BUG#39672: 2. QoS

#define FRAG_DESC_SIZE	8
typedef struct local_htt_desc {
	u32	htc_frame_hdr1;
	u32 htc_frame_hdr2;
	u32	msdu_desc1;
	u16	msdu_len : 16;
	u16	msdu_id  : 16;
	u32 frag_desc_ptr;
	u32 reserved;
	u32 frag_addr;
	u32 frag_len;
} __attribute__((packed)) local_htt_desc_s;


extern void osif_pltfrm_deliver_data_ol(os_if_t osif, struct sk_buff *skb_list);
extern A_STATUS HTCRxCompletionHandler(void *Context, adf_nbuf_t netbuf, a_uint8_t pipeID);
extern void CE_wfo_recv_msg(struct ath_hif_pci_softc *sc, unsigned int CE_id, void * skb);

extern int cs_hw_accel_wfo_wifi_tx_voq(int wifi_chip, int pe_id, struct sk_buff *skb,
        u8 tx_qid, wfo_mac_entry_s * mac_entry);
extern int cs_pni_unregister_callback(u8 *tx_base, void* adapter);
extern int cs_pni_get_free_pid();

extern int cs_hw_accel_wfo_wifi_rx(int wifi_chip, int pe_id, struct sk_buff *skb);
//extern int ol_rx_monitor_deliver(ol_txrx_pdev_handle pdev, adf_nbuf_t head_msdu, u_int32_t no_clone_reqd);
extern void cs_ol_tx_completion_handler(ol_txrx_pdev_handle pdev, u_int16_t msdu_id, enum htt_tx_status status);
extern int cs_pni_register_chip_callback_xmit(u8 chip_type, int instance,
	void* adapter, u16 (*cb) , u16 (*cb_8023) , u16 (*cb_xmit_done));
extern void cs_pni_xmit_ar988x(u8 pe_id, u8 voq, u32 buf0, int len0, u32 buf1, int len1, struct sk_buff *skb);

//++BUG#39672: 1. Separate STA in same SSID
/*
 * proc tools 
 */
struct ath_hif_pci_softc *vsc = NULL;

u8   cs_wfo_qca_11ac_sta2sta_enabled = WFO_AR988X_SAME_SSID_STA2STA_ENABLE;
u8   cs_wfo_qca_11ac_multi_bssid_enabled = WFO_AR988X_MULTI_BSSID_ENABLE;   //BUG#40246: PE0 usage is high for downlink

/* file name */
#define WFO_QCA_11AC_STA2STA_ENABLE     "wfo_qca_11ac_sta2sta"
#define WFO_QCA_11AC_MULTI_BSSID_ENABLE "wfo_qca_11ac_multi_bssid"          //BUG#40246: PE0 usage is high for downlink

/* help message */
#define CS_AR988X_WFO_QCA_11AC_STA2STA_MSG  "Purpose: Wi-Fi Offload QCA 11AC Separate STA in same SSID\n" \
			"READ Usage: cat %s\n" \
			"WRITE Usage: echo [value] > %s\n" \
			"value 0: Disable WFO QCA 11AC STA to STA traffic in same SSID\n" \
			"value 1: Enable WFO QCA 11AC STA to STA traffic in same SSID\n"
//++BUG#40246: PE0 usage is high for downlink
#define CS_AR988X_WFO_QCA_11AC_MULTI_BSSID_MSG  "Purpose: Wi-Fi Offload QCA 11AC multiple bssid support\n" \
			"READ Usage: cat %s\n" \
			"WRITE Usage: echo [value] > %s\n" \
			"value 0: Disable WFO QCA 11AC multiple bssid\n" \
			"value 1: Enable WFO QCA 11AC multiple bssid\n"
//--BUG#40246

/* entry pointer */
extern struct proc_dir_entry *proc_driver_cs752x_wfo;
extern int cs752x_add_proc_handler(char *name,
			    read_proc_t * hook_func_read,
			    write_proc_t * hook_func_write,
			    struct proc_dir_entry *parent);
extern int cs_wfo_ipc_wait_send_complete(u8 pe_id, u8 msg_type, u8 *pmsg, u8 payload_size);


cs_wfo_ar988x_wmm_status_e cs_wfo_ar988x_separate_sta2sta(cs_dev_id_t device_id, u8 sta2sta_mode)
{
	cs_ar988X_wfo_ipc_cmd_sta2sta_t ar988X_ipc_msg;
    
    if (!vsc) {
        return CS_ERR_WFO_AR988X_WMM_INIT_FAIL;
    }
        
	if (vsc->wfo_enabled) {
        printk("%s:%d:: IPC sta2sta_mode %d\n", __func__, __LINE__, sta2sta_mode);
    	memset(&ar988X_ipc_msg, 0, sizeof(cs_ar988X_wfo_ipc_cmd_sta2sta_t));
    	ar988X_ipc_msg.ipc_msg_hdr.pe_id = vsc->pid;
        ar988X_ipc_msg.ipc_msg_hdr.hdr.pe_msg.wfo_cmd = CS_WFO_IPC_MSG_CMD_AR988X_STA2STA;
        ar988X_ipc_msg.mode = sta2sta_mode;
    
    	cs_wfo_ipc_wait_send_complete(vsc->pid, CS_WFO_IPC_PE_MESSAGE, &ar988X_ipc_msg, sizeof(cs_ar988X_wfo_ipc_cmd_sta2sta_t));
    }
    
    return CS_OK;
}/* cs_wfo_ar988x_separate_sta2sta */
EXPORT_SYMBOL(cs_wfo_ar988x_separate_sta2sta);

//++BUG#40246: PE0 usage is high for downlink
cs_wfo_ar988x_wmm_status_e cs_wfo_ar988x_multi_bssid(cs_dev_id_t device_id, u8 multi_bssid_mode)
{
	cs_ar988X_wfo_ipc_cmd_multi_bssid_t ar988X_ipc_msg;
    
    if (!vsc) {
        return CS_ERR_WFO_AR988X_WMM_INIT_FAIL;
    }
        
	if (vsc->wfo_enabled) {
        printk("%s:%d:: IPC multi_bssid_mode %d\n", __func__, __LINE__, multi_bssid_mode);
    	memset(&ar988X_ipc_msg, 0, sizeof(cs_ar988X_wfo_ipc_cmd_multi_bssid_t));
    	ar988X_ipc_msg.ipc_msg_hdr.pe_id = vsc->pid;
        ar988X_ipc_msg.ipc_msg_hdr.hdr.pe_msg.wfo_cmd = CS_WFO_IPC_MSG_CMD_AR988X_MULTI_BSSID;
        ar988X_ipc_msg.mode = multi_bssid_mode;
    
    	cs_wfo_ipc_wait_send_complete(vsc->pid, CS_WFO_IPC_PE_MESSAGE, &ar988X_ipc_msg, sizeof(cs_ar988X_wfo_ipc_cmd_multi_bssid_t));
    }
    
    return CS_OK;
}/* cs_wfo_ar988x_multi_bssid */
EXPORT_SYMBOL(cs_wfo_ar988x_multi_bssid);
//--BUG#40246

/*
 * Separate STA in same SSID
 */
static int CS_AR988X_proc_sta2sta_read_proc(char *buf, char **start, off_t offset,
				   int count, int *eof, void *data)
{
	u32 len = 0;

	len += sprintf(buf + len, CS_AR988X_WFO_QCA_11AC_STA2STA_MSG, WFO_QCA_11AC_STA2STA_ENABLE, WFO_QCA_11AC_STA2STA_ENABLE);
	len += sprintf(buf + len, "\n%s = 0x%08x\n", WFO_QCA_11AC_STA2STA_ENABLE,
			cs_wfo_qca_11ac_sta2sta_enabled);
	*eof = 1;

	return len;
}/* CS_AR988X_proc_sta2sta_read_proc() */

static int CS_AR988X_proc_sta2sta_write_proc(struct file *file, const char *buffer,
				    unsigned long count, void *data)
{
	char buf[32];
	unsigned long mask;
	ssize_t len;

	len = min(count, (unsigned long)(sizeof(buf) - 1));
	if (copy_from_user(buf, buffer, len))
		goto QCA_11AC_STA2STA_INVAL_EXIT;

	buf[len] = '\0';
	if (strict_strtoul(buf, 0, &mask))
		goto QCA_11AC_STA2STA_INVAL_EXIT;

	if (mask > WFO_AR988X_SAME_SSID_STA2STA_ENABLE)
		goto QCA_11AC_STA2STA_INVAL_EXIT;

	cs_wfo_qca_11ac_sta2sta_enabled = mask;

    cs_wfo_ar988x_separate_sta2sta(0, cs_wfo_qca_11ac_sta2sta_enabled);

	printk(KERN_WARNING "Set %s as 0x%08x\n", WFO_QCA_11AC_STA2STA_ENABLE, cs_wfo_qca_11ac_sta2sta_enabled);

	return count;

QCA_11AC_STA2STA_INVAL_EXIT:
	printk(KERN_WARNING "Invalid argument\n");
	printk(KERN_WARNING CS_AR988X_WFO_QCA_11AC_STA2STA_MSG, WFO_QCA_11AC_STA2STA_ENABLE, WFO_QCA_11AC_STA2STA_ENABLE);
	/* if we return error code here, PROC fs may retry up to 3 times. */
	return count;
}/* CS_AR988X_proc_sta2sta_write_proc() */

//++BUG#40246: PE0 usage is high for downlink
/*
 * Multiple BSSID
 */
static int CS_AR988X_proc_multi_bssid_read_proc(char *buf, char **start, off_t offset,
				   int count, int *eof, void *data)
{
	u32 len = 0;

	len += sprintf(buf + len, CS_AR988X_WFO_QCA_11AC_MULTI_BSSID_MSG, WFO_QCA_11AC_MULTI_BSSID_ENABLE, WFO_QCA_11AC_MULTI_BSSID_ENABLE);
	len += sprintf(buf + len, "\n%s = 0x%08x\n", WFO_QCA_11AC_MULTI_BSSID_ENABLE,
			cs_wfo_qca_11ac_multi_bssid_enabled);
	*eof = 1;

	return len;
}/* CS_AR988X_proc_multi_bssid_read_proc() */

static int CS_AR988X_proc_multi_bssid_write_proc(struct file *file, const char *buffer,
				    unsigned long count, void *data)
{
	char buf[32];
	unsigned long mask;
	ssize_t len;

	len = min(count, (unsigned long)(sizeof(buf) - 1));
	if (copy_from_user(buf, buffer, len))
		goto QCA_11AC_MULTI_BSSID_INVAL_EXIT;

	buf[len] = '\0';
	if (strict_strtoul(buf, 0, &mask))
		goto QCA_11AC_MULTI_BSSID_INVAL_EXIT;

	if (mask > WFO_AR988X_MULTI_BSSID_ENABLE)
		goto QCA_11AC_MULTI_BSSID_INVAL_EXIT;

	cs_wfo_qca_11ac_multi_bssid_enabled = mask;

    cs_wfo_ar988x_multi_bssid(0, cs_wfo_qca_11ac_multi_bssid_enabled);

	printk(KERN_WARNING "Set %s as 0x%08x\n", WFO_QCA_11AC_MULTI_BSSID_ENABLE, cs_wfo_qca_11ac_multi_bssid_enabled);

	return count;

QCA_11AC_MULTI_BSSID_INVAL_EXIT:
	printk(KERN_WARNING "Invalid argument\n");
	printk(KERN_WARNING CS_AR988X_WFO_QCA_11AC_MULTI_BSSID_MSG, WFO_QCA_11AC_MULTI_BSSID_ENABLE, WFO_QCA_11AC_MULTI_BSSID_ENABLE);
	/* if we return error code here, PROC fs may retry up to 3 times. */
	return count;
}/* CS_AR988X_proc_multi_bssid_write_proc() */
//--BUG#40246

void CS_AR988X_proc_init_module(void)
{
	cs752x_add_proc_handler(WFO_QCA_11AC_STA2STA_ENABLE,
	            CS_AR988X_proc_sta2sta_read_proc,
				CS_AR988X_proc_sta2sta_write_proc,
				proc_driver_cs752x_wfo);
//++BUG#40246: PE0 usage is high for downlink
	cs752x_add_proc_handler(WFO_QCA_11AC_MULTI_BSSID_ENABLE,
	            CS_AR988X_proc_multi_bssid_read_proc,
				CS_AR988X_proc_multi_bssid_write_proc,
				proc_driver_cs752x_wfo);
//--BUG#40246

	return;
}/* CS_AR988X_proc_init_module() */


void CS_AR988X_proc_exit_module(void)
{
	/* no problem if it was not registered */
	/* remove file entry */
	remove_proc_entry(WFO_QCA_11AC_MULTI_BSSID_ENABLE, proc_driver_cs752x_wfo); //BUG#40246: PE0 usage is high for downlink
	remove_proc_entry(WFO_QCA_11AC_STA2STA_ENABLE, proc_driver_cs752x_wfo);

	return;
}/* CS_AR988X_proc_exit_module () */
//--BUG#39672


/*
 * forward CE messages which from wfo PNIC to HIF layer
 */
void CE_wfo_recv_msg(struct ath_hif_pci_softc *sc, unsigned int CE_id, void * skb)
{
    struct CE_state *CE_state = sc->CE_id_to_state[CE_id];
    HIF_WFO_RX_completion(CE_state->recv_context, skb);

}

void CE_wfo_send_msg_done(struct ath_hif_pci_softc *sc, unsigned int CE_id, void * skb)
{
    struct CE_state *CE_state = sc->CE_id_to_state[CE_id];
#if ATH_11AC_TXCOMPACT
#else
    HIF_WFO_TX_completion(CE_state->send_context, skb);
#endif
}

bool CS_AR988X_WFO_enabled(struct ath_hif_pci_softc *sc)
{
	/*
	 * No special purpose now.
	 */
	return sc->wfo_enabled;

}

u8 CS_AR988X_WFO_get_pe_id(struct ath_hif_pci_softc *sc)
{
	if (sc->pni_tx_qid == ENCRYPTION_VOQ_BASE)
		return CS_WFO_IPC_PE0_CPU_ID;
	else if (sc->pni_tx_qid == ENCAPSULATION_VOQ_BASE)
		return CS_WFO_IPC_PE1_CPU_ID;
	else {
		printk("%s pAd->pni_tx_qid %d is not initialized yet\n",
			__func__, sc->pni_tx_qid);
		return -1;
	}

}

u8 CS_AR988X_WFO_PNI_init(struct ath_hif_pci_softc *sc)
{
	struct net_device *dev = pci_get_drvdata(sc->pdev);
	struct pci_dev *pdev = sc->pdev;
	int pid = CS_WFO_IPC_PE0_CPU_ID;
	sc->wfo_enabled = 0;

	if (pid == -1) {
		printk("%s no available PE \n", __func__ );
		return 0;
	}
	/*
	 * PE will handle TX and RX
	 */
	if (pid == CS_WFO_IPC_PE0_CPU_ID)
		sc->pni_tx_qid = ENCRYPTION_VOQ_BASE;
	else
		sc->pni_tx_qid = ENCAPSULATION_VOQ_BASE;
	sc->pid = pid;
	sc->wfo_enabled = cs_pni_register_chip_callback_xmit(CS_WFO_CHIP_AR988X, pid - CS_WFO_IPC_PE0_CPU_ID,
		sc, &CS_AR988X_HandleRxFrameFromPNI_CE_PKT,	&CS_AR988X_HandleRxFrameFromPNI_8023,
		&CS_AR988X_PNI_TX_CE_SKB_Done);

	printk("%s::pni_tx_qid %d\n", __func__, sc->pni_tx_qid);
	if (sc->wfo_enabled) {
		u32 pcie_phy_addr_start[6], pcie_phy_addr_end[6];
		memset(pcie_phy_addr_start, 0, sizeof(pcie_phy_addr_start));
		memset(pcie_phy_addr_end, 0, sizeof(pcie_phy_addr_end));
		pcie_phy_addr_start[0] =  pdev->resource[0].start/*dev->mem_start*/;
		pcie_phy_addr_end[0] = pdev->resource[0].end/*dev->mem_end*/;
		printk("%s phy_addr start=%x end=%x\n", __func__, pcie_phy_addr_start[0], pcie_phy_addr_end[0]);

		cs_wfo_ipc_send_pcie_phy_addr(pid, 0x01, pcie_phy_addr_start, pcie_phy_addr_end);
	}
	printk("%s done\n", __func__);

    //++BUG#39672: 1. Separate STA in same SSID
	if (sc->wfo_enabled == 1) {
	    vsc = sc;
		CS_AR988X_proc_init_module();
	}
    //--BUG#39672
    
	return sc->wfo_enabled;
}

u8 CS_AR988X_WFO_PNI_exit(struct ath_hif_pci_softc *sc)
{

	printk("%s::pni_tx_qid %d\n", __func__, sc->pni_tx_qid);

	sc->wfo_enabled = cs_pni_unregister_callback(&sc->pni_tx_qid, sc);
	sc->pni_tx_qid = 0;

	//++BUG#39672: 1. Separate STA in same SSID
	CS_AR988X_proc_exit_module();
    vsc = NULL;
	//--BUG#39672
    
	return sc->wfo_enabled;

}

void cs_wfo_dump_skb(struct sk_buff *skb)
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
	printk("\n \n");

}

u8 CS_AR988X_HandleRxFrameFromPNI_CE_PKT(
	u8 rx_voq,
	struct ath_hif_pci_softc *sc,
	struct sk_buff *skb)
{
	struct net_device *dev = pci_get_drvdata(sc->pdev);  //pdev == PCIe device
	struct ol_ath_softc_net80211 *scn = ath_netdev_priv(dev); //comm device
    struct CE_state *CE_state;
    int CE_id;
	int voq_idx;
	voq_idx = rx_voq - CPU_PORT3_VOQ_BASE;

	if (voq_idx == 0) {
		CE_id = 1;
    	CE_state = sc->CE_id_to_state[CE_id];
		memset(skb->cb, 0x0, sizeof(skb->cb));
		NBUF_EXTRA_FRAG_WORDSTREAM_FLAGS(skb) =
        	(1 << (CVG_NBUF_MAX_EXTRA_FRAGS + 1)) - 1;
		/*
		 * because NE cannot receive the packet size < 60
		 * so if CE message length < 60, we will always get 60.
		 * thus need to update the correct size;
		 */
		skb->len = skb->data[2] + skb->data[3] * 16 + HTC_HDR_LENGTH;
		/*
		 * for monitor CE#1 control message
		 */
#if 0
		//if (skb->data[0] == 0) /*Endpint id == 0 */ {
			printk(KERN_NOTICE "%s htc_ep_id=%d payloadLen=%d flag=0x%x msg_type=%d HTC_HDR_LENGTH=8 \n",
				__func__,skb->data[0], skb->data[2] + skb->data[3]*16, skb->data[1], skb->data[8]);
			cs_wfo_dump_skb(skb);
		//}


		printk("%s voq=%d skb->len=%d CE_state=%p \n", __func__,
			rx_voq, skb->len, (void *)CE_state);
		cs_wfo_dump_skb(skb);
#endif

		CE_wfo_recv_msg(sc, CE_id, skb);
		return 0;
	}
#if 0
	if (voq_idx == 1) {
		/*
		 * this is for status is not htt_rx_status_ok
		 * then it would send to osif_receive_monitor_80211_base
		 * WARN: skb must include FW RX descriptor
		 */
		printk("%s voq=%d skb->len=%d \n", __func__, rx_voq, skb->len);
		if (ol_rx_monitor_deliver(scn->pdev_txrx_handle, skb, 1)) {
			dev_kfree_skb(skb);
        }
		return 0;
	}

	if (voq_idx == 2) {
		/*
		 * this is for fragment frames in A-MPDU
		 * which will only come from 11a/b/g stations
		 * refer to htt_t2h_msg_handler()
		 *             ol_rx_frag_indication_handler()
		 *
		 */
		printk("%s voq=%d skb->len=%d \n", __func__, rx_voq, skb->len);
		dev_kfree_skb(skb);

		return 0;
	}
#endif
	return 0;
}


extern cs_port_id_t cs_qos_get_voq_id(struct sk_buff *skb);
u8 CS_AR988X_HandleRxFrameFromPNI_8023(
	u8 rx_voq,
	struct ath_hif_pci_softc *sc,
	struct sk_buff *skb_list)
{
	struct net_device *dev = pci_get_drvdata(sc->pdev);  /*pdev == PCIe device*/
	struct ol_ath_softc_net80211 *scn = ath_netdev_priv(dev); /* this is comm device*/
	struct ieee80211com *ic = &scn->sc_ic; /*scn == &scn->sc_ic*/
	/* ol_txrx_pdev_handle pdev = (ol_txrx_pdev_handle) scn->pdev_txrx_handle;*/
	struct ieee80211vap *vap;
	os_if_t osifp;

	/* BUG#39672: WFO NEC related features (Mutliple BSSID) */
#if 0
	vap = TAILQ_FIRST(&ic->ic_vaps);
#else
	int vap_idx = (rx_voq - CPU_PORT6_VOQ_BASE) / 2;

	TAILQ_FOREACH(vap, &ic->ic_vaps, iv_next) {
	 	if (vap->iv_unit == vap_idx) {
			 //printk("%s vap == %p vap_idx=%d \n", __func__, vap, vap_idx);
	  	break;
		}
 	}
#endif

	if (vap != NULL	) {
		osifp = wlan_vap_get_registered_handle(vap);
		//cs_wfo_dump_skb(skb_list);
#if 0 
		printk(KERN_NOTICE "%s voq=%d skb->len=%d osifp=%p, sc->pid=%d\n", __func__, rx_voq, skb_list->len, osifp, sc->pid);
#endif
		/*
		 * TODO: if there has monitor device, we need to send the packet to monitor one
		 * by ol_rx_monitor_deliver(scn->pdev_txrx_handle, skb_list, 0);
		 * but it needs FW RX descriptor
		 */
		cs_hw_accel_wfo_wifi_rx(CS_WFO_CHIP_AR988X, sc->pid, skb_list);
		osif_pltfrm_deliver_data_ol(osifp, skb_list);
	} else {
		printk("%s vap == NULL \n", __func__);
		dev_kfree_skb(skb_list);
	}

	return 0;
}

u8 CS_AR988X_PNI_TX_CE_SKB(struct ath_hif_pci_softc *sc, int nbytes, struct sk_buff *skb_list)
{
	int num_items = NBUF_NUM_EXTRA_FRAGS(skb_list) + 1;
	int bytes = nbytes, nfrags = 0;

	struct cs_wfo_sg_list sg_list;
	sg_list.num_items = num_items;
	//printk("%s skb_list=%p num_items=%d bytes=%d \n", __func__, skb_list, num_items, bytes);
    do {
        void * frag_paddr;
		char * frag_vaddr;
        int frag_bytes;
		int send_bytes;

        frag_paddr = adf_nbuf_get_frag_paddr_lo(skb_list, nfrags);
        frag_bytes = adf_nbuf_get_frag_len(skb_list, nfrags);
		send_bytes = frag_bytes > bytes ? bytes : frag_bytes;
		sg_list.buf_addr[nfrags] = frag_paddr;
		if (nfrags == (num_items - 1))
			sg_list.buf_len[nfrags] = frag_bytes;
		else
			sg_list.buf_len[nfrags] = send_bytes;

#if 0
		frag_vaddr = adf_nbuf_get_frag_vaddr(skb_list, nfrags);
		printk("\t %s nfrags=%d send_bytes=%d frag_bytes=%d frag_paddr=%p frag_vaddr=%p gather=%d \n",
			__func__, nfrags,send_bytes, frag_bytes, frag_paddr, frag_vaddr, ((nfrags+1)<num_items)?1:0);
		int i;
		printk("\t   ");
		for (i = 0 ; i< send_bytes;i++)
			printk("%02X ", frag_vaddr[i]);
		printk("\n ");
#endif
        bytes -= frag_bytes;
        nfrags++;
    } while (bytes > 0);

	if (num_items > 2)
		printk("ERR ?? num_items=%d > 2\n", num_items);

    int qid = 0;
    u8 *p_mac_da = NULL;
	wfo_mac_entry_s mac_entry;
	struct local_htt_desc *htt_desc;
	u8 msg[30];
	//++BUG#39672: 2. QoS
    u8 qid_idx=0;
	//--BUG#39672

    if (!sc)
		return 0;

    qid = sc->pni_tx_qid;
    if (num_items == 1) {
//++BUG#39672: 2. QoS
        // transmit  packets to the default voq#
        qid = qid + (7 - CS_QOS_DSCP_DEFAULT_PRIORITY);
//--BUG#39672
        cs_pni_xmit_ar988x(sc->pid, qid, sg_list.buf_addr[0], sg_list.buf_len[0], 0, 0, skb_list);
    } else {
//++BUG#39672: 2. QoS
        if (skb_list->protocol == htons(ETH_P_EAPOL)) {
            qid_idx = 7 - CS_QOS_EAPOL_DEFAULT_PRIORITY;
//            printk("%s:%d:: EAPOL qid_idx %d \n", __func__, __LINE__, qid_idx);
        } else {
            qid_idx = cs_qos_get_voq_id(skb_list);
        }
        qid = qid + qid_idx;
//--BUG#39672
        cs_pni_xmit_ar988x(sc->pid, qid, sg_list.buf_addr[0], sg_list.buf_len[0] + FRAG_DESC_SIZE * 2,
			sg_list.buf_addr[1], sg_list.buf_len[1], skb_list);

		htt_desc = (struct local_htt_desc*) phys_to_virt(sg_list.buf_addr[0]);
		if((htt_desc->msdu_desc1 & 0x000f) == HTT_H2T_MSG_TYPE_TX_FRM) {
			p_mac_da = (u8*) phys_to_virt(sg_list.buf_addr[1]);

			/* Prepare 802.3 Mac entry */

			/* Add HW acceleration Hash */
			memset(&mac_entry, 0, sizeof(mac_entry));
			memset(&msg, 0, sizeof(mac_entry));
			memcpy(&msg[0], p_mac_da, 6);
			memcpy(&msg[6], htt_desc, 24);
			mac_entry.mac_da = p_mac_da;
			mac_entry.da_type = WFO_MAC_TYPE_802_11;
			mac_entry.pe_id = CS_WFO_IPC_PE0_CPU_ID;
			mac_entry.p802_11_hdr = &msg;
			mac_entry.len = 30;
			mac_entry.frame_type = 0x4;
			/*
			 * for Atheros 11ac, we send traffic to default voq offset 7
			 */
//++BUG#39672: 2. QoS
//			cs_hw_accel_wfo_wifi_tx_voq(CS_WFO_CHIP_AR988X, sc->pid, skb_list, qid + 7, &mac_entry);
			cs_hw_accel_wfo_wifi_tx_voq(CS_WFO_CHIP_AR988X, sc->pid, skb_list, qid, &mac_entry);
//--BUG#39672
	    }

    }
	return 0;
}

u8 temp_CS_AR988X_PNI_TX_COMPLETE_DONE(struct sk_buff *skb_list)
{
	void * frag_paddr;
	char * frag_vaddr;
	int frag_bytes;

	frag_paddr = adf_nbuf_get_frag_paddr_lo(skb_list, 0);
	frag_bytes = adf_nbuf_get_frag_len(skb_list, 0);
	frag_vaddr = adf_nbuf_get_frag_vaddr(skb_list, 0);
#if 0
	printk("\t %s frag_bytes=%d frag_paddr=%p frag_vaddr=%p  \n",
				__func__, frag_bytes, frag_paddr, frag_vaddr);
	int i;
	printk("\t	 ");
	for (i = 0 ; i< frag_bytes;i++)
		printk("%02X ", frag_vaddr[i]);
	printk("\n ");
#endif
	cs_pni_xmit_ar988x(CS_WFO_IPC_PE0_CPU_ID, 25, frag_paddr,
		frag_bytes, 0, 0, skb_list);

}

u8 CS_AR988X_PNI_TX_CE_SKB_Done(struct ath_hif_pci_softc *sc, struct sk_buff *skb)
{
	int num_items = NBUF_NUM_EXTRA_FRAGS(skb) + 1;
	char * frag_vaddr;
	struct local_htt_desc *htt_desc;
	htt_desc = adf_nbuf_get_frag_vaddr(skb, 0);

	if((htt_desc->msdu_desc1 & 0x000f) == HTT_T2H_MSG_TYPE_TX_COMPL_IND) {
		dev_kfree_skb(skb);
		return 0;
	}
	CE_wfo_send_msg_done(sc, CS_A988X_CE_HTT_TX_ID, skb);
	if(sc->scn->pdev_txrx_handle) {
		/*
		 * for replace the code for HTT_T2H_MSG_TYPE_TX_COMPL_IND message
		 */
		if((htt_desc->msdu_desc1 & 0x000f) == HTT_H2T_MSG_TYPE_TX_FRM) {
			//printk("%s pdev_txrx_handle=%p tx_desc_id=%d\n", __func__, sc->scn->pdev_txrx_handle, htt_desc->msdu_id);
    	    cs_ol_tx_completion_handler(sc->scn->pdev_txrx_handle, htt_desc->msdu_id, htt_tx_status_ok);
		}
	}
	return 0;
}

