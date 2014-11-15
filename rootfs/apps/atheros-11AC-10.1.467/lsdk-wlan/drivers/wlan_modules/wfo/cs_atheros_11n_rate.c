/* rate adjust */
#include <osdep.h>
#include "athdefs.h"
#include "osif_private.h"
#include "if_athvar.h"
#include "ah.h"
#include "ath_internal.h"
#include "cs_atheros_11n_wfo.h"
#include "ar9300/ar9300desc.h"
#include <ath_dev.h>

extern u32 cs_wfo_rate_adjust_period;
extern 	bool CS_AR9580_WFO_TX_mac_entry_update(struct ath_softc_net80211 *scn, int type, struct ieee80211_node *ni
		, struct ar9300_txc *ads, ieee80211_tx_control_t *txctl, struct ath_rc_series *rcs);
extern int CS_AR9580_WFO_rc_update_rate(struct ieee80211_node *ni);

static OS_TIMER_FUNC(ath_rate_adjust_timer)
{
	struct ieee80211_node *ni;
	OS_GET_TIMER_ARG(ni, struct ieee80211_node *);

#if 1
	//printk("%s:: entry[%02x:%02x:%02x:%02x:%02x:%02x] send null(%d).\n", __func__, 
	//	ni->ni_macaddr[0], ni->ni_macaddr[1], ni->ni_macaddr[2], ni->ni_macaddr[3], ni->ni_macaddr[4], ni->ni_macaddr[5], WME_AC_BE);
#endif
#if 0
	ieee80211_send_qosnulldata(ni, WME_AC_BE, 0);
#else
	CS_AR9580_WFO_rc_update_rate(ni);
#endif
	OS_SET_TIMER(&(ni->wfo_rateadapttimer), ni->wfo_rateadapttimer_period);
}


u8 CS_AR9580_WFO_mac_entry_timer_add(struct ath_softc_net80211 *scn, struct ieee80211_node *ni)
{
	struct ieee80211vap *vap = ni->ni_vap;

	if (scn == NULL)
		return 0;
	if (CS_AR9580_WFO_enabled(scn) == 0)
		return 0;
	if (scn->pid != CS_WFO_IPC_PE1_CPU_ID)
		return 0;

	if ((unsigned long)ni != (unsigned long)vap->iv_bss)
	{		
		if (ni->wfo_rateadapttimer_period == 0) {
			if (cs_wfo_rate_adjust_period)
				ni->wfo_rateadapttimer_period = cs_wfo_rate_adjust_period;
			else
				ni->wfo_rateadapttimer_period = CS_WFO_RATE_ADJUST_PERIOD;
	
			OS_INIT_TIMER(scn->sc_osdev, &ni->wfo_rateadapttimer, 
					  ath_rate_adjust_timer, ni);
			OS_SET_TIMER(&(ni->wfo_rateadapttimer), ni->wfo_rateadapttimer_period);
			printk("%s:: entry[%pM] add timer for rate adjust.\n", __func__, 
				ni->ni_macaddr);
			printk("	rate adjust timeout = %d.\n", ni->wfo_rateadapttimer_period);
		}
	}
	return 1;
}

bool CS_AR9580_WFO_mac_entry_timer_delete(struct ath_softc_net80211 *scn, struct ieee80211_node *ni)
{
	struct ieee80211vap *vap = ni->ni_vap;

	if (scn == NULL)
		return 0;
	if (CS_AR9580_WFO_enabled(scn) == 0)
		return 0;
	if (scn->pid != CS_WFO_IPC_PE1_CPU_ID)
		return 0;	
	if ((unsigned long)ni != (unsigned long)vap->iv_bss)
	{				
		if (ni->wfo_rateadapttimer_period != 0) {
			printk("%s:: entry[%pM] delete timer for rate adjust=%d.\n", __func__, 
				ni->ni_macaddr, ni->wfo_rateadapttimer_period);

#ifdef CONFIG_SMP
			OS_CANCEL_TIMER_SYNC(&ni->wfo_rateadapttimer);
#else
			OS_CANCEL_TIMER(&ni->wfo_rateadapttimer);
#endif
			ni->wfo_rateadapttimer_period = 0;
		}
	}
}


EXPORT_SYMBOL(CS_AR9580_WFO_mac_entry_timer_add);
EXPORT_SYMBOL(CS_AR9580_WFO_mac_entry_timer_delete);


