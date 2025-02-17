/*
 * Copyright (c) 2008-2010, Atheros Communications Inc. 
 * All Rights Reserved.
 * 
 * Copyright (c) 2011 Qualcomm Atheros, Inc.
 * All Rights Reserved.
 * Qualcomm Atheros Confidential and Proprietary.
 * 
 */

#include "opt_ah.h"

#ifdef AH_SUPPORT_AR9300

#include "ah.h"
#include "ah_desc.h"
#include "ah_internal.h"

#include "ar9300/ar9300.h"
#include "ar9300/ar9300reg.h"
#include "ar9300/ar9300desc.h"

/*
 * Get the RXDP.
 */
u_int32_t
ar9300_get_rx_dp(struct ath_hal *ath, HAL_RX_QUEUE qtype)
{
    if (qtype == HAL_RX_QUEUE_HP) {
        return OS_REG_READ(ath, AR_HP_RXDP);
    } else {
        return OS_REG_READ(ath, AR_LP_RXDP);
    }
}

/*
 * Set the rx_dp.
 */
void
ar9300_set_rx_dp(struct ath_hal *ah, u_int32_t rxdp, HAL_RX_QUEUE qtype)
{
    HALASSERT((qtype == HAL_RX_QUEUE_HP) || (qtype == HAL_RX_QUEUE_LP));

    if (qtype == HAL_RX_QUEUE_HP) {
        OS_REG_WRITE(ah, AR_HP_RXDP, rxdp);
    } else {
        OS_REG_WRITE(ah, AR_LP_RXDP, rxdp);
    }
}

/*
 * Set Receive Enable bits.
 */
void
ar9300_enable_receive(struct ath_hal *ah)
{
    OS_REG_WRITE(ah, AR_CR, 0);
}

/*
 * Set the RX abort bit.
 */
bool
ar9300_set_rx_abort(struct ath_hal *ah, bool set)
{ 
    if (set) {
        /* Set the force_rx_abort bit */
        OS_REG_SET_BIT(ah, AR_DIAG_SW, (AR_DIAG_RX_DIS | AR_DIAG_RX_ABORT));

        if ( AH_PRIVATE(ah)->ah_reset_reason == HAL_RESET_BBPANIC ){
            /* depending upon the BB panic status, rx state may not return to 0,
             * so skipping the wait for BB panic reset */
            OS_REG_CLR_BIT(ah, AR_DIAG_SW, (AR_DIAG_RX_DIS | AR_DIAG_RX_ABORT));
            return false;    
        } else {
            bool okay;
#ifdef ART_BUILD
            okay = ath_hal_wait(
                ah, AR_OBS_BUS_1, AR_OBS_BUS_1_RX_STATE, 0, AH_WAIT_TIMEOUT/100);
#else
            okay = ath_hal_wait(
                ah, AR_OBS_BUS_1, AR_OBS_BUS_1_RX_STATE, 0, AH_WAIT_TIMEOUT);
#endif
            /* Wait for Rx state to return to 0 */
            if (!okay) {
                u_int32_t    reg;

                /* abort: chip rx failed to go idle in 10 ms */
                OS_REG_CLR_BIT(ah, AR_DIAG_SW,
                    (AR_DIAG_RX_DIS | AR_DIAG_RX_ABORT));

                reg = OS_REG_READ(ah, AR_OBS_BUS_1);
                HDPRINTF(ah, HAL_DBG_RX,
                    "%s: rx failed to go idle in 10 ms RXSM=0x%x\n",
                    __func__, reg);

                return false; /* failure */
            }
        }
    } else {
        OS_REG_CLR_BIT(ah, AR_DIAG_SW, (AR_DIAG_RX_DIS | AR_DIAG_RX_ABORT));
    }

    return true; /* success */
}

/*
 * Stop Receive at the DMA engine
 */
bool
ar9300_stop_dma_receive(struct ath_hal *ah, u_int timeout)
{
    int wait;
    bool status, okay;
    u_int32_t org_value;

#define AH_RX_STOP_DMA_TIMEOUT 10000   /* usec */
#define AH_TIME_QUANTUM        100     /* usec */

#ifdef AR9300_EMULATION
    timeout = 100000;
#else
    if (timeout == 0) {
        timeout = AH_RX_STOP_DMA_TIMEOUT;
    }
#endif

    org_value = OS_REG_READ(ah, AR_MACMISC);

    OS_REG_WRITE(ah, AR_MACMISC, 
        ((AR_MACMISC_DMA_OBS_LINE_8 << AR_MACMISC_DMA_OBS_S) | 
         (AR_MACMISC_MISC_OBS_BUS_1 << AR_MACMISC_MISC_OBS_BUS_MSB_S)));

        okay = ath_hal_wait(
            ah, AR_DMADBG_7, AR_DMADBG_RX_STATE, 0, AH_WAIT_TIMEOUT);
    /* wait for Rx DMA state machine to become idle */
        if (!okay) {
            HDPRINTF(ah, HAL_DBG_RX,
                "reg AR_DMADBG_7 is not 0, instead 0x%08x\n",
                OS_REG_READ(ah, AR_DMADBG_7));
        }

    /* Set receive disable bit */
    OS_REG_WRITE(ah, AR_CR, AR_CR_RXD);

    /* Wait for rx enable bit to go low */
    for (wait = timeout / AH_TIME_QUANTUM; wait != 0; wait--) {
        if ((OS_REG_READ(ah, AR_CR) & AR_CR_RXE) == 0) {
            break;
        }
        OS_DELAY(AH_TIME_QUANTUM);
    }

    if (wait == 0) {
        HDPRINTF(ah, HAL_DBG_RX, "%s: dma failed to stop in %d ms\n"
                "AR_CR=0x%08x\nAR_DIAG_SW=0x%08x\n",
                __func__,
                timeout / 1000,
                OS_REG_READ(ah, AR_CR),
                OS_REG_READ(ah, AR_DIAG_SW));
        status = false;
    } else {
        status = true;
    }

    OS_REG_WRITE(ah, AR_MACMISC, org_value);

    return status;
#undef AH_RX_STOP_DMA_TIMEOUT
#undef AH_TIME_QUANTUM
}

/*
 * Start Transmit at the PCU engine (unpause receive)
 */
void
ar9300_start_pcu_receive(struct ath_hal *ah, bool is_scanning)
{
    ar9300_enable_mib_counters(ah);
    ar9300_ani_reset(ah, is_scanning);
    /* Clear RX_DIS and RX_ABORT after enabling phy errors in ani_reset */
    OS_REG_CLR_BIT(ah, AR_DIAG_SW, (AR_DIAG_RX_DIS | AR_DIAG_RX_ABORT));
}

/*
 * Stop Transmit at the PCU engine (pause receive)
 */
void
ar9300_stop_pcu_receive(struct ath_hal *ah)
{
    OS_REG_SET_BIT(ah, AR_DIAG_SW, AR_DIAG_RX_DIS);
    ar9300_disable_mib_counters(ah);
}

/*
 * Set multicast filter 0 (lower 32-bits)
 *               filter 1 (upper 32-bits)
 */
void
ar9300_set_multicast_filter(
    struct ath_hal *ah,
    u_int32_t filter0,
    u_int32_t filter1)
{
    OS_REG_WRITE(ah, AR_MCAST_FIL0, filter0);
    OS_REG_WRITE(ah, AR_MCAST_FIL1, filter1);
}

/*
 * Get the receive filter.
 */
u_int32_t
ar9300_get_rx_filter(struct ath_hal *ah)
{
    u_int32_t bits = OS_REG_READ(ah, AR_RX_FILTER);
    u_int32_t phybits = OS_REG_READ(ah, AR_PHY_ERR);
    if (phybits & AR_PHY_ERR_RADAR) {
        bits |= HAL_RX_FILTER_PHYRADAR;
    }
    if (phybits & (AR_PHY_ERR_OFDM_TIMING | AR_PHY_ERR_CCK_TIMING)) {
        bits |= HAL_RX_FILTER_PHYERR;
    }
    return bits;
}

/*
 * Set the receive filter.
 */
void
ar9300_set_rx_filter(struct ath_hal *ah, u_int32_t bits)
{
    u_int32_t phybits;

    if (AR_SREV_SCORPION(ah) || AR_SREV_HONEYBEE(ah)) {
        /* Enable Rx for 4 address frames */
        bits |= AR_RX_4ADDRESS;
    }
    if (AR_SREV_JUPITER(ah) || AR_SREV_APHRODITE(ah)) {
        /* HW fix for rx hang and corruption. */
        bits |= AR_RX_CONTROL_WRAPPER;
    }
    OS_REG_WRITE(ah, AR_RX_FILTER,
        bits | AR_RX_UNCOM_BA_BAR | AR_RX_COMPR_BAR);
    phybits = 0;
    if (bits & HAL_RX_FILTER_PHYRADAR) {
        phybits |= AR_PHY_ERR_RADAR;
    }
    if (bits & HAL_RX_FILTER_PHYERR) {
        phybits |= AR_PHY_ERR_OFDM_TIMING | AR_PHY_ERR_CCK_TIMING;
    }
    OS_REG_WRITE(ah, AR_PHY_ERR, phybits);
    if (phybits) {
        OS_REG_WRITE(ah, AR_RXCFG,
            OS_REG_READ(ah, AR_RXCFG) | AR_RXCFG_ZLFDMA);
    } else {
        OS_REG_WRITE(ah, AR_RXCFG,
            OS_REG_READ(ah, AR_RXCFG) &~ AR_RXCFG_ZLFDMA);
    }
}

/*
 * Select to pass PLCP headr or EVM data.
 */
bool
ar9300_set_rx_sel_evm(struct ath_hal *ah, bool sel_evm, bool just_query)
{
    struct ath_hal_9300 *ahp = AH9300(ah);
    bool old_value = ahp->ah_get_plcp_hdr == 0;

    if (just_query) {
        return old_value;
    }
    if (sel_evm) {
        OS_REG_SET_BIT(ah, AR_PCU_MISC, AR_PCU_SEL_EVM);
    } else {
        OS_REG_CLR_BIT(ah, AR_PCU_MISC, AR_PCU_SEL_EVM);
    }

    ahp->ah_get_plcp_hdr = !sel_evm;

    return old_value;
}

void ar9300_promisc_mode(struct ath_hal *ah, bool enable)
{
    u_int32_t reg_val = 0;
    reg_val =  OS_REG_READ(ah, AR_RX_FILTER);
    if (enable){
        reg_val |= AR_RX_PROM;
    } else{ /*Disable promisc mode */
        reg_val &= ~AR_RX_PROM;
    }    
    OS_REG_WRITE(ah, AR_RX_FILTER, reg_val);
}

void 
ar9300_read_pktlog_reg(
    struct ath_hal *ah,
    u_int32_t *rxfilter_val,
    u_int32_t *rxcfg_val,
    u_int32_t *phy_err_mask_val,
    u_int32_t *mac_pcu_phy_err_regval)
{
    *rxfilter_val = OS_REG_READ(ah, AR_RX_FILTER);
    *rxcfg_val    = OS_REG_READ(ah, AR_RXCFG);
    *phy_err_mask_val = OS_REG_READ(ah, AR_PHY_ERR);
    *mac_pcu_phy_err_regval = OS_REG_READ(ah, 0x8338);
    HDPRINTF(ah, HAL_DBG_UNMASKABLE,
        "%s[%d] rxfilter_val 0x%08x , rxcfg_val 0x%08x, "
        "phy_err_mask_val 0x%08x mac_pcu_phy_err_regval 0x%08x\n",
        __func__, __LINE__,
        *rxfilter_val, *rxcfg_val, *phy_err_mask_val, *mac_pcu_phy_err_regval);
}

void
ar9300_write_pktlog_reg(
    struct ath_hal *ah,
    bool enable,
    u_int32_t rxfilter_val,
    u_int32_t rxcfg_val,
    u_int32_t phy_err_mask_val,
    u_int32_t mac_pcu_phy_err_reg_val)
{
    if (AR_SREV_JUPITER(ah) || AR_SREV_APHRODITE(ah)) {
        /* HW fix for rx hang and corruption. */
        rxfilter_val |= AR_RX_CONTROL_WRAPPER;
    }
    if (enable) { /* Enable pktlog phyerr setting */
        OS_REG_WRITE(ah, AR_RX_FILTER, 0xffff | AR_RX_COMPR_BAR | rxfilter_val);
        OS_REG_WRITE(ah, AR_PHY_ERR, 0xFFFFFFFF);
        OS_REG_WRITE(ah, AR_RXCFG, rxcfg_val | AR_RXCFG_ZLFDMA);
        OS_REG_WRITE(ah, AR_PHY_ERR_MASK_REG, mac_pcu_phy_err_reg_val | 0xFF);
    } else { /* Disable phyerr and Restore regs */
        OS_REG_WRITE(ah, AR_RX_FILTER, rxfilter_val);
        OS_REG_WRITE(ah, AR_PHY_ERR, phy_err_mask_val);
        OS_REG_WRITE(ah, AR_RXCFG, rxcfg_val);
        OS_REG_WRITE(ah, AR_PHY_ERR_MASK_REG, mac_pcu_phy_err_reg_val);
    }
    HDPRINTF(ah, HAL_DBG_UNMASKABLE,
        "%s[%d] ena %d rxfilter_val 0x%08x , rxcfg_val 0x%08x, "
        "phy_err_mask_val 0x%08x mac_pcu_phy_err_regval 0x%08x\n",
        __func__, __LINE__,
        enable, rxfilter_val, rxcfg_val,
        phy_err_mask_val, mac_pcu_phy_err_reg_val);
}

#endif /* AH_SUPPORT_AR9300 */
