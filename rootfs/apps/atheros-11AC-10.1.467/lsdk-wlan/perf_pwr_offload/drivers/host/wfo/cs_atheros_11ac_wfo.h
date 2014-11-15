#ifndef __CS_ATHEROS_11AC_WFO_H__
#define __CS_ATHEROS_11AC_WFO_H__

#include <osdep.h>
//++BUG#39672: 1. Separate STA in same SSID
#include <mach/cs75xx_pni.h>
#include <mach/cs75xx_ipc_wfo.h>
#include <cs_core_logic.h>
#include <mach/cs_988x_wfo_mem_def.h>
//--BUG#39672

#define WFO_SG_MAX	12	/* CE_SENDLIST_ITEMS_MAX */
typedef struct cs_wfo_sg_list {
	int num_items;
	u32 buf_addr[WFO_SG_MAX];
	u16 buf_len[WFO_SG_MAX];
};

//++BUG#39672: 1. Separate STA in same SSID
typedef enum {
    CS_OK_WFO_AR988X_WMM = CS_OK,
    CS_ERR_WFO_AR988X_WMM_PARA,
    CS_ERR_WFO_AR988X_WMM_INIT_FAIL,
    CS_ERR_WFO_AR988X_WFO_NOT_ENABLE,
} cs_wfo_ar988x_wmm_status_e;
//--BUG#39672

u8 CS_AR988X_PNI_TX_CE_SKB(struct ath_hif_pci_softc *sc, int nbytes, struct sk_buff *skb_list);
u8 CS_AR988X_PNI_TX_CE_SKB_Done(struct ath_hif_pci_softc *sc, struct sk_buff *skb);


/*
 * for handle CE message from PNIC, we need two functions in CE and HIF layer.
 */
void CE_wfo_recv_msg(struct ath_hif_pci_softc *sc, unsigned int CE_id, void * skb);
void CE_wfo_send_msg_done(struct ath_hif_pci_softc *sc, unsigned int CE_id, void * skb);

int HIF_WFO_RX_completion(void * ce_context, void * skb);
int HIF_WFO_TX_completion(void * ce_context, void * skb);

u8 CS_AR988X_HandleRxFrameFromPNI_CE_PKT(u8 rx_voq, struct ath_hif_pci_softc *sc,
	struct sk_buff *skb);
u8 CS_AR988X_HandleRxFrameFromPNI_8023(u8 rx_voq, struct ath_hif_pci_softc *sc,
	struct sk_buff *skb);
bool CS_AR988X_WFO_enabled(struct ath_hif_pci_softc *sc);
u8 CS_AR988X_WFO_PNI_init(struct ath_hif_pci_softc *sc);
u8 CS_AR989X_WFO_PNI_exit(struct ath_hif_pci_softc *sc);


//Temp code
u8 temp_CS_AR988X_PNI_TX_COMPLETE_DONE(struct sk_buff *skb_list);

#endif
