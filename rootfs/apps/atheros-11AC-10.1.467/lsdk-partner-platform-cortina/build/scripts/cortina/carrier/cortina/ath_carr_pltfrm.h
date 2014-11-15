/* 
 * $Id: 
*/

/*
 * Defintions for the Atheros Wireless LAN controller driver.
 */
#ifndef _ATH_CARR_PLTFRM_H_	
#define _ATH_CARR_PLTFRM_H_

#include <generated/autoconf.h> /* __KERNEL__ is defined when compile hal.o for linux platform, so need to include it */

/* Note: modify the address to reflect real world usage */
#define CARRIER_EEPROM_START_ADDR 0x12345678
#define CARRIER_EEPROM_MAX	0xae0

#define CARRIER_PLTFRM_PRIVATE_SET __stringify(set_undef)
#define CARRIER_PLTFRM_PRIVATE_GET __stringify(get_undef)     

#define ath_carr_get_cal_mem_legacy(_cal_mem) \
	do {		\
		_cal_mem = OS_REMAP(CARRIER_EEPROM_START_ADDR, CARRIER_EEPROM_MAX);	\
	} while (0)

#define ath_carr_mb7x_delay(_nsec) do {} while (0)
#define ath_carr_merlin_fill_reg_shadow(_ah, _reg, _val)  do {} while (0) 

#define ath_carr_merlin_update_ob_rf5g_ch0(_ah, _reg_val) \
    do { \
        (_reg_val) = OS_REG_READ(ah, AR_AN_RF5G1_CH0);                \
        (_reg_val) &= (~AR_AN_RF5G1_CH0_OB5) & (~AR_AN_RF5G1_CH0_DB5); \
    } while (0)

#define ath_carr_merlin_update_ob_rf5g_ch1(_ah, _reg_val) \
    do { \
        (_reg_val) = OS_REG_READ(ah, AR_AN_RF5G1_CH1);  \
    } while (0)

#define ath_carr_merlin_update_ob_rf2g_ch0(_ah, _reg_val) \
    do { \
            (_reg_val) = OS_REG_READ(ah, AR_AN_RF2G1_CH0); \
            (_reg_val) &= (~AR_AN_RF2G1_CH0_OB) & (~AR_AN_RF2G1_CH0_DB); \
    } while (0)

#define ath_carr_merlin_update_ob_rf2g_ch1(_ah, _reg_val) \
    do { \
            (_reg_val) = OS_REG_READ(ah, AR_AN_RF2G1_CH1); \
    } while (0)

#define ath_carr_merline_reg_read_an_top2(_ah, _reg_val) \
    do { \
            (_reg_val) = OS_REG_READ(ah, AR_AN_TOP2); \
    } while (0)

static const u_int32_t ar5212Modes_2417_Carr[][6] = {
};

static const u_int32_t ar5212Common_2417_Carr[][2] = {
};


#define A_PCI_READ32(addr)         ioread32((void __iomem *)addr)
#define A_PCI_WRITE32(addr, value) iowrite32((u32)(value), (void __iomem *)(addr))
/**
 * Move macro definition here from ah_osdep.h!
 * Assume that infineon platform and pb42 have the same way to access to h/w register.
 */
#define _OS_REG_WRITE(_ah, _reg, _val) do {                     \
        writel((_val),((volatile u_int32_t *)(AH_PRIVATE(_ah)->ah_sh + (_reg))));   \
} while(0)
#define _OS_REG_READ(_ah, _reg) \
        readl((volatile u_int32_t *)(AH_PRIVATE(_ah)->ah_sh + (_reg)))
#endif /* _ATH_CARR_1_H_ */

