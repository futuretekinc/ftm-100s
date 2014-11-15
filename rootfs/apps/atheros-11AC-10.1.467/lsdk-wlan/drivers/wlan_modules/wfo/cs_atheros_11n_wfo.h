#ifndef __CS_ATHEROS_11N_WFO_H__
#define __CS_ATHEROS_11N_WFO_H__

#include <osdep.h>
#include <mach/cs75xx_pni.h>
#include <mach/cs75xx_ipc_wfo.h>
#include <cs_core_logic.h>
#include <mach/cs_9580_wfo_mem_def.h>

/* Bug#39840: wfo mode 9; dbdc; can't ping 11n from g2-eth1 pc \
   Move from cs_atheros_11n_wfo.c to here */
/* client ID for PE0 and PE1 */
typedef enum {
    CS_WFO_NI_NEW = 0,
    CS_WFO_NI_ADD_ENTRY,
    CS_WFO_NI_UPDATE_KEY,
    CS_WFO_NI_ADD_HASH,
    CS_WFO_NI_SW_ONLY,
} cs_wfo_ni_status;

bool CS_AR9580_WFO_enabled(struct ath_softc_net80211 *scn);
u8 CS_AR9580_WFO_PNI_init(struct ath_softc_net80211 *scn, u32 phy_addr_start, u32 phy_addr_end);
u8 CS_AR9580_WFO_PNI_exit(struct ath_softc_net80211 *scn);
bool CS_AR9580_WFO_TX_80211n(struct ath_softc_net80211 *scn, int qnum, void * txs, struct ath_buf *bf);
bool CS_AR9580_WFO_send_reset_rx(struct ath_softc_net80211 *scn);
bool CS_AR9580_WFO_TX_add_hash(struct ath_softc_net80211 *scn, int qnum, struct ath_buf *bf, ieee80211_tx_control_t *txctl);

extern int cs_core_logic_output_set_cb(struct sk_buff *skb);
extern int cs_hw_accel_wfo_wifi_tx_voq(int wifi_chip, int pe_id, struct sk_buff *skb,
        u8 tx_qid, wfo_mac_entry_s * mac_entry);
extern int cs_hw_accel_wfo_wifi_rx(int wifi_chip, int pe_id, struct sk_buff *skb);

#define CS_WFO_RATE_ADJUST_PERIOD 100

#endif
