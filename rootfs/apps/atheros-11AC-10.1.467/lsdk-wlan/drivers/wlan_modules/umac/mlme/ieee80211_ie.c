/*
 *  Copyright (c) 2008 Atheros Communications Inc. 
 * All Rights Reserved.
 * 
 * Copyright (c) 2011 Qualcomm Atheros, Inc.
 * All Rights Reserved.
 * Qualcomm Atheros Confidential and Proprietary.
 * 
 *
 *  all the IE parsing/processing routines.
 */
#include <ieee80211_var.h>
#include <ieee80211_channel.h>
#include <ieee80211_rateset.h>
#include "ieee80211_mlme_priv.h"

#define	IEEE80211_ADDSHORT(frm, v) 	do {frm[0] = (v) & 0xff; frm[1] = (v) >> 8;	frm += 2;} while (0)
#define	IEEE80211_ADDSELECTOR(frm, sel) do {OS_MEMCPY(frm, sel, 4); frm += 4;} while (0)
#define IEEE80211_SM(_v, _f)    (((_v) << _f##_S) & _f)
#define RX_MCS_SINGLE_STREAM_BYTE_OFFSET 0
#define RX_MCS_DUAL_STREAM_BYTE_OFFSET 1
#define RX_MCS_ALL_NSTREAM_RATES 0xff

/* unalligned little endian access */     
#define LE_READ_2(p)                            \
    ((u_int16_t)                                \
    ((((const u_int8_t *)(p))[0]      ) |       \
    (((const u_int8_t *)(p))[1] <<  8)))
#define LE_READ_4(p)                            \
    ((u_int32_t)                                \
    ((((const u_int8_t *)(p))[0]      ) |       \
    (((const u_int8_t *)(p))[1] <<  8) |        \
    (((const u_int8_t *)(p))[2] << 16) |        \
    (((const u_int8_t *)(p))[3] << 24)))

void
ieee80211_savenie(osdev_t osdev,u_int8_t **iep, const u_int8_t *ie, u_int ielen);
void ieee80211_saveie(osdev_t osdev,u_int8_t **iep, const u_int8_t *ie);

/*
 * Add a supported rates element id to a frame.
 */
u_int8_t *
ieee80211_add_rates(u_int8_t *frm, const struct ieee80211_rateset *rs)
{
    int nrates;

    *frm++ = IEEE80211_ELEMID_RATES;
    nrates = rs->rs_nrates;
    if (nrates > IEEE80211_RATE_SIZE)
        nrates = IEEE80211_RATE_SIZE;
    *frm++ = nrates;
    OS_MEMCPY(frm, rs->rs_rates, nrates);
    return frm + nrates;
}

/*
 * Add an extended supported rates element id to a frame.
 */
u_int8_t *
ieee80211_add_xrates(u_int8_t *frm, const struct ieee80211_rateset *rs)
{
    /*
     * Add an extended supported rates element if operating in 11g mode.
     */
    if (rs->rs_nrates > IEEE80211_RATE_SIZE) {
        int nrates = rs->rs_nrates - IEEE80211_RATE_SIZE;
        *frm++ = IEEE80211_ELEMID_XRATES;
        *frm++ = nrates;
        OS_MEMCPY(frm, rs->rs_rates + IEEE80211_RATE_SIZE, nrates);
        frm += nrates;
    }
    return frm;
}

/* 
 * Add an ssid elemet to a frame.
 */
u_int8_t *
ieee80211_add_ssid(u_int8_t *frm, const u_int8_t *ssid, u_int len)
{
    *frm++ = IEEE80211_ELEMID_SSID;
    *frm++ = len;
    OS_MEMCPY(frm, ssid, len);
    return frm + len;
}

/*
 * Add an erp element to a frame.
 */
u_int8_t *
ieee80211_add_erp(u_int8_t *frm, struct ieee80211com *ic)
{
    u_int8_t erp;

    *frm++ = IEEE80211_ELEMID_ERP;
    *frm++ = 1;
    erp = 0;
    if (ic->ic_nonerpsta != 0 )
        erp |= IEEE80211_ERP_NON_ERP_PRESENT;
    if (ic->ic_flags & IEEE80211_F_USEPROT)
        erp |= IEEE80211_ERP_USE_PROTECTION;
    if (ic->ic_flags & IEEE80211_F_USEBARKER)
        erp |= IEEE80211_ERP_LONG_PREAMBLE;
    *frm++ = erp;
    return frm;
}

/*
 * Add a country information element to a frame.
 */
u_int8_t *
ieee80211_add_country(u_int8_t *frm, struct ieee80211vap *vap)
{
    u_int16_t chanflags;
    struct ieee80211com *ic = vap->iv_ic;

    /* add country code */
    if(IEEE80211_IS_CHAN_2GHZ(vap->iv_bsschan))
        chanflags = IEEE80211_CHAN_2GHZ;
    else
        chanflags = IEEE80211_CHAN_5GHZ;

    ic->ic_country_iso[0] = ic->ic_country.iso[0];
    ic->ic_country_iso[1] = ic->ic_country.iso[1];
    ic->ic_country_iso[2] = ic->ic_country.iso[2];

    if (chanflags != vap->iv_country_ie_chanflags)
        ieee80211_build_countryie(vap);

    if (vap->iv_country_ie_data.country_len) {
    	OS_MEMCPY(frm, (u_int8_t *)&vap->iv_country_ie_data,
	    	vap->iv_country_ie_data.country_len + 2);
	    frm +=  vap->iv_country_ie_data.country_len + 2;
    }

    return frm;
}

#if ATH_SUPPORT_IBSS_DFS
/*
* Add a IBSS DFS element into a frame
*/
u_int8_t *
ieee80211_add_ibss_dfs(u_int8_t *frm, struct ieee80211vap *vap)
{

    OS_MEMCPY(frm, (u_int8_t *)&vap->iv_ibssdfs_ie_data,
              vap->iv_ibssdfs_ie_data.len + sizeof(struct ieee80211_ie_header));
    frm += vap->iv_ibssdfs_ie_data.len + sizeof(struct ieee80211_ie_header);

    return frm;
}
#endif /* ATH_SUPPORT_IBSS_DFS */

u_int8_t *
ieee80211_setup_wpa_ie(struct ieee80211vap *vap, u_int8_t *ie)
{
    static const u_int8_t oui[4] = { WPA_OUI_BYTES, WPA_OUI_TYPE };
    static const u_int8_t cipher_suite[][4] = {
        { WPA_OUI_BYTES, WPA_CSE_WEP40 },    /* NB: 40-bit */
        { WPA_OUI_BYTES, WPA_CSE_TKIP },
        { 0x00, 0x00, 0x00, 0x00 },        /* XXX WRAP */
        { WPA_OUI_BYTES, WPA_CSE_CCMP },
        { 0x00, 0x00, 0x00, 0x00 },        /* XXX CKIP */
        { WPA_OUI_BYTES, WPA_CSE_NULL },
    };
    static const u_int8_t wep104_suite[4] =
        { WPA_OUI_BYTES, WPA_CSE_WEP104 };
    static const u_int8_t key_mgt_unspec[4] =
        { WPA_OUI_BYTES, AKM_SUITE_TYPE_IEEE8021X };
    static const u_int8_t key_mgt_psk[4] =
        { WPA_OUI_BYTES, AKM_SUITE_TYPE_PSK };
    static const u_int8_t key_mgt_cckm[4] =
        { CCKM_OUI_BYTES, CCKM_ASE_UNSPEC };
    const struct ieee80211_rsnparms *rsn = &vap->iv_rsn;
    ieee80211_cipher_type mcastcipher;
    u_int8_t *frm = ie;
    u_int8_t *selcnt;

    *frm++ = IEEE80211_ELEMID_VENDOR;
    *frm++ = 0;                /* length filled in below */
    OS_MEMCPY(frm, oui, sizeof(oui));        /* WPA OUI */
    frm += sizeof(oui);
    IEEE80211_ADDSHORT(frm, WPA_VERSION);

    /* XXX filter out CKIP */

    /* multicast cipher */
    mcastcipher = ieee80211_get_current_mcastcipher(vap);
    if (mcastcipher == IEEE80211_CIPHER_WEP &&
        rsn->rsn_mcastkeylen >= 13)
        IEEE80211_ADDSELECTOR(frm, wep104_suite);
    else
        IEEE80211_ADDSELECTOR(frm, cipher_suite[mcastcipher]);

    /* unicast cipher list */
    selcnt = frm;
    IEEE80211_ADDSHORT(frm, 0);			/* selector count */
/* do not use CCMP unicast cipher in WPA mode */
#if IEEE80211_USE_WPA_CCMP
    if (RSN_CIPHER_IS_CCMP(rsn)) {
        selcnt[0]++;
        IEEE80211_ADDSELECTOR(frm, cipher_suite[IEEE80211_CIPHER_AES_CCM]);
    }
#endif
    if (RSN_CIPHER_IS_TKIP(rsn)) {
        selcnt[0]++;
        IEEE80211_ADDSELECTOR(frm, cipher_suite[IEEE80211_CIPHER_TKIP]);
    }

    /* authenticator selector list */
    selcnt = frm;
	IEEE80211_ADDSHORT(frm, 0);			/* selector count */
    if (RSN_AUTH_IS_CCKM(rsn)) {
        selcnt[0]++;
        IEEE80211_ADDSELECTOR(frm, key_mgt_cckm);
    } else {
    if (rsn->rsn_keymgmtset & WPA_ASE_8021X_UNSPEC) {
        selcnt[0]++;
        IEEE80211_ADDSELECTOR(frm, key_mgt_unspec);
    }
    if (rsn->rsn_keymgmtset & WPA_ASE_8021X_PSK) {
        selcnt[0]++;
        IEEE80211_ADDSELECTOR(frm, key_mgt_psk);
    }
    }

    /* optional capabilities */
    if (rsn->rsn_caps != 0 && rsn->rsn_caps != RSN_CAP_PREAUTH)
        IEEE80211_ADDSHORT(frm, rsn->rsn_caps);

    /* calculate element length */
    ie[1] = frm - ie - 2;
    KASSERT(ie[1]+2 <= sizeof(struct ieee80211_ie_wpa),
            ("WPA IE too big, %u > %zu", ie[1]+2, sizeof(struct ieee80211_ie_wpa)));
    return frm;
}

u_int8_t *
ieee80211_setup_rsn_ie(struct ieee80211vap *vap, u_int8_t *ie)
{
    static const u_int8_t cipher_suite[][4] = {
        { RSN_OUI_BYTES, RSN_CSE_WEP40 },    /* NB: 40-bit */
        { RSN_OUI_BYTES, RSN_CSE_TKIP },
        { RSN_OUI_BYTES, RSN_CSE_WRAP },
        { RSN_OUI_BYTES, RSN_CSE_CCMP },
        { RSN_OUI_BYTES, RSN_CSE_CCMP },   /* WAPI */
        { CCKM_OUI_BYTES, RSN_CSE_NULL },  /* XXX CKIP */
        { RSN_OUI_BYTES, RSN_CSE_AES_CMAC }, /* AES_CMAC */
        { RSN_OUI_BYTES, RSN_CSE_NULL },
    };
    static const u_int8_t wep104_suite[4] =
        { RSN_OUI_BYTES, RSN_CSE_WEP104 };
    static const u_int8_t key_mgt_unspec[4] =
        { RSN_OUI_BYTES, AKM_SUITE_TYPE_IEEE8021X };
    static const u_int8_t key_mgt_psk[4] =
        { RSN_OUI_BYTES, AKM_SUITE_TYPE_PSK };
    static const u_int8_t key_mgt_sha256_1x[4] =
        { RSN_OUI_BYTES, AKM_SUITE_TYPE_SHA256_IEEE8021X };
    static const u_int8_t key_mgt_sha256_psk[4] =
        { RSN_OUI_BYTES, AKM_SUITE_TYPE_SHA256_PSK };
    static const u_int8_t key_mgt_cckm[4] =
        { CCKM_OUI_BYTES, CCKM_ASE_UNSPEC };
    const struct ieee80211_rsnparms *rsn = &vap->iv_rsn;
    ieee80211_cipher_type mcastcipher;
    u_int8_t *frm = ie;
    u_int8_t *selcnt, pmkidFilled=0;
    int i;

    *frm++ = IEEE80211_ELEMID_RSN;
    *frm++ = 0;                /* length filled in below */
    IEEE80211_ADDSHORT(frm, RSN_VERSION);

    /* XXX filter out CKIP */

    /* multicast cipher */
    mcastcipher = ieee80211_get_current_mcastcipher(vap);
    if (mcastcipher == IEEE80211_CIPHER_WEP &&
        rsn->rsn_mcastkeylen >= 13) {
        IEEE80211_ADDSELECTOR(frm, wep104_suite);
    } else {
        IEEE80211_ADDSELECTOR(frm, cipher_suite[mcastcipher]);
    }

    /* unicast cipher list */
    selcnt = frm;
    IEEE80211_ADDSHORT(frm, 0);			/* selector count */
    if (RSN_CIPHER_IS_CCMP(rsn)) {
        selcnt[0]++;
        IEEE80211_ADDSELECTOR(frm, cipher_suite[IEEE80211_CIPHER_AES_CCM]);
    }
    if (RSN_CIPHER_IS_TKIP(rsn)) {
        selcnt[0]++;
        IEEE80211_ADDSELECTOR(frm, cipher_suite[IEEE80211_CIPHER_TKIP]);
    }

    /* authenticator selector list */
    selcnt = frm;
	IEEE80211_ADDSHORT(frm, 0);			/* selector count */
    if (RSN_AUTH_IS_CCKM(rsn)) {
        selcnt[0]++;
        IEEE80211_ADDSELECTOR(frm, key_mgt_cckm);
    } else {
        if (rsn->rsn_keymgmtset & RSN_ASE_8021X_UNSPEC) {
            selcnt[0]++;
            IEEE80211_ADDSELECTOR(frm, key_mgt_unspec);
        }
        if (rsn->rsn_keymgmtset & RSN_ASE_8021X_PSK) {
            selcnt[0]++;
            IEEE80211_ADDSELECTOR(frm, key_mgt_psk);
        }
        if (rsn->rsn_keymgmtset & RSN_ASE_SHA256_IEEE8021X) {
            selcnt[0]++;
            IEEE80211_ADDSELECTOR(frm, key_mgt_sha256_1x);
        }
        if (rsn->rsn_keymgmtset & RSN_ASE_SHA256_PSK) {
            selcnt[0]++;
            IEEE80211_ADDSELECTOR(frm, key_mgt_sha256_psk);
        }
    }

    /* capabilities */
    IEEE80211_ADDSHORT(frm, rsn->rsn_caps);

    /* PMKID */
    if (vap->iv_opmode == IEEE80211_M_STA && vap->iv_pmkid_count > 0) {
        struct ieee80211_node *ni = vap->iv_bss; /* bss node */
        /* Find and include the PMKID for target AP*/
        for (i = 0; i < vap->iv_pmkid_count; i++) {
            if (!OS_MEMCMP( vap->iv_pmkid_list[i].bssid, ni->ni_bssid, IEEE80211_ADDR_LEN)) {
                IEEE80211_ADDSHORT(frm, 1);
                OS_MEMCPY(frm, vap->iv_pmkid_list[i].pmkid, IEEE80211_PMKID_LEN);
                frm += IEEE80211_PMKID_LEN;
                pmkidFilled = 1;
                break;
            }
        }
    }
    
    /* mcast/group mgmt cipher set (optional 802.11w) */
    if ((vap->iv_opmode == IEEE80211_M_HOSTAP)  &&  (rsn->rsn_caps & RSN_CAP_MFP_ENABLED)) {
        if (!pmkidFilled) {
            /* PMKID is not filled. so put zero for PMKID count */
            IEEE80211_ADDSHORT(frm, 0);
        }
        IEEE80211_ADDSELECTOR(frm, cipher_suite[IEEE80211_CIPHER_AES_CMAC]);
    }
    
    /* calculate element length */
    ie[1] = frm - ie - 2;
    KASSERT(ie[1]+2 <= sizeof(struct ieee80211_ie_wpa),
            ("RSN IE too big, %u > %zu", ie[1]+2, sizeof(struct ieee80211_ie_wpa)));
    return frm;
}

static int
ieee80211_get_rxstreams(struct ieee80211com *ic, struct ieee80211vap *vap)
{

    u_int8_t rx_streams = ieee80211_getstreams(ic, ic->ic_rx_chainmask);
#if ATH_SUPPORT_WAPI
    if(IEEE80211_VAP_IS_PRIVACY_ENABLED(vap) && 
       (RSN_CIPHER_IS_SMS4(&vap->iv_rsn))) {
        if (rx_streams > ic->ic_num_wapi_rx_maxchains)
            rx_streams = ic->ic_num_wapi_rx_maxchains;
    }
#endif
    return rx_streams;
}

int
ieee80211_get_txstreams(struct ieee80211com *ic, struct ieee80211vap *vap)
{

    u_int8_t tx_streams = ieee80211_getstreams(ic, ic->ic_tx_chainmask);
#if ATH_SUPPORT_WAPI
    if(IEEE80211_VAP_IS_PRIVACY_ENABLED(vap) && 
       (RSN_CIPHER_IS_SMS4(&vap->iv_rsn))) {
        if (tx_streams > ic->ic_num_wapi_tx_maxchains)
            tx_streams = ic->ic_num_wapi_tx_maxchains;
    }
#endif
    return tx_streams;
}

/* add IE for WAPI in mgmt frames */
#if ATH_SUPPORT_WAPI
u_int8_t *
ieee80211_setup_wapi_ie(struct ieee80211vap *vap, u_int8_t *ie)
{
#define	ADDSHORT(frm, v) do {frm[0] = (v) & 0xff;frm[1] = (v) >> 8;frm += 2;} while (0)
#define	ADDSELECTOR(frm, sel) do {OS_MEMCPY(frm, sel, 4); frm += 4;} while (0)
#define	WAPI_OUI_BYTES		0x00, 0x14, 0x72

	static const u_int8_t cipher_suite[4] = 
		{ WAPI_OUI_BYTES, WAPI_CSE_WPI_SMS4};	/* SMS4 128 bits */
	static const u_int8_t key_mgt_unspec[4] =
		{ WAPI_OUI_BYTES, WAPI_ASE_WAI_UNSPEC };
	static const u_int8_t key_mgt_psk[4] =
		{ WAPI_OUI_BYTES, WAPI_ASE_WAI_PSK };
	const struct ieee80211_rsnparms *rsn = &vap->iv_rsn;
	u_int8_t *frm = ie;
	u_int8_t *selcnt;
	*frm++ = IEEE80211_ELEMID_WAPI;
	*frm++ = 0;				/* length filled in below */
	ADDSHORT(frm, WAPI_VERSION);

	/* authenticator selector list */
	selcnt = frm;
	ADDSHORT(frm, 0);			/* selector count */

	if (rsn->rsn_keymgmtset & WAPI_ASE_WAI_UNSPEC) {
		selcnt[0]++;
		ADDSELECTOR(frm, key_mgt_unspec);
	}
	if (rsn->rsn_keymgmtset & WAPI_ASE_WAI_PSK) {
		selcnt[0]++;
		ADDSELECTOR(frm, key_mgt_psk);
	}
	
	/* unicast cipher list */
	selcnt = frm;
	ADDSHORT(frm, 0);			/* selector count */

	if (RSN_HAS_UCAST_CIPHER(rsn, IEEE80211_CIPHER_WAPI)) {
		selcnt[0]++;
		ADDSELECTOR(frm, cipher_suite);
	}

	/* multicast cipher */
	ADDSELECTOR(frm, cipher_suite);

	/* optional capabilities */
	ADDSHORT(frm, rsn->rsn_caps);
	/* XXX PMKID */

    /* BKID count, only in ASSOC/REASSOC REQ frames from STA to AP*/
    if (vap->iv_opmode == IEEE80211_M_STA) {
        ADDSHORT(frm, 0);
    }

	/* calculate element length */
	ie[1] = frm - ie - 2;
	KASSERT(ie[1]+2 <= sizeof(struct ieee80211_ie_wpa),
		("RSN IE too big, %u > %u",
		ie[1]+2, sizeof(struct ieee80211_ie_wpa)));
	return frm;
#undef ADDSELECTOR
#undef ADDSHORT
#undef WAPI_OUI_BYTES
}
#endif /*ATH_SUPPORT_WAPI*/

/*
 * Add a WME Info element to a frame.
 */
u_int8_t *
ieee80211_add_wmeinfo(u_int8_t *frm, struct ieee80211_node *ni, 
                      u_int8_t wme_subtype, u_int8_t *wme_info, u_int8_t info_len)
{
    static const u_int8_t oui[4] = { WME_OUI_BYTES, WME_OUI_TYPE };
    struct ieee80211_ie_wme *ie = (struct ieee80211_ie_wme *) frm;
    struct ieee80211_wme_state *wme = &ni->ni_ic->ic_wme;
    struct ieee80211vap *vap = ni->ni_vap;

    *frm++ = IEEE80211_ELEMID_VENDOR;
    *frm++ = 0;                             /* length filled in below */
    OS_MEMCPY(frm, oui, sizeof(oui));       /* WME OUI */
    frm += sizeof(oui);
    *frm++ = wme_subtype;          /* OUI subtype */
    switch (wme_subtype) {
    case WME_INFO_OUI_SUBTYPE:
        *frm++ = WME_VERSION;                   /* protocol version */
        /* QoS Info field depends on operating mode */
        ie->wme_info = 0;
        switch (vap->iv_opmode) {
        case IEEE80211_M_HOSTAP:
            *frm = wme->wme_bssChanParams.cap_info & WME_QOSINFO_COUNT;
            if (IEEE80211_VAP_IS_UAPSD_ENABLED(vap)) {
                *frm |= WME_CAPINFO_UAPSD_EN;
            }
            frm++;
            break;
        case IEEE80211_M_STA:
            /* Set the U-APSD flags */
            if (ieee80211_vap_wme_is_set(vap) && (ni->ni_ext_caps & IEEE80211_NODE_C_UAPSD)) {
                *frm |= vap->iv_uapsd;
            }
            frm++;
            break;
        default:
            *frm++ = 0;
        }
        break;
    case WME_TSPEC_OUI_SUBTYPE:
        *frm++ = WME_TSPEC_OUI_VERSION;        /* protocol version */
        OS_MEMCPY(frm, wme_info, info_len);
        frm += info_len;
        break;
    default:
        break;
    }

    ie->wme_len = (u_int8_t)(frm - &ie->wme_oui[0]);

    return frm;
}

/*
 * Add a WME Parameter element to a frame.
 */
u_int8_t *
ieee80211_add_wme_param(u_int8_t *frm, struct ieee80211_wme_state *wme,
                        int uapsd_enable)
{
    static const u_int8_t oui[4] = { WME_OUI_BYTES, WME_OUI_TYPE };
    struct ieee80211_wme_param *ie = (struct ieee80211_wme_param *) frm;
    int i;

    *frm++ = IEEE80211_ELEMID_VENDOR;
    *frm++ = 0;				/* length filled in below */
    OS_MEMCPY(frm, oui, sizeof(oui));		/* WME OUI */
    frm += sizeof(oui);
    *frm++ = WME_PARAM_OUI_SUBTYPE;		/* OUI subtype */
    *frm++ = WME_VERSION;			/* protocol version */

    ie->param_qosInfo = 0;
    *frm = wme->wme_bssChanParams.cap_info & WME_QOSINFO_COUNT;
    if (uapsd_enable) {
        *frm |= WME_CAPINFO_UAPSD_EN;
    }
    frm++;
    *frm++ = 0;                             /* reserved field */
    for (i = 0; i < WME_NUM_AC; i++) {
        const struct wmeParams *ac =
            &wme->wme_bssChanParams.cap_wmeParams[i];
        *frm++ = IEEE80211_SM(i, WME_PARAM_ACI)
            | IEEE80211_SM(ac->wmep_acm, WME_PARAM_ACM)
            | IEEE80211_SM(ac->wmep_aifsn, WME_PARAM_AIFSN)
            ;
        *frm++ = IEEE80211_SM(ac->wmep_logcwmax, WME_PARAM_LOGCWMAX)
            | IEEE80211_SM(ac->wmep_logcwmin, WME_PARAM_LOGCWMIN)
            ;
        IEEE80211_ADDSHORT(frm, ac->wmep_txopLimit);
    }

    ie->param_len = frm - &ie->param_oui[0];

    return frm;
}

/*
 * Add an Atheros Advanaced Capability element to a frame
 */
u_int8_t *
ieee80211_add_athAdvCap(u_int8_t *frm, u_int8_t capability, u_int16_t defaultKey)
{
    static const u_int8_t oui[6] = {(ATH_OUI & 0xff), ((ATH_OUI >>8) & 0xff),
                                    ((ATH_OUI >> 16) & 0xff), ATH_OUI_TYPE, ATH_OUI_SUBTYPE, ATH_OUI_VERSION};
    struct ieee80211_ie_athAdvCap *ie = (struct ieee80211_ie_athAdvCap *) frm;

    *frm++ = IEEE80211_ELEMID_VENDOR;
    *frm++ = 0;				/* Length filled in below */
    OS_MEMCPY(frm, oui, sizeof(oui));		/* Atheros OUI, type, subtype, and version for adv capabilities */
    frm += sizeof(oui);
    *frm++ = capability;

    /* Setup default key index in little endian byte order */
    *frm++ = (defaultKey & 0xff);
    *frm++ = ((defaultKey >> 8)& 0xff);
    ie->athAdvCap_len = frm - &ie->athAdvCap_oui[0];

    return frm;
}

/*
 * Add an Atheros extended capability information element to a frame
 */
u_int8_t *
ieee80211_add_athextcap(u_int8_t *frm, u_int16_t ath_extcap, u_int8_t weptkipaggr_rxdelim)
{
    static const u_int8_t oui[6] = {(ATH_OUI & 0xff),
                                        ((ATH_OUI >>8) & 0xff),
                                        ((ATH_OUI >> 16) & 0xff),
                                        ATH_OUI_EXTCAP_TYPE,
                                        ATH_OUI_EXTCAP_SUBTYPE,
                                        ATH_OUI_EXTCAP_VERSION};

    *frm++ = IEEE80211_ELEMID_VENDOR;
    *frm++ = 10;
    OS_MEMCPY(frm, oui, sizeof(oui));
    frm += sizeof(oui);
    *frm++ = ath_extcap & 0xff;
    *frm++ = (ath_extcap >> 8) & 0xff;
    *frm++ = weptkipaggr_rxdelim & 0xff;
    *frm++ = 0; /* reserved */
    return frm;
}

/*
 * Add 802.11h information elements to a frame.
 */
u_int8_t *
ieee80211_add_doth(u_int8_t *frm, struct ieee80211vap *vap)
{
    struct ieee80211_channel *c;
    int    i, j, chancnt;
    u_int8_t chanlist[IEEE80211_CHAN_MAX + 1];
    u_int8_t prevchan;
    u_int8_t *frmbeg;
    struct ieee80211com *ic = vap->iv_ic;

    /* XXX ie structures */
    /*
     * Power Capability IE
     */
    *frm++ = IEEE80211_ELEMID_PWRCAP;
    *frm++ = 2;
    *frm++ = vap->iv_bsschan->ic_minpower;
    *frm++ = vap->iv_bsschan->ic_maxpower;

	/*
	 * Supported Channels IE as per 802.11h-2003.
	 */
    frmbeg = frm;
    prevchan = 0;
    chancnt = 0;

    for (i = 0; i < ic->ic_nchans; i++)
    {
        c = &ic->ic_channels[i];

        /* Skip turbo channels */
        if (IEEE80211_IS_CHAN_TURBO(c))
            continue;

        /* Skip half/quarter rate channels */
        if (IEEE80211_IS_CHAN_HALF(c) || IEEE80211_IS_CHAN_QUARTER(c))
            continue;

        /* Skip previously reported channels */
        for (j=0; j < chancnt; j++) {
            if (c->ic_ieee == chanlist[j])
                break;
		}
        if (j != chancnt) /* found a match */
            continue;

        chanlist[chancnt] = c->ic_ieee;
        chancnt++;

        if ((c->ic_ieee == (prevchan + 1)) && prevchan) {
            frm[1] = frm[1] + 1;
        } else {
            frm += 2;
            frm[0] =  c->ic_ieee;
            frm[1] = 1;
        }

        prevchan = c->ic_ieee;
    }

    frm += 2;

    if (chancnt) {
        frmbeg[0] = IEEE80211_ELEMID_SUPPCHAN;
        frmbeg[1] = (u_int8_t)(frm - frmbeg - 2);
    } else {
        frm = frmbeg;
    }

    return frm;
}

/*
 * Add ht supported rates to HT element.
 * Precondition: the Rx MCS bitmask is zero'd out.
 */
static void
ieee80211_set_htrates(struct ieee80211vap *vap, u_int8_t *rx_mcs, struct ieee80211com *ic)
{
    u_int8_t tx_streams = ieee80211_get_txstreams(ic, vap),
             rx_streams = ieee80211_get_rxstreams(ic, vap);

    /* First, clear Supported MCS fields. Default to max 1 tx spatial stream */
    rx_mcs[IEEE80211_TX_MCS_OFFSET] &= ~IEEE80211_TX_MCS_SET;

    /* Set Tx MCS Set Defined */
    rx_mcs[IEEE80211_TX_MCS_OFFSET] |= IEEE80211_TX_MCS_SET_DEFINED;

    if (tx_streams != rx_streams) {
        /* Tx MCS Set != Rx MCS Set */
        rx_mcs[IEEE80211_TX_MCS_OFFSET] |= IEEE80211_TX_RX_MCS_SET_NOT_EQUAL;

        switch(tx_streams) {
        case 2:
            rx_mcs[IEEE80211_TX_MCS_OFFSET] |= IEEE80211_TX_2_SPATIAL_STREAMS;
            break;
        case 3:
            rx_mcs[IEEE80211_TX_MCS_OFFSET] |= IEEE80211_TX_3_SPATIAL_STREAMS;
            break;
        case 4:
            rx_mcs[IEEE80211_TX_MCS_OFFSET] |= IEEE80211_TX_4_SPATIAL_STREAMS;
            break;
        }
    }

    /* REVISIT: update bitmask if/when going to > 3 streams */
    switch (rx_streams) {
    default:
        /* Default to single stream */
    case 1:
        /* Advertise all single spatial stream (0-7) mcs rates */
        rx_mcs[IEEE80211_RX_MCS_1_STREAM_BYTE_OFFSET] = IEEE80211_RX_MCS_ALL_NSTREAM_RATES;
        break;
    case 2:
        /* Advertise all single & dual spatial stream mcs rates (0-15) */
        rx_mcs[IEEE80211_RX_MCS_1_STREAM_BYTE_OFFSET] = IEEE80211_RX_MCS_ALL_NSTREAM_RATES;
        rx_mcs[IEEE80211_RX_MCS_2_STREAM_BYTE_OFFSET] = IEEE80211_RX_MCS_ALL_NSTREAM_RATES;
        break;
    case 3:
        /* Advertise all single, dual & triple spatial stream mcs rates (0-23) */
        rx_mcs[IEEE80211_RX_MCS_1_STREAM_BYTE_OFFSET] = IEEE80211_RX_MCS_ALL_NSTREAM_RATES;
        rx_mcs[IEEE80211_RX_MCS_2_STREAM_BYTE_OFFSET] = IEEE80211_RX_MCS_ALL_NSTREAM_RATES;
        rx_mcs[IEEE80211_RX_MCS_3_STREAM_BYTE_OFFSET] = IEEE80211_RX_MCS_ALL_NSTREAM_RATES;
        break;
    }
}

/*
 * Add ht basic rates to HT element.
 */
static void
ieee80211_set_basic_htrates(u_int8_t *frm, const struct ieee80211_rateset *rs)
{
    int i;
    int nrates;

    nrates = rs->rs_nrates;
    if (nrates > IEEE80211_HT_RATE_SIZE)
        nrates = IEEE80211_HT_RATE_SIZE;

    /* set the mcs bit mask from the rates */
    for (i=0; i < nrates; i++) {
        if ((i < IEEE80211_RATE_MAXSIZE) &&
            (rs->rs_rates[i] & IEEE80211_RATE_BASIC))
            *(frm + IEEE80211_RV(rs->rs_rates[i]) / 8) |= 1 << (IEEE80211_RV(rs->rs_rates[i]) % 8);
    }
}

/*
 * Add 802.11n HT Capabilities IE
 */
static void
ieee80211_add_htcap_cmn(struct ieee80211_node *ni, struct ieee80211_ie_htcap_cmn *ie, u_int8_t subtype)
{
    struct ieee80211com       *ic = ni->ni_ic;
    struct ieee80211vap       *vap = ni->ni_vap;
    u_int16_t                 htcap, hc_extcap = 0;
    u_int8_t                  noht40 = 0;
    u_int32_t rx_streams = ieee80211_get_rxstreams(ic, vap);
    u_int32_t tx_streams = ieee80211_get_txstreams(ic, vap);

    /*
     * XXX : Temporarily overide the shortgi based on the htflags,
     * fix this later
     */
    htcap = ic->ic_htcap;
    htcap &= ((ic->ic_htflags & IEEE80211_HTF_SHORTGI40) ?
                                 ic->ic_htcap  : ~IEEE80211_HTCAP_C_SHORTGI40);
    htcap &= ((ic->ic_htflags & IEEE80211_HTF_SHORTGI20) ?
                                 ic->ic_htcap  : ~IEEE80211_HTCAP_C_SHORTGI20);

    htcap &= (vap->iv_ldpc ? ic->ic_htcap : ~IEEE80211_HTCAP_C_ADVCODING);
    /*
     * Adjust the TX and RX STBC fields based on the chainmask and configuration
     */
    htcap &= (((vap->iv_tx_stbc) && (tx_streams > 1)) ? ic->ic_htcap : ~IEEE80211_HTCAP_C_TXSTBC);
    htcap &= (((vap->iv_rx_stbc) && (rx_streams > 0)) ? ic->ic_htcap : ~IEEE80211_HTCAP_C_RXSTBC);

    /* Bug Fix: EV 76451: Traffic between TDLS Stations also uses 
     * legacy rates when connected to Rootap in legacy mode.
     * Enabling HT flags for TDLS node
     */
    if (IEEE80211_IS_TDLS_NODE(ni)) {
        htcap |= ni->ni_htcap;
        ni->ni_htcap = htcap;
    }

    /* If bss/regulatory does not allow HT40, turn off HT40 capability */
    if (!(IEEE80211_IS_CHAN_11N_HT40(vap->iv_bsschan)) &&
        !(IEEE80211_IS_CHAN_11AC_VHT40(vap->iv_bsschan)) && 
        !(IEEE80211_IS_CHAN_11AC_VHT80(vap->iv_bsschan))) {
        noht40 = 1;

        /* Don't advertize any HT40 Channel width capability bit */
        htcap &= ~IEEE80211_HTCAP_C_CHWIDTH40;
    }

    if (IEEE80211_IS_CHAN_11NA(vap->iv_bsschan)) {
        htcap &= ~IEEE80211_HTCAP_C_DSSSCCK40;
    }
     
    /* Should we advertize HT40 capability on 2.4GHz channels? */
    if (IEEE80211_IS_CHAN_11NG(vap->iv_bsschan)) {
        if (subtype == IEEE80211_FC0_SUBTYPE_PROBE_REQ) {
            noht40 = 1;
        } else if (!ic->ic_enable2GHzHt40Cap ||
                   !(ni->ni_htcap & IEEE80211_HTCAP_C_CHWIDTH40))
        {
            noht40 = 1;
        }
        if(!ic->ic_enable2GHzHt40Cap)
            htcap &= ~IEEE80211_HTCAP_C_CHWIDTH40;
    }

    if (noht40) {
        /* Don't advertize any HT40 capability bits */
        htcap &= ~(IEEE80211_HTCAP_C_DSSSCCK40 |
                   IEEE80211_HTCAP_C_SHORTGI40);
    }


    if (!ieee80211_vap_dynamic_mimo_ps_is_set(ni->ni_vap)) {
        /* Don't advertise Dynamic MIMO power save if not configured */
        htcap &= ~IEEE80211_HTCAP_C_SMPOWERSAVE_DYNAMIC;
        htcap |= IEEE80211_HTCAP_C_SM_ENABLED;
    }

    /* Set support for 20/40 Coexistence Management frame support */
    htcap |= (vap->iv_ht40_intolerant) ? IEEE80211_HTCAP_C_INTOLERANT40 : 0;

    ie->hc_cap = htole16(htcap);
    
    if (IEEE80211_IS_TDLS_NODE(ni)) {
        htcap |= ni->ni_htcap;
        ie->hc_cap = htole16(htcap);
    }

    ie->hc_maxampdu	= ic->ic_maxampdu;
    ie->hc_mpdudensity = ic->ic_mpdudensity;
    ie->hc_reserved	= 0;

    /* Initialize the MCS bitmask */
    OS_MEMZERO(ie->hc_mcsset, sizeof(ie->hc_mcsset));

    /* Set supported MCS set */
    ieee80211_set_htrates(vap, ie->hc_mcsset, ic);
    if(IEEE80211_VAP_IS_PRIVACY_ENABLED(vap) && 
            (RSN_CIPHER_IS_WEP(&vap->iv_rsn)
             || (RSN_CIPHER_IS_TKIP(&vap->iv_rsn) && (!RSN_CIPHER_IS_CCMP(&vap->iv_rsn))))) {
        /* 
         * WAR for Tx FIFO underruns with MCS15 in WEP mode. Exclude
         * MCS15 from rates if WEP encryption is set in HT20 mode 
         */
        if (IEEE80211_IS_CHAN_11N_HT20(vap->iv_bsschan))
            ie->hc_mcsset[IEEE80211_RX_MCS_2_STREAM_BYTE_OFFSET] &= 0x7F;
    }


#ifdef ATH_SUPPORT_TxBF
    ic->ic_set_txbf_caps(ic);       /* update txbf cap*/
    ie->hc_txbf.value = htole32(ic->ic_txbf.value);

    /* disable TxBF mode for SoftAP mode of win7*/
    if (vap->iv_opmode == IEEE80211_M_HOSTAP){
        if(vap->iv_txbfmode == 0 ){
            ie->hc_txbf.value = 0;
        }
    }
    if (ie->hc_txbf.value!=0) {
        hc_extcap |= IEEE80211_HTCAP_EXTC_HTC_SUPPORT;    /*enable +HTC support*/
    }
#else
    ie->hc_txbf    = 0;
#endif
    ie->hc_extcap  = htole16(hc_extcap);
    ie->hc_antenna = 0;
}

u_int8_t *
ieee80211_add_htcap(u_int8_t *frm, struct ieee80211_node *ni, u_int8_t subtype)
{
    struct ieee80211_ie_htcap_cmn *ie;
    int htcaplen;
    struct ieee80211_ie_htcap *htcap = (struct ieee80211_ie_htcap *)frm;

    htcap->hc_id      = IEEE80211_ELEMID_HTCAP_ANA;
    htcap->hc_len     = sizeof(struct ieee80211_ie_htcap) - 2;

    ie = &htcap->hc_ie;
    htcaplen = sizeof(struct ieee80211_ie_htcap);

    ieee80211_add_htcap_cmn(ni, ie, subtype);

    return frm + htcaplen;
}

u_int8_t *
ieee80211_add_htcap_pre_ana(u_int8_t *frm, struct ieee80211_node *ni,u_int8_t subtype)
{
    struct ieee80211_ie_htcap_cmn *ie;
    int htcaplen;
    struct ieee80211_ie_htcap *htcap = (struct ieee80211_ie_htcap *)frm;

    htcap->hc_id      = IEEE80211_ELEMID_HTCAP;
    htcap->hc_len     = sizeof(struct ieee80211_ie_htcap) - 2;

    ie = &htcap->hc_ie;
    htcaplen = sizeof(struct ieee80211_ie_htcap);

    ieee80211_add_htcap_cmn(ni, ie, subtype);

    return frm + htcaplen;
}

u_int8_t *
ieee80211_add_htcap_vendor_specific(u_int8_t *frm, struct ieee80211_node *ni,u_int8_t subtype)
{
    struct ieee80211_ie_htcap_cmn *ie;
    int htcaplen;
    struct vendor_ie_htcap *htcap = (struct vendor_ie_htcap *)frm;

    IEEE80211_DPRINTF(ni->ni_vap, IEEE80211_MSG_DEBUG, "%s: use HT caps IE vendor specific\n",
                      __func__);

    htcap->hc_id      = IEEE80211_ELEMID_VENDOR;
    htcap->hc_oui[0]  = (ATH_HTOUI >> 16) & 0xff;
    htcap->hc_oui[1]  = (ATH_HTOUI >>  8) & 0xff;
    htcap->hc_oui[2]  = ATH_HTOUI & 0xff;
    htcap->hc_ouitype = IEEE80211_ELEMID_HTCAP;
    htcap->hc_len     = sizeof(struct vendor_ie_htcap) - 2;

    ie = &htcap->hc_ie;
    htcaplen = sizeof(struct vendor_ie_htcap);

    ieee80211_add_htcap_cmn(ni, ie,subtype);

    return frm + htcaplen;
}

/*
 * Add 802.11n HT Information IE
 */
/* NB: todo: still need to handle the case for when there may be non-HT STA's on channel (extension 
   and/or control) that are not a part of the BSS.  Process beacons for no HT IEs and
   process assoc-req for BS' other than our own */
void
ieee80211_update_htinfo_cmn(struct ieee80211_ie_htinfo_cmn *ie, struct ieee80211_node *ni)
{
    struct ieee80211com        *ic = ni->ni_ic;
    struct ieee80211vap *vap = ni->ni_vap;
    enum ieee80211_cwm_width ic_cw_width = ic->ic_cwm_get_width(ic);
    u_int8_t chwidth = 0;

    /*
     ** If the value in the VAP is set, we use that instead of the actual setting
     ** per Srini D.  Hopefully this matches the actual setting.
     */
    if( vap->iv_chwidth != IEEE80211_CWM_WIDTHINVALID) {
        chwidth = vap->iv_chwidth;
    } else {
        chwidth = ic_cw_width;
    }
    ie->hi_txchwidth = (chwidth == IEEE80211_CWM_WIDTH20) ?
        IEEE80211_HTINFO_TXWIDTH_20 : IEEE80211_HTINFO_TXWIDTH_2040;

    /*
     ** If the value in the VAP for the offset is set, use that per
     ** Srini D.  Otherwise, use the actual setting
     */

    if( vap->iv_chextoffset != 0 ) {
        switch( vap->iv_chextoffset ) {
            case 1:
                ie->hi_extchoff = IEEE80211_HTINFO_EXTOFFSET_NA;
                break;         
            case 2:
                ie->hi_extchoff =  IEEE80211_HTINFO_EXTOFFSET_ABOVE;
                break;
            case 3:
                ie->hi_extchoff =  IEEE80211_HTINFO_EXTOFFSET_BELOW;
                break;
            default:
                break;
        }
    } else {
        if ((ic_cw_width == IEEE80211_CWM_WIDTH40)||(ic_cw_width == IEEE80211_CWM_WIDTH80)) {
            switch (ic->ic_cwm_get_extoffset(ic)) {
                case 1:
                    ie->hi_extchoff = IEEE80211_HTINFO_EXTOFFSET_ABOVE;
                    break;
                case -1:
                    ie->hi_extchoff = IEEE80211_HTINFO_EXTOFFSET_BELOW;
                    break;
                case 0:
                default:
                    ie->hi_extchoff = IEEE80211_HTINFO_EXTOFFSET_NA;
            }
        } else {
            ie->hi_extchoff = IEEE80211_HTINFO_EXTOFFSET_NA;
        }
    }
    if (vap->iv_disable_HTProtection) {
        /* Force HT40: no HT protection*/
        ie->hi_opmode = IEEE80211_HTINFO_OPMODE_PURE;
        ie->hi_obssnonhtpresent=IEEE80211_HTINFO_OBSS_NONHT_NOT_PRESENT;
        ie->hi_rifsmode = IEEE80211_HTINFO_RIFSMODE_ALLOWED;
    }
    else if (ic->ic_sta_assoc > ic->ic_ht_sta_assoc) {
        /*
         * Legacy stations associated.
         */
        ie->hi_opmode =IEEE80211_HTINFO_OPMODE_MIXED_PROT_ALL;
        ie->hi_obssnonhtpresent = IEEE80211_HTINFO_OBSS_NONHT_PRESENT;
        ie->hi_rifsmode	= IEEE80211_HTINFO_RIFSMODE_PROHIBITED;
    }
    else if (ieee80211_ic_non_ht_ap_is_set(ic)) {
        /*
         * Overlapping with legacy BSSs.
         */
        ie->hi_opmode = IEEE80211_HTINFO_OPMODE_MIXED_PROT_OPT;
        ie->hi_obssnonhtpresent =IEEE80211_HTINFO_OBSS_NONHT_NOT_PRESENT;	
        ie->hi_rifsmode	= IEEE80211_HTINFO_RIFSMODE_PROHIBITED;
    }
    else if (ie->hi_txchwidth == IEEE80211_HTINFO_TXWIDTH_2040 && ic->ic_ht_sta_assoc > ic->ic_ht40_sta_assoc) {
        /* 
         * HT20 Stations present in HT40 BSS.
         */
        ie->hi_opmode = IEEE80211_HTINFO_OPMODE_MIXED_PROT_40;
        ie->hi_obssnonhtpresent = IEEE80211_HTINFO_OBSS_NONHT_NOT_PRESENT;
        ie->hi_rifsmode	= IEEE80211_HTINFO_RIFSMODE_ALLOWED;
    } else {
        /* 
         * all Stations are HT40 capable
         */
        ie->hi_opmode = IEEE80211_HTINFO_OPMODE_PURE;
        ie->hi_obssnonhtpresent=IEEE80211_HTINFO_OBSS_NONHT_NOT_PRESENT;
        ie->hi_rifsmode	= IEEE80211_HTINFO_RIFSMODE_ALLOWED;
    }

    if (vap->iv_opmode != IEEE80211_M_IBSS &&
                ic->ic_ht_sta_assoc > ic->ic_ht_gf_sta_assoc)
        ie->hi_nongfpresent = 1;
    else
        ie->hi_nongfpresent = 0;
}

static void
ieee80211_add_htinfo_cmn(struct ieee80211_node *ni, struct ieee80211_ie_htinfo_cmn *ie)
{
    struct ieee80211com        *ic = ni->ni_ic;
    struct ieee80211vap        *vap = ni->ni_vap;

    OS_MEMZERO(ie, sizeof(struct ieee80211_ie_htinfo_cmn));
    
    /* set control channel center in IE */
    ie->hi_ctrlchannel 	= ieee80211_chan2ieee(ic, vap->iv_bsschan);

    ieee80211_update_htinfo_cmn(ie,ni);
    /* Set the basic MCS Set */
    OS_MEMZERO(ie->hi_basicmcsset, sizeof(ie->hi_basicmcsset));
    ieee80211_set_basic_htrates(ie->hi_basicmcsset, &ni->ni_htrates);

    ieee80211_update_htinfo_cmn(ie, ni);        
}

u_int8_t *
ieee80211_add_htinfo(u_int8_t *frm, struct ieee80211_node *ni)
{
    struct ieee80211_ie_htinfo_cmn *ie;
    int htinfolen;
    struct ieee80211_ie_htinfo *htinfo = (struct ieee80211_ie_htinfo *)frm;

    htinfo->hi_id      = IEEE80211_ELEMID_HTINFO_ANA;
    htinfo->hi_len     = sizeof(struct ieee80211_ie_htinfo) - 2;

    ie = &htinfo->hi_ie;
    htinfolen = sizeof(struct ieee80211_ie_htinfo);

    ieee80211_add_htinfo_cmn(ni, ie);

    return frm + htinfolen;
}

u_int8_t *
ieee80211_add_htinfo_pre_ana(u_int8_t *frm, struct ieee80211_node *ni)
{
    struct ieee80211_ie_htinfo_cmn *ie;
    int htinfolen;
    struct ieee80211_ie_htinfo *htinfo = (struct ieee80211_ie_htinfo *)frm;

    htinfo->hi_id      = IEEE80211_ELEMID_HTINFO;
    htinfo->hi_len     = sizeof(struct ieee80211_ie_htinfo) - 2;

    ie = &htinfo->hi_ie;
    htinfolen = sizeof(struct ieee80211_ie_htinfo);

    ieee80211_add_htinfo_cmn(ni, ie);

    return frm + htinfolen;
}

u_int8_t *
ieee80211_add_htinfo_vendor_specific(u_int8_t *frm, struct ieee80211_node *ni)
{
    struct ieee80211_ie_htinfo_cmn *ie;
    int htinfolen;
    struct vendor_ie_htinfo *htinfo = (struct vendor_ie_htinfo *) frm;

    IEEE80211_DPRINTF(ni->ni_vap, IEEE80211_MSG_DEBUG, "%s: use HT info IE vendor specific\n",
                      __func__);

    htinfo->hi_id      = IEEE80211_ELEMID_VENDOR;
    htinfo->hi_oui[0]  = (ATH_HTOUI >> 16) & 0xff;
    htinfo->hi_oui[1]  = (ATH_HTOUI >>  8) & 0xff;
    htinfo->hi_oui[2]  = ATH_HTOUI & 0xff;
    htinfo->hi_ouitype = IEEE80211_ELEMID_HTINFO;
    htinfo->hi_len     = sizeof(struct vendor_ie_htinfo) - 2;

    ie = &htinfo->hi_ie;
    htinfolen = sizeof(struct vendor_ie_htinfo);

    ieee80211_add_htinfo_cmn(ni, ie);

    return frm + htinfolen;
}

/*
 * Add ext cap element.
 */
u_int8_t *
ieee80211_add_extcap(u_int8_t *frm,struct ieee80211_node *ni)
{
    struct ieee80211com *ic = ni->ni_ic;
    struct ieee80211vap *vap = ni->ni_vap;
    struct ieee80211_ie_ext_cap *ie = (struct ieee80211_ie_ext_cap *) frm;
    u_int32_t ext_capflags = 0;
    u_int32_t ext_capflags2 = 0;
    if (!(ic->ic_flags & IEEE80211_F_COEXT_DISABLE)) {
        ext_capflags |= IEEE80211_EXTCAPIE_2040COEXTMGMT;
    }
    ieee80211_wnm_add_extcap(ni, &ext_capflags);
    ieee80211tdls_add_extcap(ni, &ext_capflags);

#if UMAC_SUPPORT_PROXY_ARP
    if (ieee80211_vap_proxyarp_is_set(vap) &&
        vap->iv_opmode == IEEE80211_M_HOSTAP)
    {
        ext_capflags |= IEEE80211_EXTCAPIE_PROXYARP;
    }
#endif
#if ATH_SUPPORT_HS20
    if (vap->iv_hotspot_xcaps) {
        ext_capflags |= vap->iv_hotspot_xcaps;
    }
#endif
    
    if (vap->iv_ath_cap & IEEE80211_ATHC_TDLS) {
        ext_capflags2 |= IEEE80211_EXTCAPIE_TDLSSUPPORT;
    }
 
    /* Support reception of Operating Mode notification */
    ext_capflags2 |= IEEE80211_EXTCAPIE_OP_MODE_NOTIFY;

    if (ext_capflags || ext_capflags2) {
        OS_MEMSET(ie, 0, sizeof(struct ieee80211_ie_ext_cap));
        ie->elem_id = IEEE80211_ELEMID_XCAPS;
        ie->elem_len = sizeof(struct ieee80211_ie_ext_cap) - 2;
        ie->ext_capflags = htole32(ext_capflags);
        ie->ext_capflags2 = ext_capflags2;
        ie->ext_capflags2 = htole32(ext_capflags2);
        return frm + sizeof (struct ieee80211_ie_ext_cap);
    }
    else {
        return frm;
    }
}

/* 
 * Update overlapping bss scan element.
 */
void
ieee80211_update_obss_scan(struct ieee80211_ie_obss_scan *ie,
                           struct ieee80211_node *ni)
{
    struct ieee80211vap *vap = ni->ni_vap;
    
    if ( ie == NULL )
        return;

    ie->scan_interval = (vap->iv_chscaninit) ? 
          htole16(vap->iv_chscaninit):htole16(IEEE80211_OBSS_SCAN_INTERVAL_DEF);
}

/*
 * Add overlapping bss scan element.
 */
u_int8_t *
ieee80211_add_obss_scan(u_int8_t *frm, struct ieee80211_node *ni)
{
    struct ieee80211_ie_obss_scan *ie = (struct ieee80211_ie_obss_scan *) frm;

    OS_MEMSET(ie, 0, sizeof(struct ieee80211_ie_obss_scan));
    ie->elem_id = IEEE80211_ELEMID_OBSS_SCAN;
    ie->elem_len = sizeof(struct ieee80211_ie_obss_scan) - 2;
    ieee80211_update_obss_scan(ie, ni);
    ie->scan_passive_dwell = htole16(IEEE80211_OBSS_SCAN_PASSIVE_DWELL_DEF);
    ie->scan_active_dwell = htole16(IEEE80211_OBSS_SCAN_ACTIVE_DWELL_DEF);
    ie->scan_passive_total = htole16(IEEE80211_OBSS_SCAN_PASSIVE_TOTAL_DEF);
    ie->scan_active_total = htole16(IEEE80211_OBSS_SCAN_ACTIVE_TOTAL_DEF);
    ie->scan_thresh = htole16(IEEE80211_OBSS_SCAN_THRESH_DEF);
    ie->scan_delay = htole16(IEEE80211_OBSS_SCAN_DELAY_DEF);
    return frm + sizeof (struct ieee80211_ie_obss_scan);
}

/* 
 * routines to parse the IEs received from management frames.
 */
u_int32_t
ieee80211_parse_mpdudensity(u_int32_t mpdudensity)
{
    /*
     * 802.11n D2.0 defined values for "Minimum MPDU Start Spacing":
     *   0 for no restriction
     *   1 for 1/4 us
     *   2 for 1/2 us
     *   3 for 1 us
     *   4 for 2 us
     *   5 for 4 us
     *   6 for 8 us
     *   7 for 16 us
     */
    switch (mpdudensity) {
    case 0:
        return 0;
    case 1:
    case 2:
    case 3:
        /* Our lower layer calculations limit our precision to 1 microsecond */
        return 1;
    case 4:
        return 2;
    case 5:
        return 4;
    case 6:
        return 8;
    case 7:
        return 16;
    default:
        return 0;
    }
}

int 
ieee80211_parse_htcap(struct ieee80211_node *ni, u_int8_t *ie)
{
    struct ieee80211_ie_htcap_cmn *htcap = (struct ieee80211_ie_htcap_cmn *)ie;
    struct ieee80211com   *ic = ni->ni_ic;
    struct ieee80211vap   *vap = ni->ni_vap;
    u_int8_t rx_mcs;
    int                    htcapval, prev_htcap = ni->ni_htcap;
    u_int32_t rx_streams = ieee80211_get_rxstreams(ic, vap);
    u_int32_t tx_streams = ieee80211_get_txstreams(ic, vap);

    htcapval    = le16toh(htcap->hc_cap);
    rx_mcs = htcap->hc_mcsset[IEEE80211_TX_MCS_OFFSET]; 

    rx_mcs &= IEEE80211_TX_MCS_SET;

    if (rx_mcs & IEEE80211_TX_MCS_SET_DEFINED) {
        if( !(rx_mcs & IEEE80211_TX_RX_MCS_SET_NOT_EQUAL) &&
             (rx_mcs & (IEEE80211_TX_MAXIMUM_STREAMS_MASK |IEEE80211_TX_UNEQUAL_MODULATION_MASK  ))){
            return 0;
        }
    } else {
        if (rx_mcs & IEEE80211_TX_MCS_SET){
            return 0; 
        }
    }

    if (vap->iv_opmode == IEEE80211_M_HOSTAP) {
        /*
         * Check if SM powersav state changed.
         * prev_htcap == 0 => htcap set for the first time.
         */
        switch (htcapval & IEEE80211_HTCAP_C_SM_MASK) {
            case IEEE80211_HTCAP_C_SM_ENABLED:
                if (((ni->ni_htcap & IEEE80211_HTCAP_C_SM_MASK) != 
                     IEEE80211_HTCAP_C_SM_ENABLED) || !prev_htcap) {
                    /*
                     * Station just disabled SM Power Save therefore we can
                     * send to it at full SM/MIMO. 
                     */
                    ni->ni_htcap &= (~IEEE80211_HTCAP_C_SM_MASK);
                    ni->ni_htcap |= IEEE80211_HTCAP_C_SM_ENABLED;
                    ni->ni_updaterates = IEEE80211_NODE_SM_EN;
                    IEEE80211_DPRINTF(ni->ni_vap,IEEE80211_MSG_POWER,"%s:SM"
                                      " powersave disabled\n", __func__);
                }
                break;
            case IEEE80211_HTCAP_C_SMPOWERSAVE_STATIC:
                if (((ni->ni_htcap & IEEE80211_HTCAP_C_SM_MASK) != 
                     IEEE80211_HTCAP_C_SMPOWERSAVE_STATIC) || !prev_htcap) {
                    /* 
                     * Station just enabled static SM power save therefore
                     * we can only send to it at single-stream rates.
                     */
                    ni->ni_htcap &= (~IEEE80211_HTCAP_C_SM_MASK);
                    ni->ni_htcap |= IEEE80211_HTCAP_C_SMPOWERSAVE_STATIC;
                    ni->ni_updaterates = IEEE80211_NODE_SM_PWRSAV_STAT;
                    IEEE80211_DPRINTF(ni->ni_vap, IEEE80211_MSG_POWER,
                                      "%s:switching to static SM power save\n", __func__);
                }
                break;
            case IEEE80211_HTCAP_C_SMPOWERSAVE_DYNAMIC:
                if (((ni->ni_htcap & IEEE80211_HTCAP_C_SM_MASK) != 
                     IEEE80211_HTCAP_C_SMPOWERSAVE_DYNAMIC) || !prev_htcap) {
                    /* 
                     * Station just enabled dynamic SM power save therefore
                     * we should precede each packet we send to it with
                     * an RTS.
                     */
                    ni->ni_htcap &= (~IEEE80211_HTCAP_C_SM_MASK);
                    ni->ni_htcap |= IEEE80211_HTCAP_C_SMPOWERSAVE_DYNAMIC;
                    ni->ni_updaterates = IEEE80211_NODE_SM_PWRSAV_DYN;
                    IEEE80211_DPRINTF(ni->ni_vap,IEEE80211_MSG_POWER,
                                      "%s:switching to dynamic SM power save\n",__func__);
                }
        }
        IEEE80211_DPRINTF(ni->ni_vap,IEEE80211_MSG_POWER,
                          "%s:calculated updaterates %#x\n",__func__, ni->ni_updaterates);

        ni->ni_htcap = (htcapval & ~IEEE80211_HTCAP_C_SM_MASK) |
            (ni->ni_htcap & IEEE80211_HTCAP_C_SM_MASK);

        IEEE80211_DPRINTF(ni->ni_vap, IEEE80211_MSG_POWER, "%s: ni_htcap %#x\n",
                          __func__, ni->ni_htcap);

        if (htcapval & IEEE80211_HTCAP_C_GREENFIELD)
            ni->ni_htcap |= IEEE80211_HTCAP_C_GREENFIELD;
    } else {
        ni->ni_htcap = htcapval;
    }
    
    /* Bug Fix: EV 76451: Traffic between TDLS Stations also uses 
     * legacy rates when connected to Rootap in legacy mode.
     * Enabling HT flags for TDLS node
     */
    if (!IEEE80211_IS_TDLS_NODE(ni)) {
        if (ni->ni_htcap & IEEE80211_HTCAP_C_SHORTGI40)
            ni->ni_htcap  = ni->ni_htcap & ((ic->ic_htflags & IEEE80211_HTF_SHORTGI40) 
                                        ? ni->ni_htcap  : ~IEEE80211_HTCAP_C_SHORTGI40);
        if (ni->ni_htcap & IEEE80211_HTCAP_C_SHORTGI20)
            ni->ni_htcap  = ni->ni_htcap & ((ic->ic_htflags & IEEE80211_HTF_SHORTGI20) 
                                        ? ni->ni_htcap  : ~IEEE80211_HTCAP_C_SHORTGI20);
    }

    if (ni->ni_htcap & IEEE80211_HTCAP_C_ADVCODING) {
        ni->ni_htcap  = ni->ni_htcap & ((vap->iv_ldpc) ? ni->ni_htcap  : ~IEEE80211_HTCAP_C_ADVCODING);
    }

    if (ni->ni_htcap & IEEE80211_HTCAP_C_TXSTBC) {
        ni->ni_htcap  = ni->ni_htcap & (((vap->iv_rx_stbc) && (rx_streams > 1)) ? ni->ni_htcap : ~IEEE80211_HTCAP_C_TXSTBC);
    }

    /* Tx on our side and Rx on the remote side should be considered for STBC with rate control */
    if (ni->ni_htcap & IEEE80211_HTCAP_C_RXSTBC) {
        ni->ni_htcap  = ni->ni_htcap & (((vap->iv_tx_stbc) && (tx_streams > 1)) ? ni->ni_htcap : ~IEEE80211_HTCAP_C_RXSTBC);
    }

    /* Note: when 11ac is enabled the VHTCAP Channel width will override this */
    if (!(ni->ni_htcap & IEEE80211_HTCAP_C_CHWIDTH40)) {
        ni->ni_chwidth = IEEE80211_CWM_WIDTH20;
    } else {
        /* Channel width needs to be set to 40MHz for both 40MHz and 80MHz mode */
        if (ic->ic_cwm_get_width(ic) != IEEE80211_CWM_WIDTH20) {
            ni->ni_chwidth = IEEE80211_CWM_WIDTH40;
        }
    }

    if ((ni->ni_htcap & IEEE80211_HTCAP_C_INTOLERANT40) &&
        (IEEE80211_IS_CHAN_11N_HT40(vap->iv_bsschan))) {
        IEEE80211_DPRINTF(ni->ni_vap, IEEE80211_MSG_POWER, 
                 "%s: Received htcap with 40 intolerant bit set\n", __func__);
        ni->ni_flags |= IEEE80211_NODE_40_INTOLERANT;
    }

    /*
     * The Maximum Rx A-MPDU defined by this field is equal to
     *      (2^^(13 + Maximum Rx A-MPDU Factor)) - 1
     * octets.  Maximum Rx A-MPDU Factor is an integer in the
     * range 0 to 3.
     */

    ni->ni_maxampdu = ((1u << (IEEE80211_HTCAP_MAXRXAMPDU_FACTOR + htcap->hc_maxampdu)) - 1);
    ni->ni_mpdudensity = ieee80211_parse_mpdudensity(htcap->hc_mpdudensity);

    ni->ni_flags |= IEEE80211_NODE_HT;

#ifdef ATH_SUPPORT_TxBF
    ni->ni_mmss = htcap->hc_mpdudensity;
    ni->ni_txbf.value = le32toh(htcap->hc_txbf.value);
    //IEEE80211_DPRINTF(vap, IEEE80211_MSG_ANY,"==>%s:get remote txbf ie %x\n",__func__,ni->ni_txbf.value);
    ieee80211_match_txbfcapability(ic, ni);
    //IEEE80211_DPRINTF(vap, IEEE80211_MSG_ANY,"==>%s:final result Com ExBF %d, NonCOm ExBF %d, ImBf %d\n",
      //  __func__,ni->ni_explicit_compbf,ni->ni_explicit_noncompbf,ni->ni_implicit_bf );
#endif

    if (ic->ic_set_ampduparams) {
        /* Notify LMAC of the ampdu params */
        ic->ic_set_ampduparams(ni);
    }
    return 1;
}

void
ieee80211_parse_htinfo(struct ieee80211_node *ni, u_int8_t *ie)
{
    struct ieee80211_ie_htinfo_cmn  *htinfo = (struct ieee80211_ie_htinfo_cmn *)ie;
    enum ieee80211_cwm_width    chwidth;
    int8_t extoffset;

    switch(htinfo->hi_extchoff) {
    case IEEE80211_HTINFO_EXTOFFSET_ABOVE:
        extoffset = 1;
        break;
    case IEEE80211_HTINFO_EXTOFFSET_BELOW:
        extoffset = -1;
        break;
    case IEEE80211_HTINFO_EXTOFFSET_NA:
    default:
        extoffset = 0;
    }

    chwidth = IEEE80211_CWM_WIDTH20;
    if (extoffset && (htinfo->hi_txchwidth == IEEE80211_HTINFO_TXWIDTH_2040)) {
        chwidth = IEEE80211_CWM_WIDTH40;
    }

    /* update node's recommended tx channel width */
    ni->ni_chwidth = chwidth;

    /* update node's ext channel offset */
    ni->ni_extoffset = extoffset;

    /* update other HT information */
    ni->ni_obssnonhtpresent = htinfo->hi_obssnonhtpresent;
    ni->ni_txburstlimit     = htinfo->hi_txburstlimit;
    ni->ni_nongfpresent     = htinfo->hi_nongfpresent;
}

void
ieee80211_parse_vhtcap(struct ieee80211_node *ni, u_int8_t *ie)
{
    struct ieee80211_ie_vhtcap *vhtcap = (struct ieee80211_ie_vhtcap *)ie;
    struct ieee80211com  *ic = ni->ni_ic;
    struct ieee80211vap  *vap = ni->ni_vap;
    u_int32_t ampdu_len = 0;
    u_int8_t chwidth = 0;
    u_int32_t rx_streams = ieee80211_get_rxstreams(ic, vap);
    u_int32_t tx_streams = ieee80211_get_txstreams(ic, vap);

    /* Negotiated capability set */
    ni->ni_vhtcap = le32toh(vhtcap->vht_cap_info);
    if (ni->ni_vhtcap & IEEE80211_VHTCAP_SHORTGI_80) {
        ni->ni_vhtcap  = ni->ni_vhtcap & ((vap->iv_sgi) ? ni->ni_vhtcap  : ~IEEE80211_VHTCAP_SHORTGI_80);
    }
    if (ni->ni_vhtcap & IEEE80211_VHTCAP_RX_LDPC) {
        ni->ni_vhtcap  = ni->ni_vhtcap & ((vap->iv_ldpc) ? ni->ni_vhtcap  : ~IEEE80211_VHTCAP_RX_LDPC);
    }
    if (ni->ni_vhtcap & IEEE80211_VHTCAP_TX_STBC) {
        ni->ni_vhtcap  = ni->ni_vhtcap & (((vap->iv_rx_stbc) && (rx_streams > 1)) ? ni->ni_vhtcap : ~IEEE80211_VHTCAP_TX_STBC);
    }

    /* Tx on our side and Rx on the remote side should be considered for STBC with rate control */
    if (ni->ni_vhtcap & IEEE80211_VHTCAP_RX_STBC) {
        ni->ni_vhtcap  = ni->ni_vhtcap & (((vap->iv_tx_stbc) && (tx_streams > 1)) ? ni->ni_vhtcap : ~IEEE80211_VHTCAP_RX_STBC);
    }

    if (vap->iv_chwidth != IEEE80211_CWM_WIDTHINVALID) {
        chwidth = vap->iv_chwidth;
    } else {
        chwidth = ic->ic_cwm_get_width(ic);
    }

    if (vap->iv_opmode == IEEE80211_M_HOSTAP) {
        switch(chwidth) {
            case IEEE80211_CWM_WIDTH20:
                ni->ni_chwidth = IEEE80211_CWM_WIDTH20;
            break;

            case IEEE80211_CWM_WIDTH40:
                /* HTCAP Channelwidth will be set to max for VHT as well ? */
                if (!(ni->ni_htcap & IEEE80211_HTCAP_C_CHWIDTH40)) {
                    ni->ni_chwidth = IEEE80211_CWM_WIDTH20;
                } else {
                    ni->ni_chwidth = IEEE80211_CWM_WIDTH40;
                }
            break;

            case IEEE80211_CWM_WIDTH80:
                if (!(ni->ni_htcap & IEEE80211_HTCAP_C_CHWIDTH40)) {
                    ni->ni_chwidth = IEEE80211_CWM_WIDTH20;
                } else if (!(ni->ni_vhtcap)) {
                    ni->ni_chwidth = IEEE80211_CWM_WIDTH40;
                } else {
                    ni->ni_chwidth = IEEE80211_CWM_WIDTH80;
                }
            break;

            default:
                /* Do nothing */
            break;
        }
    }

    /*
     * The Maximum Rx A-MPDU defined by this field is equal to
     *   (2^^(13 + Maximum Rx A-MPDU Factor)) - 1
     * octets.  Maximum Rx A-MPDU Factor is an integer in the
     * range 0 to 7.
     */

    ampdu_len = (le32toh(vhtcap->vht_cap_info) & IEEE80211_VHTCAP_MAX_AMPDU_LEN_EXP) >> IEEE80211_VHTCAP_MAX_AMPDU_LEN_EXP_S;
    ni->ni_maxampdu = (1u << (IEEE80211_VHTCAP_MAX_AMPDU_LEN_FACTOR + ampdu_len)) -1;
    ni->ni_flags |= IEEE80211_NODE_VHT;
    ni->ni_tx_vhtrates = le16toh(vhtcap->tx_mcs_map);
    ni->ni_tx_max_rate = le16toh(vhtcap->tx_high_data_rate);
    ni->ni_rx_vhtrates = le16toh(vhtcap->rx_mcs_map);
    ni->ni_rx_max_rate = le16toh(vhtcap->rx_high_data_rate);
}

void
ieee80211_parse_vhtop(struct ieee80211_node *ni, u_int8_t *ie)
{
    struct ieee80211_ie_vhtop *vhtop = (struct ieee80211_ie_vhtop *)ie;

    switch (vhtop->vht_op_chwidth) {
       case IEEE80211_VHTOP_CHWIDTH_2040:
           /* Exact channel width is already taken care of by the HT parse */
       break;
       case IEEE80211_VHTOP_CHWIDTH_80:
           ni->ni_chwidth = IEEE80211_CWM_WIDTH80; 
       break;
       default:
           IEEE80211_DPRINTF(ni->ni_vap, IEEE80211_MSG_DEBUG,
                           "%s: Unsupported Channel Width\n", __func__);
       break;
    }

    ni->ni_vht_cfreq1 = vhtop->vht_op_ch_freq_seg1;
    ni->ni_vht_basic_mcs = le16toh(vhtop->vhtop_basic_mcs_set);
}

void
ieee80211_add_opmode(u_int8_t *frm, struct ieee80211_node *ni,
                    struct ieee80211com *ic,  u_int8_t subtype)
{
    struct ieee80211_ie_op_mode *opmode = (struct ieee80211_ie_op_mode *)frm;
    enum ieee80211_cwm_width ic_cw_width = ic->ic_cwm_get_width(ic);
    struct ieee80211vap *vap = ni->ni_vap;
    u_int8_t rx_streams = ieee80211_get_rxstreams(ic, vap);

    /* Fill in the Channel width */
    if (vap->iv_chwidth != IEEE80211_CWM_WIDTHINVALID) {
        opmode->ch_width = vap->iv_chwidth;
    } else {
        opmode->ch_width = ic_cw_width;
    }

    opmode->reserved = 0; 
    opmode->rx_nss_type = 0; /* No beamforming */
    opmode->rx_nss = (rx_streams -1); /* Supported RX streams */ 

}

u_int8_t *
ieee80211_add_opmode_notify(u_int8_t *frm, struct ieee80211_node *ni,
                    struct ieee80211com *ic,  u_int8_t subtype)
{
    struct ieee80211_ie_op_mode_ntfy *opmode = (struct ieee80211_ie_op_mode_ntfy *)frm;
    int opmode_notify_len = sizeof(struct ieee80211_ie_op_mode_ntfy);
    
    opmode->elem_id   = IEEE80211_ELEMID_OP_MODE_NOTIFY;
    opmode->elem_len  =  opmode_notify_len- 2;
    ieee80211_add_opmode((u_int8_t *)&opmode->opmode, ni, ic, subtype);
    return frm + opmode_notify_len;
}


void 
ieee80211_parse_opmode(struct ieee80211_node *ni, u_int8_t *ie, u_int8_t subtype)
{
    struct ieee80211_ie_op_mode *opmode = (struct ieee80211_ie_op_mode *)ie;
    struct ieee80211com  *ic = ni->ni_ic;
    u_int8_t tx_streams = ieee80211_get_txstreams(ic, ni->ni_vap);
    u_int8_t rx_nss = 0;

    /* Check whether this is a beamforming type */
    if (opmode->rx_nss_type == 1) {
        IEEE80211_DPRINTF(ni->ni_vap, IEEE80211_MSG_DEBUG,
                           "%s: Beamforming is unsupported\n", __func__);
        return;
    }

    if (opmode->ch_width != ni->ni_chwidth) {
        IEEE80211_DPRINTF(ni->ni_vap, IEEE80211_MSG_DEBUG,
            "%s: Bandwidth changed from %d to %d \n",
             __func__, ni->ni_chwidth, opmode->ch_width);
        switch (opmode->ch_width) {
            case 0:
                ni->ni_chwidth = IEEE80211_CWM_WIDTH20; 
            break;

            case 1:
                ni->ni_chwidth = IEEE80211_CWM_WIDTH40; 
            break;

            case 2:
                ni->ni_chwidth = IEEE80211_CWM_WIDTH80; 
            break;

            default:
                IEEE80211_DPRINTF(ni->ni_vap, IEEE80211_MSG_DEBUG,
                           "%s: Unsupported Channel Width\n", __func__);
                return;
            break;
        }

        if ((subtype != IEEE80211_FC0_SUBTYPE_ASSOC_RESP) &&
            (subtype != IEEE80211_FC0_SUBTYPE_REASSOC_RESP) &&
            (subtype != IEEE80211_FC0_SUBTYPE_REASSOC_REQ) &&
            (subtype != IEEE80211_FC0_SUBTYPE_ASSOC_REQ)) {
            ic->ic_chwidth_change(ni);
        }
    }

    /* Propagate the number of Spatial streams to the target */
    rx_nss = opmode->rx_nss + 1;
    if ((rx_nss != ni->ni_streams) && (rx_nss <= tx_streams)) {
        IEEE80211_DPRINTF(ni->ni_vap, IEEE80211_MSG_DEBUG,
             "%s: NSS changed from %d to %d \n", __func__, ni->ni_streams, opmode->rx_nss);
       ni->ni_streams = rx_nss;
        if ((subtype != IEEE80211_FC0_SUBTYPE_ASSOC_RESP) &&
            (subtype != IEEE80211_FC0_SUBTYPE_REASSOC_RESP) &&
            (subtype != IEEE80211_FC0_SUBTYPE_REASSOC_REQ) &&
            (subtype != IEEE80211_FC0_SUBTYPE_ASSOC_REQ)) {
            ic->ic_nss_change(ni);
        }
       return;
    }
}

void
ieee80211_parse_opmode_notify(struct ieee80211_node *ni, u_int8_t *ie, u_int8_t subtype)
{
    struct ieee80211_ie_op_mode_ntfy *opmode = (struct ieee80211_ie_op_mode_ntfy *)ie;
    ieee80211_parse_opmode(ni, (u_int8_t *)&opmode->opmode, subtype);
}

int
ieee80211_parse_dothparams(struct ieee80211vap *vap, u_int8_t *frm)
{
    struct ieee80211com *ic = vap->iv_ic;
    u_int len = frm[1];
    u_int8_t chan, tbtt;

    if (len < 4-2) {        /* XXX ie struct definition */
        IEEE80211_DISCARD_IE(vap,
                             IEEE80211_MSG_ELEMID | IEEE80211_MSG_DOTH,
                             "channel switch", "too short, len %u", len);
        return -1;
    }
    chan = frm[3];
    if (isclr(ic->ic_chan_avail, chan)) {
        IEEE80211_DISCARD_IE(vap,
                             IEEE80211_MSG_ELEMID | IEEE80211_MSG_DOTH,
                             "channel switch", "invalid channel %u", chan);
        return -1;
    }
    tbtt = frm[4];
    IEEE80211_DPRINTF(vap, IEEE80211_MSG_DOTH,
                      "%s: channel switch to %d in %d tbtt\n", __func__, chan, tbtt);
    if (tbtt <= 1) {
        struct ieee80211_channel *c;

        IEEE80211_DPRINTF(vap, IEEE80211_MSG_DOTH,
                          "%s: Channel switch to %d NOW!\n", __func__, chan);
        if ((c = ieee80211_doth_findchan(vap, chan)) == NULL) {
            /* XXX something wrong */
            IEEE80211_DISCARD_IE(vap,
                                 IEEE80211_MSG_ELEMID | IEEE80211_MSG_DOTH,
                                 "channel switch",
                                 "channel %u lookup failed", chan);
            return 0;
        }
        vap->iv_bsschan = c;
        ieee80211_set_channel(ic, c);
        return 1;
    }
    return 0;
}

int
ieee80211_parse_wmeparams(struct ieee80211vap *vap, u_int8_t *frm,
                          u_int8_t *qosinfo, int forced_update)
{
#define MS(_v, _f)  (((_v) & _f) >> _f##_S)
    struct ieee80211_wme_state *wme = &vap->iv_ic->ic_wme;
    u_int len = frm[1], qosinfo_count;
    int i;

    *qosinfo = 0;

    if (len < sizeof(struct ieee80211_wme_param) - 2) {
        /* XXX: TODO msg+stats */
        return -1;
    }

    *qosinfo = frm[__offsetof(struct ieee80211_wme_param, param_qosInfo)];
    qosinfo_count = *qosinfo & WME_QOSINFO_COUNT;

    if (!forced_update) {

   	 /* XXX do proper check for wraparound */
    	if (qosinfo_count == (wme->wme_wmeChanParams.cap_info & WME_QOSINFO_COUNT))
        	return 0;
    }

    frm += __offsetof(struct ieee80211_wme_param, params_acParams);
    for (i = 0; i < WME_NUM_AC; i++) {
        struct wmeParams *wmep =
            &wme->wme_wmeChanParams.cap_wmeParams[i];
        /* NB: ACI not used */
        wmep->wmep_acm = MS(frm[0], WME_PARAM_ACM);
        wmep->wmep_aifsn = MS(frm[0], WME_PARAM_AIFSN);
        wmep->wmep_logcwmin = MS(frm[1], WME_PARAM_LOGCWMIN);
        wmep->wmep_logcwmax = MS(frm[1], WME_PARAM_LOGCWMAX);
        wmep->wmep_txopLimit = LE_READ_2(frm+2);
        frm += 4;
    }
    wme->wme_wmeChanParams.cap_info = *qosinfo;

    return 1;
#undef MS
}

int
ieee80211_parse_wmeinfo(struct ieee80211vap *vap, u_int8_t *frm,
                        u_int8_t *qosinfo)
{
    struct ieee80211_wme_state *wme = &vap->iv_ic->ic_wme;
    u_int len = frm[1], qosinfo_count;

    *qosinfo = 0;

    if (len < sizeof(struct ieee80211_ie_wme) - 2) {
        /* XXX: TODO msg+stats */
        return -1;
    }

    *qosinfo = frm[__offsetof(struct ieee80211_wme_param, param_qosInfo)];
    qosinfo_count = *qosinfo & WME_QOSINFO_COUNT;

    /* XXX do proper check for wraparound */
    if (qosinfo_count == (wme->wme_wmeChanParams.cap_info & WME_QOSINFO_COUNT))
        return 0;

    wme->wme_wmeChanParams.cap_info = *qosinfo;

    return 1;
}

int
ieee80211_parse_tspecparams(struct ieee80211vap *vap, u_int8_t *frm)
{
    struct ieee80211_tsinfo_bitmap *tsinfo;

    tsinfo = (struct ieee80211_tsinfo_bitmap *) &((struct ieee80211_wme_tspec *) frm)->ts_tsinfo[0];

    if (tsinfo->tid == 6)
        OS_MEMCPY(&vap->iv_ic->ic_sigtspec, frm, sizeof(struct ieee80211_wme_tspec));
    else
        OS_MEMCPY(&vap->iv_ic->ic_datatspec, frm, sizeof(struct ieee80211_wme_tspec));

    return 1;
}

/*
 * used by STA when it receives a (RE)ASSOC rsp.
 */
int
ieee80211_parse_timeieparams(struct ieee80211vap *vap, u_int8_t *frm)
{
    struct ieee80211_ie_timeout_interval *tieinfo;

    tieinfo = (struct ieee80211_ie_timeout_interval *) frm;

    if (tieinfo->interval_type == IEEE80211_TIE_INTERVAL_TYPE_ASSOC_COMEBACK_TIME)
        vap->iv_assoc_comeback_time = tieinfo->value;
    else
        vap->iv_assoc_comeback_time = 0;

    return 1;
}

/*
 * used by HOST AP when it receives a (RE)ASSOC req.
 */
int
ieee80211_parse_wmeie(u_int8_t *frm, const struct ieee80211_frame *wh, 
                      struct ieee80211_node *ni)
{
    u_int len = frm[1];
    u_int8_t ac;

    if (len != 7) {
        IEEE80211_DISCARD_IE(ni->ni_vap,
            IEEE80211_MSG_ELEMID | IEEE80211_MSG_WME,
            "WME IE", "too short, len %u", len);
        return -1;
    }
    ni->ni_uapsd = frm[WME_CAPINFO_IE_OFFSET];
    if (ni->ni_uapsd) {
        ieee80211node_set_flag(ni, IEEE80211_NODE_UAPSD);
        switch (WME_UAPSD_MAXSP(ni->ni_uapsd)) {
        case 1:
            ni->ni_uapsd_maxsp = 2;
            break;
        case 2:
            ni->ni_uapsd_maxsp = 4;
            break;
        case 3:
            ni->ni_uapsd_maxsp = 6;
            break;
        default:
            ni->ni_uapsd_maxsp = WME_UAPSD_NODE_MAXQDEPTH;
        }
        for (ac = 0; ac < WME_NUM_AC; ac++) {
            ni->ni_uapsd_ac_trigena[ac] = (WME_UAPSD_AC_ENABLED(ac, ni->ni_uapsd)) ? 1:0;
            ni->ni_uapsd_ac_delivena[ac] = (WME_UAPSD_AC_ENABLED(ac, ni->ni_uapsd)) ? 1:0;
        }
    } else {
        ieee80211node_clear_flag(ni, IEEE80211_NODE_UAPSD);
    }

    IEEE80211_NOTE(ni->ni_vap, IEEE80211_MSG_POWER, ni,
        "UAPSD bit settings from STA: %02x", ni->ni_uapsd);

    return 1;
}

/*
 * Convert a WPA cipher selector OUI to an internal
 * cipher algorithm.  Where appropriate we also
 * record any key length.
 */
static int
wpa_cipher(u_int8_t *sel, u_int8_t *keylen)
{
    u_int32_t w = LE_READ_4(sel);

    switch (w)
    {
    case WPA_SEL(WPA_CSE_NULL):
        return IEEE80211_CIPHER_NONE;
    case WPA_SEL(WPA_CSE_WEP40):
        if (keylen)
            *keylen = 40 / NBBY;
        return IEEE80211_CIPHER_WEP;
    case WPA_SEL(WPA_CSE_WEP104):
        if (keylen)
            *keylen = 104 / NBBY;
        return IEEE80211_CIPHER_WEP;
    case WPA_SEL(WPA_CSE_TKIP):
        return IEEE80211_CIPHER_TKIP;
    case WPA_SEL(WPA_CSE_CCMP):
        return IEEE80211_CIPHER_AES_CCM;
    }
    return 32;      /* NB: so 1<< is discarded */
}

/*
 * Convert a WPA key management/authentication algorithm
 * to an internal code.
 */
static int
wpa_keymgmt(u_int8_t *sel)
{
    u_int32_t w = LE_READ_4(sel);

    switch (w)
    {
    case WPA_SEL(WPA_ASE_8021X_UNSPEC):
        return WPA_ASE_8021X_UNSPEC;
    case WPA_SEL(WPA_ASE_8021X_PSK):
        return WPA_ASE_8021X_PSK;
    case WPA_SEL(WPA_ASE_NONE):
        return WPA_ASE_NONE;
    case CCKM_SEL(CCKM_ASE_UNSPEC):
        return WPA_CCKM_AKM;
    }
    return 0;       /* NB: so is discarded */
}

/*
 * Parse a WPA information element to collect parameters
 * and validate the parameters against what has been
 * configured for the system.
 */
int
ieee80211_parse_wpa(struct ieee80211vap *vap, u_int8_t *frm,
                    struct ieee80211_rsnparms *rsn)
{
    u_int8_t len = frm[1];
    u_int32_t w;
    int n;

    /*
     * Check the length once for fixed parts: OUI, type,
     * version, mcast cipher, and 2 selector counts.
     * Other, variable-length data, must be checked separately.
     */
    RSN_RESET_AUTHMODE(rsn);
    RSN_SET_AUTHMODE(rsn, IEEE80211_AUTH_WPA);
    
    if (len < 14) {
        IEEE80211_DISCARD_IE(vap,
            IEEE80211_MSG_ELEMID | IEEE80211_MSG_WPA,
            "WPA", "too short, len %u", len);
        return IEEE80211_REASON_IE_INVALID;
    }
    frm += 6, len -= 4;     /* NB: len is payload only */
    /* NB: iswapoui already validated the OUI and type */
    w = LE_READ_2(frm);
    if (w != WPA_VERSION) {
        IEEE80211_DISCARD_IE(vap,
            IEEE80211_MSG_ELEMID | IEEE80211_MSG_WPA,
            "WPA", "bad version %u", w);
        return IEEE80211_REASON_IE_INVALID;
    }
    frm += 2, len -= 2;

    /* multicast/group cipher */
    RSN_RESET_MCAST_CIPHERS(rsn);
    w = wpa_cipher(frm, &rsn->rsn_mcastkeylen);
    RSN_SET_MCAST_CIPHER(rsn, w);
    frm += 4, len -= 4;

    /* unicast ciphers */
    n = LE_READ_2(frm);
    frm += 2, len -= 2;
    if (len < n*4+2) {
        IEEE80211_DISCARD_IE(vap,
            IEEE80211_MSG_ELEMID | IEEE80211_MSG_WPA,
            "WPA", "ucast cipher data too short; len %u, n %u",
            len, n);
        return IEEE80211_REASON_IE_INVALID;
    }

    RSN_RESET_UCAST_CIPHERS(rsn);
    for (; n > 0; n--) {
        RSN_SET_UCAST_CIPHER(rsn, wpa_cipher(frm, &rsn->rsn_ucastkeylen));
        frm += 4, len -= 4;
    }

    if (rsn->rsn_ucastcipherset == 0) {
        IEEE80211_DISCARD_IE(vap,
            IEEE80211_MSG_ELEMID | IEEE80211_MSG_WPA,
            "WPA", "%s", "ucast cipher set empty");
        return IEEE80211_REASON_IE_INVALID;
    }

    /* key management algorithms */
    n = LE_READ_2(frm);
    frm += 2, len -= 2;
    if (len < n*4) {
        IEEE80211_DISCARD_IE(vap,
            IEEE80211_MSG_ELEMID | IEEE80211_MSG_WPA,
            "WPA", "key mgmt alg data too short; len %u, n %u",
            len, n);
        return IEEE80211_REASON_IE_INVALID;
    }
    w = 0;
    rsn->rsn_keymgmtset = 0;
    for (; n > 0; n--) {
        w = wpa_keymgmt(frm);
        if (w == WPA_CCKM_AKM) { /* CCKM AKM */
            RSN_SET_AUTHMODE(rsn, IEEE80211_AUTH_CCKM);
            // when AuthMode is CCKM we don't need keymgmtset
            // as AuthMode drives the AKM_CCKM in WPA/RSNIE
            //rsn->rsn_keymgmtset |= 0;
        }
        else
            rsn->rsn_keymgmtset |= (w&0xff);
        frm += 4, len -= 4;
    }

    /* optional capabilities */
    if (len >= 2) {
        rsn->rsn_caps = LE_READ_2(frm);
        frm += 2, len -= 2;
    }

    return 0;
}

/*
 * Convert an RSN cipher selector OUI to an internal
 * cipher algorithm.  Where appropriate we also
 * record any key length.
 */
static int
rsn_cipher(u_int8_t *sel, u_int8_t *keylen)
{
#define RSN_SEL(x)  (((x)<<24)|RSN_OUI)
    u_int32_t w = LE_READ_4(sel);

    switch (w)
    {
    case RSN_SEL(RSN_CSE_NULL):
        return IEEE80211_CIPHER_NONE;
    case RSN_SEL(RSN_CSE_WEP40):
        if (keylen)
            *keylen = 40 / NBBY;
        return IEEE80211_CIPHER_WEP;
    case RSN_SEL(RSN_CSE_WEP104):
        if (keylen)
            *keylen = 104 / NBBY;
        return IEEE80211_CIPHER_WEP;
    case RSN_SEL(RSN_CSE_TKIP):
        return IEEE80211_CIPHER_TKIP;
    case RSN_SEL(RSN_CSE_CCMP):
        return IEEE80211_CIPHER_AES_CCM;
    case RSN_SEL(RSN_CSE_WRAP):
        return IEEE80211_CIPHER_AES_OCB;
    case RSN_SEL(RSN_CSE_AES_CMAC):
        return IEEE80211_CIPHER_AES_CMAC;
    }
    return 32;      /* NB: so 1<< is discarded */
#undef RSN_SEL
}

/*
 * Convert an RSN key management/authentication algorithm
 * to an internal code.
 */
static int
rsn_keymgmt(u_int8_t *sel)
{
#define RSN_SEL(x)  (((x)<<24)|RSN_OUI)
    u_int32_t w = LE_READ_4(sel);

    switch (w)
    {
    case RSN_SEL(RSN_ASE_8021X_UNSPEC):
        return RSN_ASE_8021X_UNSPEC;
    case RSN_SEL(RSN_ASE_8021X_PSK):
        return RSN_ASE_8021X_PSK;
    case RSN_SEL(RSN_ASE_NONE):
        return RSN_ASE_NONE;
    case RSN_SEL(AKM_SUITE_TYPE_SHA256_IEEE8021X):
        return RSN_ASE_SHA256_IEEE8021X;
    case RSN_SEL(AKM_SUITE_TYPE_SHA256_PSK):
        return RSN_ASE_SHA256_PSK;
    case CCKM_SEL(CCKM_ASE_UNSPEC):
        return RSN_CCKM_AKM;
    }
    return 0;       /* NB: so is discarded */
#undef RSN_SEL
}

/*
 * Parse a WPA/RSN information element to collect parameters
 * and validate the parameters against what has been
 * configured for the system.
 */
int
ieee80211_parse_rsn(struct ieee80211vap *vap, u_int8_t *frm,
                    struct ieee80211_rsnparms *rsn)
{
    u_int8_t len = frm[1];
    u_int32_t w;
    int n;

    /*
    * Check the length once for fixed parts:
    * version, mcast cipher, and 2 selector counts.
    * Other, variable-length data, must be checked separately.
    */
    RSN_RESET_AUTHMODE(rsn);
    RSN_SET_AUTHMODE(rsn, IEEE80211_AUTH_RSNA);

    if (len < 10) {
        IEEE80211_DISCARD_IE(vap,
            IEEE80211_MSG_ELEMID | IEEE80211_MSG_WPA,
            "RSN", "too short, len %u", len);
        return IEEE80211_REASON_IE_INVALID;
    }
    frm += 2;
    w = LE_READ_2(frm);
    if (w != RSN_VERSION) {
        IEEE80211_DISCARD_IE(vap,
            IEEE80211_MSG_ELEMID | IEEE80211_MSG_WPA,
            "RSN", "bad version %u", w);
        return IEEE80211_REASON_IE_INVALID;
    }
    frm += 2, len -= 2;

    /* multicast/group cipher */
    RSN_RESET_MCAST_CIPHERS(rsn);
    w = rsn_cipher(frm, &rsn->rsn_mcastkeylen);
    RSN_SET_MCAST_CIPHER(rsn, w);
    frm += 4, len -= 4;

    /* unicast ciphers */
    n = LE_READ_2(frm);
    frm += 2, len -= 2;
    if (len < n*4+2) {
        IEEE80211_DISCARD_IE(vap,
            IEEE80211_MSG_ELEMID | IEEE80211_MSG_WPA,
            "RSN", "ucast cipher data too short; len %u, n %u",
            len, n);
        return IEEE80211_REASON_IE_INVALID;
    }
    
    RSN_RESET_UCAST_CIPHERS(rsn);
    for (; n > 0; n--) {
        RSN_SET_UCAST_CIPHER(rsn, rsn_cipher(frm, &rsn->rsn_ucastkeylen));
        frm += 4, len -= 4;
    }

    if (rsn->rsn_ucastcipherset == 0) {
        IEEE80211_DISCARD_IE(vap,
            IEEE80211_MSG_ELEMID | IEEE80211_MSG_WPA,
            "RSN", "%s", "ucast cipher set empty");
        return IEEE80211_REASON_IE_INVALID;
    }

    /* key management algorithms */
    n = LE_READ_2(frm);
    frm += 2, len -= 2;
    if (len < n*4) {
        IEEE80211_DISCARD_IE(vap,
            IEEE80211_MSG_ELEMID | IEEE80211_MSG_WPA,
            "RSN", "key mgmt alg data too short; len %u, n %u",
            len, n);
        return IEEE80211_REASON_IE_INVALID;
    }
    w = 0;
    rsn->rsn_keymgmtset = 0;
    for (; n > 0; n--) {
        w = rsn_keymgmt(frm);
        if (w == RSN_CCKM_AKM) { /* CCKM AKM */
            RSN_SET_AUTHMODE(rsn, IEEE80211_AUTH_CCKM);
            // when AuthMode is CCKM we don't need keymgmtset
            // as AuthMode drives the AKM_CCKM in WPA/RSNIE
            //rsn->rsn_keymgmtset |= 0;
        }
        else
            rsn->rsn_keymgmtset = w;
        frm += 4, len -= 4;
    }

    /* optional RSN capabilities */
    if (len >= 2) {
        rsn->rsn_caps = LE_READ_2(frm);
        frm += 2, len -= 2;
        if((rsn->rsn_caps & RSN_CAP_MFP_ENABLED) || (rsn->rsn_caps & RSN_CAP_MFP_REQUIRED)){
            RSN_RESET_MCASTMGMT_CIPHERS(rsn);
            w = IEEE80211_CIPHER_AES_CMAC;
            RSN_SET_MCASTMGMT_CIPHER(rsn, w);
        }
    }

    /* optional XXXPMKID */
    if (len >= 2) {
        n = LE_READ_2(frm);
        frm += 2, len -= 2;
        /* Skip them */		
        if (len < n*16) {
            IEEE80211_DISCARD_IE(vap,
                IEEE80211_MSG_ELEMID | IEEE80211_MSG_WPA,
                "RSN", "key mgmt OMKID data too short; len %u, n %u",
                len, n);
            return IEEE80211_REASON_IE_INVALID;
        }
        frm += n * 16, len -= n * 16;
    }

    /* optional multicast/group management frame cipher */
    if (len >= 4) {
        RSN_RESET_MCASTMGMT_CIPHERS(rsn);
        w = rsn_cipher(frm, NULL);
        if(w != IEEE80211_CIPHER_AES_CMAC) {
            IEEE80211_DISCARD_IE(vap,
                IEEE80211_MSG_ELEMID | IEEE80211_MSG_WPA,
                "RSN", "invalid multicast/group management frame cipher; len %u, n %u",
                len, n);
            return IEEE80211_REASON_IE_INVALID;
        }
        RSN_SET_MCASTMGMT_CIPHER(rsn, w);
        frm += 4, len -= 4;
    }

    return IEEE80211_STATUS_SUCCESS;
}

void
ieee80211_savenie(osdev_t osdev,u_int8_t **iep, const u_int8_t *ie, u_int ielen)
{
    /*
    * Record information element for later use.
    */
    if (*iep == NULL || (*iep)[1] != ie[1])
    {
        if (*iep != NULL)
            OS_FREE(*iep);
		*iep = (void *) OS_MALLOC(osdev, ielen, GFP_KERNEL);
    }
    if (*iep != NULL)
        OS_MEMCPY(*iep, ie, ielen);
}

void
ieee80211_saveie(osdev_t osdev,u_int8_t **iep, const u_int8_t *ie)
{
    u_int ielen = ie[1]+2;
    ieee80211_savenie(osdev,iep, ie, ielen);
}

void
ieee80211_process_extcap(struct ieee80211_node *ni, u_int8_t *ie) 
{   
    /* Check for TDLS support in driver */
    if (IEEE80211_TDLS_ENABLED(ni->ni_vap)) {            
        u_int32_t extcap = 0;
        
        if (ni == NULL || ie == NULL) {
            return;
        }

        extcap = LE_READ_4(ie);
        
        ieee80211tdls_process_extcap_ie(ni, extcap);     
    }
    
    return; 
}

/*  ieee80211_process_extcap_ie; is used to extact TDLS specific bit masks
 *  and store in ni 
 *  TODO: General extcaps needs to stored in ni if needed.
 */
void
ieee80211_process_extcap_ie(struct ieee80211_node *ni, u_int8_t *ie) 
{   
    struct ieee80211_ie_ext_cap *extcapie  = (struct ieee80211_ie_ext_cap *) ie;
    u_int32_t flags=0;
    
    if (extcapie->elem_len >= 5 )
    {
         flags = extcapie->ext_capflags2;
         if (flags&IEEE80211_EXTCAPIE_TDLSPROHIBIT)
         {
            ni->ni_tdls_caps |= IEEE80211_TDLS_PROHIBIT;
         }else
            ni->ni_tdls_caps &= ~(IEEE80211_TDLS_PROHIBIT);
         if (flags & IEEE80211_EXTCAPIE_TDLSCHANSXPROHIBIT) {
             ni->ni_tdls_caps |= IEEE80211_TDLS_CHAN_SX_PROHIBIT;
         }
         else {
             ni->ni_tdls_caps &= ~(IEEE80211_TDLS_CHAN_SX_PROHIBIT);
         }
     }
     else
     {   /* TODO: Add other caps related to TDLS*/
            ni->ni_tdls_caps &= ~(IEEE80211_TDLS_PROHIBIT);
            ni->ni_tdls_caps &= ~(IEEE80211_TDLS_CHAN_SX_PROHIBIT);
     }
    return; 
}

void
ieee80211_process_athextcap_ie(struct ieee80211_node *ni, u_int8_t *ie)
{
    struct ieee80211_ie_ath_extcap *athextcapIe =
        (struct ieee80211_ie_ath_extcap *) ie;
    u_int16_t remote_extcap = athextcapIe->ath_extcap_extcap;

    remote_extcap = LE_READ_2(&remote_extcap);

    /* We know remote node is an Atheros Owl or follow-on device */
    ni->ni_flags |= IEEE80211_NODE_ATH;

    /* If either one of us is capable of OWL WDS workaround,
     * implement WDS mode block-ack corruption workaround
     */
    if (remote_extcap & IEEE80211_ATHEC_OWLWDSWAR) {
        ni->ni_flags |= IEEE80211_NODE_OWL_WDSWAR;
    }

    /* If device and remote node support the Atheros proprietary 
     * wep/tkip aggregation mode, mark node as supporting
     * wep/tkip w/aggregation.
     * Save off the number of rx delimiters required by the destination to
     * properly receive tkip/wep with aggregation.
     */
    if (remote_extcap & IEEE80211_ATHEC_WEPTKIPAGGR) {
        ni->ni_flags |= IEEE80211_NODE_WEPTKIPAGGR;
        ni->ni_weptkipaggr_rxdelim = athextcapIe->ath_extcap_weptkipaggr_rxdelim;
    }
    /* Check if remote device, require extra delimiters to be added while
     * sending aggregates. Osprey 1.0 and earlier chips need this.
     */
    if (remote_extcap & IEEE80211_ATHEC_EXTRADELIMWAR) {
        ni->ni_flags |= IEEE80211_NODE_EXTRADELIMWAR;
    }

}

void
ieee80211_parse_athParams(struct ieee80211_node *ni, u_int8_t *ie)
{
    struct ieee80211vap *vap = ni->ni_vap;
    struct ieee80211com *ic = ni->ni_ic;
    struct ieee80211_ie_athAdvCap *athIe =
            (struct ieee80211_ie_athAdvCap *) ie;

    (void)vap;
    (void)ic;

    ni->ni_ath_flags = athIe->athAdvCap_capability;
    if (ni->ni_ath_flags & IEEE80211_ATHC_COMP)
        ni->ni_ath_defkeyindex = LE_READ_2(&athIe->athAdvCap_defKeyIndex);
}

/*support for WAPI: parse WAPI IE*/
#if ATH_SUPPORT_WAPI
/*
 * Convert an WAPI cipher selector OUI to an internal
 * cipher algorithm.  Where appropriate we also
 * record any key length.
 */
static int
wapi_cipher(u_int8_t *sel, u_int8_t *keylen)
{
#define	WAPI_SEL(x)	(((x)<<24)|WAPI_OUI)
	u_int32_t w = LE_READ_4(sel);

	switch (w) {
	case WAPI_SEL(RSN_CSE_NULL):
		return IEEE80211_CIPHER_NONE;
	case WAPI_SEL(WAPI_CSE_WPI_SMS4):
		if (keylen)
			*keylen = 128 / NBBY;
		return IEEE80211_CIPHER_WAPI;
	}
	return 32;		/* NB: so 1<< is discarded */
#undef WAPI_SEL
}

/*
 * Convert an RSN key management/authentication algorithm
 * to an internal code.
 */
static int
wapi_keymgmt(u_int8_t *sel)
{
#define	WAPI_SEL(x)	(((x)<<24)|WAPI_OUI)
	u_int32_t w = LE_READ_4(sel);

	switch (w) {
	case WAPI_SEL(WAPI_ASE_WAI_UNSPEC):
		return WAPI_ASE_WAI_UNSPEC;
	case WAPI_SEL(WAPI_ASE_WAI_PSK):
		return WAPI_ASE_WAI_PSK;
	case WAPI_SEL(WAPI_ASE_NONE):
		return WAPI_ASE_NONE;
	}
	return 0;		/* NB: so is discarded */
#undef WAPI_SEL
}

/*
 * Parse a WAPI information element to collect parameters
 * and validate the parameters against what has been
 * configured for the system.
 */
int
ieee80211_parse_wapi(struct ieee80211vap *vap, u_int8_t *frm, 
	struct ieee80211_rsnparms *rsn)
{
	u_int8_t len = frm[1];
	u_int32_t w;
	int n;

	/*
	 * Check the length once for fixed parts: 
	 * version, mcast cipher, and 2 selector counts.
	 * Other, variable-length data, must be checked separately.
	 */
    RSN_RESET_AUTHMODE(rsn);
    RSN_SET_AUTHMODE(rsn, IEEE80211_AUTH_WAPI);

	if (!ieee80211_vap_wapi_is_set(vap)) {
		IEEE80211_DISCARD_IE(vap,
		    IEEE80211_MSG_ELEMID | IEEE80211_MSG_WPA,
		    "WAPI", "vap not WAPI, flags 0x%x", vap->iv_flags);
		return IEEE80211_REASON_IE_INVALID;
	}
	 
	if (len < 20) {
		IEEE80211_DISCARD_IE(vap,
		    IEEE80211_MSG_ELEMID | IEEE80211_MSG_WPA,
		    "WAPI", "too short, len %u", len);
		return IEEE80211_REASON_IE_INVALID;
	}
	frm += 2;
	w = LE_READ_2(frm);
	if (w != WAPI_VERSION) {
		IEEE80211_DISCARD_IE(vap,
		    IEEE80211_MSG_ELEMID | IEEE80211_MSG_WPA,
		    "WAPI", "bad version %u", w);
		return IEEE80211_REASON_IE_INVALID;
	}
	frm += 2, len -= 2;
	
	/* key management algorithms */
	n = LE_READ_2(frm);
	frm += 2, len -= 2;
	if (len < n*4) {
		IEEE80211_DISCARD_IE(vap, 
		    IEEE80211_MSG_ELEMID | IEEE80211_MSG_WPA,
		    "WAPI", "key mgmt alg data too short; len %u, n %u",
		    len, n);
		return IEEE80211_REASON_IE_INVALID;
	}
	w = 0;
	for (; n > 0; n--) {
		w |= wapi_keymgmt(frm);
		frm += 4, len -= 4;
	}
	if (w == 0) {
		IEEE80211_DISCARD_IE(vap,
		    IEEE80211_MSG_ELEMID | IEEE80211_MSG_WPA,
		    "WAPI", "%s", "no acceptable key mgmt alg");
		return IEEE80211_REASON_IE_INVALID;
		
	}
    rsn->rsn_keymgmtset = w & WAPI_ASE_WAI_AUTO;

	/* unicast ciphers */
	n = LE_READ_2(frm);
	frm += 2, len -= 2;
	if (len < n*4+2) {
		IEEE80211_DISCARD_IE(vap,
		    IEEE80211_MSG_ELEMID | IEEE80211_MSG_WPA,
		    "WAPI", "ucast cipher data too short; len %u, n %u",
		    len, n);
		return IEEE80211_REASON_IE_INVALID;
	}
	w = 0;
    RSN_RESET_UCAST_CIPHERS(rsn);
	for (; n > 0; n--) {
		w |= 1<<wapi_cipher(frm, &rsn->rsn_ucastkeylen);
		frm += 4, len -= 4;
	}
	if (w == 0) {
		IEEE80211_DISCARD_IE(vap,
		    IEEE80211_MSG_ELEMID | IEEE80211_MSG_WPA,
		    "WAPI", "%s", "ucast cipher set empty");
		return IEEE80211_REASON_IE_INVALID;
	}
	if (w & (1<<IEEE80211_CIPHER_WAPI))
		RSN_SET_UCAST_CIPHER(rsn, IEEE80211_CIPHER_WAPI);
	else
		RSN_SET_UCAST_CIPHER(rsn, IEEE80211_CIPHER_WAPI);

	/* multicast/group cipher */
    RSN_RESET_MCAST_CIPHERS(rsn);
	w = wapi_cipher(frm, &rsn->rsn_mcastkeylen);
    RSN_SET_MCAST_CIPHER(rsn, w);
	if (!RSN_HAS_MCAST_CIPHER(rsn, IEEE80211_CIPHER_WAPI)) {
		IEEE80211_DISCARD_IE(vap,
		    IEEE80211_MSG_ELEMID | IEEE80211_MSG_WPA,
		    "WAPI", "mcast cipher mismatch; got %u, expected %u",
		    w, IEEE80211_CIPHER_WAPI);
		return IEEE80211_REASON_IE_INVALID;
	}
	frm += 4, len -= 4;


	/* optional RSN capabilities */
	if (len > 2)
		rsn->rsn_caps = LE_READ_2(frm);
	/* XXXPMKID */

	return 0;
}
#endif /*ATH_SUPPORT_WAPI*/

static int
ieee80211_query_ie(struct ieee80211vap *vap, u_int8_t *frm)
{
    switch (*frm) {
        case IEEE80211_ELEMID_RSN:
            if ((frm[1] + 2) < IEEE80211_RSN_IE_LEN) {
                return -EOVERFLOW;
            }
            ieee80211_setup_rsn_ie(vap, frm);
            break;
        default:
            break;
    }
    return EOK;
}

int
wlan_get_ie(wlan_if_t vaphandle, u_int8_t *frm)
{
    return ieee80211_query_ie(vaphandle, frm);
}

static int
ieee80211_parse_csa_ecsa_ie(
    u_int8_t * pucInfoBlob,
    u_int32_t uSizeOfBlob,
    u_int8_t ucInfoId,
    u_int8_t * pucLength,
    u_int8_t ** ppvInfoEle
    )
{
    int status = IEEE80211_STATUS_SUCCESS;
    struct ieee80211_ie_header * pInfoEleHdr = NULL;
    u_int32_t uRequiredSize = 0;
    bool bFound = FALSE;

    *pucLength = 0;
    *ppvInfoEle = NULL;
    while(uSizeOfBlob) {

        pInfoEleHdr = (struct ieee80211_ie_header *)pucInfoBlob;
        if (uSizeOfBlob < sizeof(struct ieee80211_ie_header)) {
            break;
        }

        uRequiredSize = (u_int32_t)(pInfoEleHdr->length) + sizeof(struct ieee80211_ie_header);
        if (uSizeOfBlob < uRequiredSize) {
            break;
        }

        if (pInfoEleHdr->element_id == ucInfoId) {
            *pucLength = pInfoEleHdr->length;
            *ppvInfoEle = pucInfoBlob + sizeof(struct ieee80211_ie_header);
            bFound = TRUE;
            break;
        }

        uSizeOfBlob -= uRequiredSize;
        pucInfoBlob += uRequiredSize;
    }

    if (!bFound) {
        status = IEEE80211_REASON_IE_INVALID;
    }
    return status;
}

struct ieee80211_channel *
ieee80211_get_new_sw_chan (
    struct ieee80211_node                       *ni,
    struct ieee80211_channelswitch_ie           *chanie,
    struct ieee80211_extendedchannelswitch_ie   *echanie,
    struct ieee80211_ie_sec_chan_offset         *secchanoffsetie,
    struct ieee80211_ie_wide_bw_switch         *widebwie,
    u_int8_t *cswarp
    )
{
    struct ieee80211_channel *chan;
    struct ieee80211com *ic = ni->ni_ic;
    enum ieee80211_phymode phymode = IEEE80211_MODE_AUTO;
    enum ieee80211_cwm_width new_chwidth = IEEE80211_CWM_WIDTH20;
    u_int8_t    secchanoffset = 0;
    u_int8_t    newchannel = 0;

   if(chanie) {
        newchannel = chanie->newchannel;
        IEEE80211_DPRINTF(ni->ni_vap, IEEE80211_MSG_DEBUG,
            "%s: CSA new channel = %d\n",
             __func__, chanie->newchannel);
    } else if (echanie) {
        newchannel = echanie->newchannel;
        IEEE80211_DPRINTF(ni->ni_vap, IEEE80211_MSG_DEBUG,
            "%s: E-CSA new channel = %d\n",
             __func__, echanie->newchannel);
    }


   if(widebwie) {
        IEEE80211_DPRINTF(ni->ni_vap, IEEE80211_MSG_DEBUG,
            "%s: wide bandwidth changed new vht chwidth = %d\n",
             __func__, widebwie->new_ch_width);
    }
    if(secchanoffsetie) {
        secchanoffset = secchanoffsetie->sec_chan_offset; 
        IEEE80211_DPRINTF(ni->ni_vap, IEEE80211_MSG_DEBUG,
            "%s: HT bandwidth changed new secondary channel offset = %d\n",
             __func__, secchanoffsetie->sec_chan_offset);
    }

    if(newchannel > 20) { // 5G channel

        if(cswarp && !widebwie) {  //20 bandwidth
            if (IEEE80211_SUPPORT_PHY_MODE(ic, IEEE80211_MODE_11AC_VHT20)) {
                    phymode = IEEE80211_MODE_11AC_VHT20;
            }
            else if (IEEE80211_SUPPORT_PHY_MODE(ic, IEEE80211_MODE_11NA_HT20)) {
                    phymode = IEEE80211_MODE_11NA_HT20;
            } else {
                    phymode = IEEE80211_MODE_11A;
            }
        }
        else if (widebwie &&
            (IEEE80211_SUPPORT_PHY_MODE(ic, IEEE80211_MODE_11AC_VHT20) ||
            IEEE80211_SUPPORT_PHY_MODE(ic, IEEE80211_MODE_11AC_VHT40) ||
            IEEE80211_SUPPORT_PHY_MODE(ic, IEEE80211_MODE_11AC_VHT40PLUS) ||
            IEEE80211_SUPPORT_PHY_MODE(ic, IEEE80211_MODE_11AC_VHT40MINUS) ||                
            IEEE80211_SUPPORT_PHY_MODE(ic, IEEE80211_MODE_11AC_VHT80))) {

            switch (widebwie->new_ch_width) {
                case IEEE80211_VHTOP_CHWIDTH_2040 :
                    if (secchanoffsetie) {
                        if ((secchanoffset == IEEE80211_SEC_CHAN_OFFSET_SCA) &&
                            (IEEE80211_SUPPORT_PHY_MODE(ic, IEEE80211_MODE_11AC_VHT40PLUS) ||
                            IEEE80211_SUPPORT_PHY_MODE(ic, IEEE80211_MODE_11AC_VHT40))) {
                                phymode = IEEE80211_MODE_11AC_VHT40PLUS;
                        } else if ((secchanoffset == IEEE80211_SEC_CHAN_OFFSET_SCB) &&
                            (IEEE80211_SUPPORT_PHY_MODE(ic, IEEE80211_MODE_11AC_VHT40MINUS) ||
                            IEEE80211_SUPPORT_PHY_MODE(ic, IEEE80211_MODE_11AC_VHT40))) {
                                phymode = IEEE80211_MODE_11AC_VHT40MINUS;
                        } else {
                                phymode = IEEE80211_MODE_11AC_VHT20;
                        }
                    } else if (IEEE80211_SUPPORT_PHY_MODE(ic, IEEE80211_MODE_11AC_VHT40) ||
                            IEEE80211_SUPPORT_PHY_MODE(ic, IEEE80211_MODE_11AC_VHT40PLUS) ||
                            IEEE80211_SUPPORT_PHY_MODE(ic,  IEEE80211_MODE_11AC_VHT40MINUS)) {
                        phymode = IEEE80211_MODE_11AC_VHT40;                          
                    } 
                    else {
                        phymode = IEEE80211_MODE_11AC_VHT20;
                    }
                break;
                case IEEE80211_VHTOP_CHWIDTH_80 :
                    if (IEEE80211_SUPPORT_PHY_MODE(ic, IEEE80211_MODE_11AC_VHT80)) {
                        phymode = IEEE80211_MODE_11AC_VHT80;
                    } else if (IEEE80211_SUPPORT_PHY_MODE(ic, IEEE80211_MODE_11AC_VHT40)) {
                        phymode = IEEE80211_MODE_11AC_VHT40;
                    } else {
                        phymode = IEEE80211_MODE_11AC_VHT20;
                    }
                break;

                default:
                    phymode = IEEE80211_MODE_11AC_VHT20;
                    IEEE80211_DPRINTF_IC(ic, IEEE80211_VERBOSE_LOUD, IEEE80211_MSG_DEBUG,
                               "%s : Received Bad Chwidth", __func__);
                break;
                } 
        } else if (secchanoffsetie) {
            if((secchanoffset == IEEE80211_SEC_CHAN_OFFSET_SCA) &&
                IEEE80211_SUPPORT_PHY_MODE(ic, IEEE80211_MODE_11NA_HT40PLUS)) {
                    phymode = IEEE80211_MODE_11NA_HT40PLUS;
            } else if ((secchanoffset == IEEE80211_SEC_CHAN_OFFSET_SCB) &&
                IEEE80211_SUPPORT_PHY_MODE(ic, IEEE80211_MODE_11NA_HT40MINUS)) {
                    phymode = IEEE80211_MODE_11NA_HT40MINUS;
            } else if (IEEE80211_SUPPORT_PHY_MODE(ic, IEEE80211_MODE_11NA_HT20)) {
                    phymode = IEEE80211_MODE_11NA_HT20;
            } else {
                    phymode = IEEE80211_MODE_11A;
            }
        } else {
            phymode = IEEE80211_MODE_11A;
        }
    } else {  //2.4 G channel
        /* Check for HT capability only if we as well support HT mode */
        if (secchanoffsetie) {
            if ((secchanoffset == IEEE80211_SEC_CHAN_OFFSET_SCA) &&
                IEEE80211_SUPPORT_PHY_MODE(ic, IEEE80211_MODE_11NG_HT40PLUS)) {
                    phymode = IEEE80211_MODE_11NG_HT40PLUS;
            } else if ((secchanoffset == IEEE80211_SEC_CHAN_OFFSET_SCB) &&
                       IEEE80211_SUPPORT_PHY_MODE(ic, IEEE80211_MODE_11NG_HT40MINUS)) {
                    phymode = IEEE80211_MODE_11NG_HT40MINUS;
            } else if (IEEE80211_SUPPORT_PHY_MODE(ic, IEEE80211_MODE_11NG_HT20)) {
                    phymode = IEEE80211_MODE_11NG_HT20;
            } else if (IEEE80211_SUPPORT_PHY_MODE(ic, IEEE80211_MODE_11G)){
                    phymode = IEEE80211_MODE_11G;
            } else {
                    phymode = IEEE80211_MODE_11B;
            }
        } else {
            /*
             * XXX: This is probably the most reliable way to tell the difference
             * between 11g and 11b beacons.
             */
            if (IEEE80211_SUPPORT_PHY_MODE(ic, IEEE80211_MODE_11G)) {
                phymode = IEEE80211_MODE_11G;
            } else {
                phymode = IEEE80211_MODE_11B;
            }
        }
    }
       
    chan  =  ieee80211_find_dot11_channel(ic, newchannel, phymode);
    
    if (!chan)
        return chan;

    if (chan->ic_flags & IEEE80211_CHAN_VHT80) {
        new_chwidth = IEEE80211_CWM_WIDTH80;
    }
    else if (chan->ic_flags & (IEEE80211_CHAN_HT40PLUS | IEEE80211_CHAN_HT40MINUS
        | IEEE80211_CHAN_VHT40PLUS | IEEE80211_CHAN_VHT40MINUS)) {
        new_chwidth = IEEE80211_CWM_WIDTH40;
    }
    else if (chan->ic_flags & (IEEE80211_CHAN_TURBO | IEEE80211_CHAN_CCK |IEEE80211_CHAN_OFDM | IEEE80211_CHAN_DYN
        | IEEE80211_CHAN_GFSK | IEEE80211_CHAN_STURBO | IEEE80211_CHAN_HALF | IEEE80211_CHAN_QUARTER
        | IEEE80211_CHAN_HT20 | IEEE80211_CHAN_VHT20)) {
        new_chwidth = IEEE80211_CWM_WIDTH20;
    } 

    ic->ic_chanchange_chwidth = new_chwidth;

   return chan;
}

/* Process CSA/ECSA IE and switch to new announced channel */
int
ieee80211_process_csa_ecsa_ie (
    struct ieee80211_node *ni, 
   struct ieee80211_action * pia 
    )
{
    struct ieee80211_extendedchannelswitch_ie * pecsaIe = NULL;
    struct ieee80211_channelswitch_ie * pcsaIe = NULL;
    struct ieee80211_ie_sec_chan_offset *psecchanoffsetIe = NULL;
    struct ieee80211_ie_wide_bw_switch  *pwidebwie = NULL;
    u_int8_t *cswarp = NULL;


    struct ieee80211vap *vap = ni->ni_vap;
     struct ieee80211com *ic = ni->ni_ic;

    struct ieee80211_channel* chan = NULL;
    
    u_int8_t * ptmp1 = NULL;
    u_int8_t * ptmp2 = NULL;
    u_int8_t size;
    int      err = (-EINVAL);

    ASSERT(pia);

    if(!(ic->ic_flags_ext & IEEE80211_FEXT_MARKDFS)){
        return EOK; 
        /*Returning EOK to make sure that we dont get disconnect from AP */
    }
    ptmp1 = (u_int8_t *)pia+sizeof(struct ieee80211_action);

    /*Find CSA/ECSA IE*/
    if (ieee80211_parse_csa_ecsa_ie((u_int8_t *)ptmp1,
                        sizeof(struct ieee80211_channelswitch_ie),
                        IEEE80211_ELEMID_CHANSWITCHANN,
                        &size,
                        (u_int8_t **)&ptmp2) == IEEE80211_STATUS_SUCCESS)
    {
           ptmp2 -= sizeof(struct ieee80211_ie_header);
           pcsaIe = (struct ieee80211_channelswitch_ie * )ptmp2 ;
    }
    
    if (ieee80211_parse_csa_ecsa_ie((u_int8_t *)ptmp1,
                        sizeof(struct ieee80211_extendedchannelswitch_ie),
                        IEEE80211_ELEMID_EXTCHANSWITCHANN,
                        &size,
                        (u_int8_t **)&ptmp2) == IEEE80211_STATUS_SUCCESS)
    {
        ptmp2 -= sizeof(struct ieee80211_ie_header);
        pecsaIe = (struct ieee80211_extendedchannelswitch_ie * )ptmp2 ;
    }

    if (ieee80211_parse_csa_ecsa_ie((u_int8_t *)ptmp1,
                        sizeof(struct ieee80211_ie_sec_chan_offset),
                        IEEE80211_ELEMID_SECCHANOFFSET,
                        &size,
                        (u_int8_t **)&ptmp2) == IEEE80211_STATUS_SUCCESS)
    {
        ptmp2 -= sizeof(struct ieee80211_ie_header);
        psecchanoffsetIe = (struct ieee80211_ie_sec_chan_offset * )ptmp2 ;
    }

    if (ieee80211_parse_csa_ecsa_ie((u_int8_t *)ptmp1,
                        sizeof(struct ieee80211_ie_wide_bw_switch),
                        IEEE80211_ELEMID_WIDE_BAND_CHAN_SWITCH,
                        &size,
                        (u_int8_t **)&ptmp2) == IEEE80211_STATUS_SUCCESS)
    {
        ptmp2 -= sizeof(struct ieee80211_channelswitch_ie);
        pwidebwie = (struct ieee80211_ie_wide_bw_switch * )ptmp2 ;
    }

    chan = ieee80211_get_new_sw_chan (ni, pcsaIe, pecsaIe, psecchanoffsetIe, pwidebwie, cswarp);

    if(!chan)
        return EOK;

     /*
     * Set or clear flag indicating reception of channel switch announcement
     * in this channel. This flag should be set before notifying the scan 
     * algorithm.
     * We should not send probe requests on a channel on which CSA was 
     * received until we receive another beacon without the said flag.
     */
    if ((pcsaIe != NULL) || (pecsaIe != NULL)) {
        ic->ic_curchan->ic_flagext |= IEEE80211_CHAN_CSA_RECEIVED;
    }

#if ATH_SUPPORT_IBSS_DFS
    /* only support pcsaIe for now */
    if (vap->iv_opmode == IEEE80211_M_IBSS &&
        chan &&
        pcsaIe) {

        if(ieee80211_dfs_action(vap, pcsaIe)) {
            err = EOK;
        }        
        
    } else if (chan) {
#else
    if (chan) {
#endif /* ATH_SUPPORT_IBSS_DFS */
        /*
         * For Station, just switch channel right away.
         */
        if (!IEEE80211_IS_RADAR_ENABLED(ic) &&
            (chan != vap->iv_bsschan))
        {
            IEEE80211_ENABLE_RADAR(ic);
            ni->ni_chanswitch_tbtt = pcsaIe ? pcsaIe->tbttcount : pecsaIe->tbttcount;
            
                    /*
             * Issue a channel switch request to resource manager.
             * If the function returns EOK (0) then its ok to change the channel synchronously
             * If the function returns EBUSY then resource manager will 
             * switch channel asynchronously and post an event event handler registred by vap and
             * vap handler will inturn do the rest of the processing involved. 
                     */
            err = ieee80211_resmgr_request_chanswitch(ic->ic_resmgr, vap, chan, MLME_REQ_ID);

            if (err == EOK) {
                err = ieee80211_set_channel(ic, chan);

                ieee80211_mlme_chanswitch_continue(ni, err);
            } else if (err == EBUSY) {
                err = EOK;
            }
        }
    }
    IEEE80211_NOTE(vap, IEEE80211_MSG_ACTION, ni,
                   "%s: Exited.\n",__func__
                   );

    return err;
}

#if ATH_SUPPORT_IBSS_DFS

static int
ieee80211_validate_ie(
    u_int8_t * pucInfoBlob,
    u_int32_t uSizeOfBlob,
    u_int8_t ucInfoId,
    u_int8_t * pucLength,
    u_int8_t ** ppvInfoEle
    )
{
    int status = IEEE80211_STATUS_SUCCESS;
    struct ieee80211_ie_header * pInfoEleHdr = NULL;
    u_int32_t uRequiredSize = 0;
    bool bFound = FALSE;

    *pucLength = 0;
    *ppvInfoEle = NULL;
    while(uSizeOfBlob) {

        pInfoEleHdr = (struct ieee80211_ie_header *)pucInfoBlob;
        if (uSizeOfBlob < sizeof(struct ieee80211_ie_header)) {
            break;
        }

        uRequiredSize = (u_int32_t)(pInfoEleHdr->length) + sizeof(struct ieee80211_ie_header);
        if (uSizeOfBlob < uRequiredSize) {
            break;
        }

        if (pInfoEleHdr->element_id == ucInfoId) {
            *pucLength = pInfoEleHdr->length;
            *ppvInfoEle = pucInfoBlob + sizeof(struct ieee80211_ie_header);
            bFound = TRUE;
            break;
        }

        uSizeOfBlob -= uRequiredSize;
        pucInfoBlob += uRequiredSize;
    }

    if (!bFound) {
        status = IEEE80211_REASON_IE_INVALID;
    }
    return status;
}

/*
 * when we enter this function, we assume:
 * 1. if pmeasrepie is NULL, we build a measurement report with map field's radar set to 1
 * 2. if pmeasrepie is not NULL, only job is to repeat it.
 * 3. only basic report is used for now. For future expantion, it should be modified.
 *  
 */
int
ieee80211_measurement_report_action (
    struct ieee80211vap                    *vap, 
    struct ieee80211_measurement_report_ie *pmeasrepie
    )
{
    struct ieee80211_action_mgt_args       *actionargs; 
    struct ieee80211_measurement_report_ie *newmeasrepie; 
    struct ieee80211_measurement_report_basic_report *pbasic_report;
    struct ieee80211com *ic = vap->iv_ic;

    /* currently we only support IBSS mode */
    if (vap->iv_opmode != IEEE80211_M_IBSS) {
        return -EINVAL;
    }

    if(vap->iv_measrep_action_count_per_tbtt > vap->iv_ibss_dfs_csa_measrep_limit) {
        return EOK;
    }
    vap->iv_measrep_action_count_per_tbtt++;
   
    actionargs = OS_MALLOC(vap->iv_ic->ic_osdev, sizeof(struct ieee80211_action_mgt_args) , GFP_KERNEL);
    if (actionargs == NULL) {
        IEEE80211_DPRINTF(vap, IEEE80211_MSG_ANY, "%s: Unable to alloc arg buf. Size=%d\n",
                                    __func__, sizeof(struct ieee80211_action_mgt_args));
        return -EINVAL;
    }
    OS_MEMZERO(actionargs, sizeof(struct ieee80211_action_mgt_args));
   

    if (pmeasrepie) {

        actionargs->category = IEEE80211_ACTION_CAT_SPECTRUM;
        actionargs->action   = IEEE80211_ACTION_MEAS_REPORT;
        actionargs->arg1     = 0;   /* Dialog Token */
        actionargs->arg2     = 0;   /* not used */
        actionargs->arg3     = 0;   /* not used */
        actionargs->arg4     = (u_int8_t *)pmeasrepie;
        ieee80211_send_action(vap->iv_bss, actionargs, NULL);        
    } else {
    
        newmeasrepie = OS_MALLOC(vap->iv_ic->ic_osdev, sizeof(struct ieee80211_measurement_report_ie) , GFP_KERNEL);
        if (newmeasrepie == NULL) {
            IEEE80211_DPRINTF(vap, IEEE80211_MSG_ANY, "%s: Unable to alloc report ie buf. Size=%d\n",
                                        __func__, sizeof(struct ieee80211_measurement_report_ie));
            OS_FREE(actionargs);                                
            return -EINVAL;
        }        
        OS_MEMZERO(newmeasrepie, sizeof(struct ieee80211_measurement_report_ie));
        newmeasrepie->ie = IEEE80211_ELEMID_MEASREP;
        newmeasrepie->len = sizeof(struct ieee80211_measurement_report_ie)- sizeof(struct ieee80211_ie_header); /* might be different if other report type is supported */
        newmeasrepie->measurement_token = 0;
        newmeasrepie->measurement_report_mode = 0;
        newmeasrepie->measurement_type = 0;
        pbasic_report = (struct ieee80211_measurement_report_basic_report *)newmeasrepie->pmeasurement_report;

        pbasic_report->channel = ic->ic_curchan->ic_ieee;
        pbasic_report->measurement_start_time = vap->iv_bss->ni_tstamp.tsf; /* just make one */
        pbasic_report->measurement_duration = 50; /* fake */
        pbasic_report->map.radar = 1;
        pbasic_report->map.unmeasured = 0;
        
        actionargs->category = IEEE80211_ACTION_CAT_SPECTRUM;
        actionargs->action   = IEEE80211_ACTION_MEAS_REPORT;
        actionargs->arg1     = 0;   /* Dialog Token */
        actionargs->arg2     = 0;   /* not used */
        actionargs->arg3     = 0;   /* not used */
        actionargs->arg4     = (u_int8_t *)newmeasrepie;
        ieee80211_send_action(vap->iv_bss, actionargs, NULL);  
        
        OS_FREE(newmeasrepie);
    }

    OS_FREE(actionargs);

    /* trigger beacon_update timer, we use it as timer */
    ieee80211_ibss_beacon_update_start(ic);

    return EOK;
}


/*  Process Measurement report and take action
 *  Currently this is only supported/tested in IBSS_DFS situation. 
 *  
 */

int
ieee80211_process_meas_report_ie (
    struct ieee80211_node *ni, 
    struct ieee80211_action * pia 
    )
{
    struct ieee80211_measurement_report_ie *pmeasrepie = NULL;
    struct ieee80211_measurement_report_basic_report *pbasic_report =NULL;
    struct ieee80211vap *vap = ni->ni_vap;
    struct ieee80211com *ic = vap->iv_ic;
    u_int8_t * ptmp1 = NULL;
    u_int8_t * ptmp2 = NULL;
    u_int8_t size;
    int      err = (-EOK);
    u_int8_t i = 0;
    u_int8_t unit_len         = sizeof(struct channel_map_field);

    ASSERT(pia);

    if(!(ic->ic_flags_ext & IEEE80211_FEXT_MARKDFS)) {
        return err;
    }
    ptmp1 = (u_int8_t *)pia + sizeof(struct ieee80211_action_measrep_header);

    /*Find measurement report IE*/
    if (ieee80211_validate_ie((u_int8_t *)ptmp1,
                        sizeof(struct ieee80211_measurement_report_ie),
                        IEEE80211_ELEMID_MEASREP,
                        &size,
                        (u_int8_t **)&ptmp2) == IEEE80211_STATUS_SUCCESS)
    {
           ptmp2 -= sizeof(struct ieee80211_ie_header);
           pmeasrepie = (struct ieee80211_measurement_report_ie * )ptmp2 ;
    } else {
        err = -EINVAL;
        return err;
    }

    if (vap->iv_opmode == IEEE80211_M_IBSS) {

        if(pmeasrepie->measurement_type == 0) { /* basic report */
            pbasic_report = (struct ieee80211_measurement_report_basic_report *)pmeasrepie->pmeasurement_report;
        } else {
            err = -EINVAL;
            return err;
        }

         /* mark currnet DFS element's channel's map field */
        for( i = (vap->iv_ibssdfs_ie_data.len - IBSS_DFS_ZERO_MAP_SIZE)/unit_len; i >0; i--) {
            if (vap->iv_ibssdfs_ie_data.ch_map_list[i-1].ch_num == pbasic_report->channel) {
                vap->iv_ibssdfs_ie_data.ch_map_list[i-1].chmap_in_byte |= pbasic_report->chmap_in_byte;
                vap->iv_ibssdfs_ie_data.ch_map_list[i-1].ch_map.unmeasured = 0;
                break;
            }
        }

        if(ic->ic_curchan->ic_ieee == pbasic_report->channel) {
            if (IEEE80211_ADDR_EQ(vap->iv_ibssdfs_ie_data.owner, vap->iv_myaddr) &&
                pbasic_report->map.radar) {
                ieee80211_dfs_action(vap, NULL);
            } else if (pbasic_report->map.radar) { /* Not owner, trigger recovery mode */
                if (vap->iv_ibssdfs_state == IEEE80211_IBSSDFS_JOINER) {
                    vap->iv_ibssdfs_state = IEEE80211_IBSSDFS_WAIT_RECOVERY;
                }
            }
        }
        /* repeat measurement report when we receive it */
        err = ieee80211_measurement_report_action(vap, pmeasrepie);
    }
    return err;
}
#endif /* ATH_SUPPORT_IBSS_DFS */


u_int8_t *
ieee80211_add_mmie(struct ieee80211vap *vap, u_int8_t *bfrm, u_int32_t len)
{
    struct ieee80211_key *key = &vap->iv_igtk_key;
    struct ieee80211_mmie *mmie;
    u_int8_t *pn, aad[20], *efrm;
    struct ieee80211_frame *wh;
    u_int32_t i, hdrlen;

    if (!key && !bfrm) {
        /* Invalid Key or frame */
        return NULL;
    }

    efrm = bfrm + len;
    len += sizeof(*mmie);
    hdrlen = sizeof(*wh);

    mmie = (struct ieee80211_mmie *) efrm;
    mmie->element_id = IEEE80211_ELEMID_MMIE;
    mmie->length = sizeof(*mmie) - 2;
    mmie->key_id = cpu_to_le16(key->wk_keyix);

    /* PN = PN + 1 */
    pn = (u_int8_t*)&key->wk_keytsc;

    for (i = 0; i <= 5; i++) {
        pn[i]++;
        if (pn[i])
            break;
    }

    /* Copy IPN */
    memcpy(mmie->sequence_number, pn, 6);

    wh = (struct ieee80211_frame *) bfrm;

    /* generate BIP AAD: FC(masked) || A1 || A2 || A3 */

    /* FC type/subtype */
    aad[0] = wh->i_fc[0];
    /* Mask FC Retry, PwrMgt, MoreData flags to zero */
    aad[1] = wh->i_fc[1] & ~(IEEE80211_FC1_RETRY | IEEE80211_FC1_PWR_MGT | IEEE80211_FC1_MORE_DATA);
    /* A1 || A2 || A3 */
    memcpy(aad + 2, wh->i_addr1, IEEE80211_ADDR_LEN); 
    memcpy(aad + 8, wh->i_addr2, IEEE80211_ADDR_LEN);
    memcpy(aad + 14, wh->i_addr3, IEEE80211_ADDR_LEN);

    /*
     * MIC = AES-128-CMAC(IGTK, AAD || Management Frame Body || MMIE, 64)
     */
    ieee80211_cmac_calc_mic(key, aad, bfrm + hdrlen, len - hdrlen, mmie->mic);

    return bfrm + len;

}

void
ieee80211_set_vht_rates(struct ieee80211com *ic, struct ieee80211vap  *vap)
{
    u_int8_t tx_streams = ieee80211_get_txstreams(ic, vap),
             rx_streams = ieee80211_get_rxstreams(ic, vap);

    /* Adjust supported rate set based on txchainmask */
    switch (tx_streams) {
        default:
            /* Default to single stream */
        case 1:
            ic->ic_vhtcap_max_mcs.tx_mcs_set.mcs_map = VHT_MCSMAP_NSS1_MCS0_9; /* MCS 0-9 */
            if (vap->iv_vht_mcsmap) {
                ic->ic_vhtcap_max_mcs.tx_mcs_set.mcs_map = (vap->iv_vht_mcsmap | VHT_MCSMAP_NSS1_MASK); 
            }
        break;

        case 2:
            /* Dual stream */
            ic->ic_vhtcap_max_mcs.tx_mcs_set.mcs_map = VHT_MCSMAP_NSS2_MCS0_9; /* MCS 0-9 */
            if (vap->iv_vht_mcsmap) {
                ic->ic_vhtcap_max_mcs.tx_mcs_set.mcs_map = (vap->iv_vht_mcsmap | VHT_MCSMAP_NSS2_MASK); 
            }
        break;

        case 3:
            /* Tri stream */
            ic->ic_vhtcap_max_mcs.tx_mcs_set.mcs_map = VHT_MCSMAP_NSS3_MCS0_9; /* MCS 0-9 */
            if (vap->iv_vht_mcsmap) {
                ic->ic_vhtcap_max_mcs.tx_mcs_set.mcs_map = (vap->iv_vht_mcsmap | VHT_MCSMAP_NSS3_MASK); 
            }
        break;
    }

    /* Adjust rx rates based on the rx chainmask */
    switch (rx_streams) {
        default:
            /* Default to single stream */
        case 1:
            ic->ic_vhtcap_max_mcs.rx_mcs_set.mcs_map = VHT_MCSMAP_NSS1_MCS0_9;
            if (vap->iv_vht_mcsmap) {
                ic->ic_vhtcap_max_mcs.rx_mcs_set.mcs_map = (vap->iv_vht_mcsmap | VHT_MCSMAP_NSS1_MASK); 
            }
        break;

        case 2:
            /* Dual stream */
            ic->ic_vhtcap_max_mcs.rx_mcs_set.mcs_map = VHT_MCSMAP_NSS2_MCS0_9;
            if (vap->iv_vht_mcsmap) {
                ic->ic_vhtcap_max_mcs.rx_mcs_set.mcs_map = (vap->iv_vht_mcsmap | VHT_MCSMAP_NSS2_MASK); 
            }
        break;

        case 3:
            /* Tri stream */
            ic->ic_vhtcap_max_mcs.rx_mcs_set.mcs_map = VHT_MCSMAP_NSS3_MCS0_9;
            if (vap->iv_vht_mcsmap) {
                ic->ic_vhtcap_max_mcs.rx_mcs_set.mcs_map = (vap->iv_vht_mcsmap | VHT_MCSMAP_NSS3_MASK); 
            }
        break;
    }
}

u_int8_t *
ieee80211_add_vhtcap(u_int8_t *frm, struct ieee80211_node *ni,
                     struct ieee80211com *ic, u_int8_t subtype)
{
    int vhtcaplen = sizeof(struct ieee80211_ie_vhtcap);
    struct ieee80211_ie_vhtcap *vhtcap = (struct ieee80211_ie_vhtcap *)frm;
    struct ieee80211vap  *vap = ni->ni_vap;
    u_int32_t vhtcap_info;
    u_int32_t rx_streams = ieee80211_get_rxstreams(ic, vap);
    u_int32_t tx_streams = ieee80211_get_txstreams(ic, vap);

    vhtcap->elem_id   = IEEE80211_ELEMID_VHTCAP;
    vhtcap->elem_len  = sizeof(struct ieee80211_ie_vhtcap) - 2;

    /* Fill in the VHT capabilities info */
    vhtcap_info = ic->ic_vhtcap;
    vhtcap_info &= ((vap->iv_sgi) ? ic->ic_vhtcap : ~IEEE80211_VHTCAP_SHORTGI_80);
    vhtcap_info &= ((vap->iv_ldpc) ?  ic->ic_vhtcap  : ~IEEE80211_VHTCAP_RX_LDPC);

    /* Adjust the TX and RX STBC fields based on the chainmask and config status */
    vhtcap_info &= (((vap->iv_tx_stbc) && (tx_streams > 1)) ?  ic->ic_vhtcap : ~IEEE80211_VHTCAP_TX_STBC);
    vhtcap_info &= (((vap->iv_rx_stbc) && (rx_streams > 0)) ?  ic->ic_vhtcap : ~IEEE80211_VHTCAP_RX_STBC);
    vhtcap->vht_cap_info = htole32(vhtcap_info); 

    /* Fill in the VHT MCS info */
    ieee80211_set_vht_rates(ic,vap);
    vhtcap->rx_mcs_map = htole16(ic->ic_vhtcap_max_mcs.rx_mcs_set.mcs_map);
    vhtcap->rx_high_data_rate = htole16(ic->ic_vhtcap_max_mcs.rx_mcs_set.data_rate);
    vhtcap->tx_mcs_map = htole16(ic->ic_vhtcap_max_mcs.tx_mcs_set.mcs_map);
    vhtcap->tx_high_data_rate = htole16(ic->ic_vhtcap_max_mcs.tx_mcs_set.data_rate);

    return frm + vhtcaplen;
}


u_int8_t *
ieee80211_add_vhtop(u_int8_t *frm, struct ieee80211_node *ni,
                    struct ieee80211com *ic,  u_int8_t subtype)
{
    struct ieee80211vap *vap = ni->ni_vap;
    struct ieee80211_ie_vhtop *vhtop = (struct ieee80211_ie_vhtop *)frm;
    int vhtoplen = sizeof(struct ieee80211_ie_vhtop);
    enum ieee80211_cwm_width ic_cw_width = ic->ic_cwm_get_width(ic);
    u_int8_t chwidth = 0;

    vhtop->elem_id   = IEEE80211_ELEMID_VHTOP;
    vhtop->elem_len  = sizeof(struct ieee80211_ie_vhtop) - 2;

    /* Fill in the VHT Operation info */
    if (vap->iv_chwidth != IEEE80211_CWM_WIDTHINVALID) {
        chwidth = vap->iv_chwidth;
    } else {
        chwidth = ic_cw_width;
    }
    vhtop->vht_op_chwidth = (chwidth == IEEE80211_CWM_WIDTH80) ? 1 : 0;
    vhtop->vht_op_ch_freq_seg1 = vap->iv_bsschan->ic_vhtop_ch_freq_seg1;

    /* Note: This is applicable only for 80+80Mhz mode */
    vhtop->vht_op_ch_freq_seg2 = vap->iv_bsschan->ic_vhtop_ch_freq_seg2; 

    /* Fill in the VHT Basic MCS set */
    vhtop->vhtop_basic_mcs_set =  htole16(ic->ic_vhtop_basic_mcs);
    
    return frm + vhtoplen;
}

u_int8_t *
ieee80211_add_vht_txpwr_envlp(u_int8_t *frm, struct ieee80211_node *ni,
                    struct ieee80211com *ic,  u_int8_t subtype, u_int8_t is_subelement)
{
    struct ieee80211_ie_vht_txpwr_env *txpwr = (struct ieee80211_ie_vht_txpwr_env *)frm;
    int txpwr_len = sizeof(struct ieee80211_ie_vht_txpwr_env) -
             (IEEE80211_VHT_TXPWR_MAX_POWER_COUNT - IEEE80211_VHT_TXPWR_NUM_POWER_SUPPORTED);
    struct ieee80211vap *vap = ni->ni_vap;
    u_int8_t max_pwr;
	struct ieee80211_channel *channel;
    
    txpwr->elem_id   = IEEE80211_ELEMID_VHT_TX_PWR_ENVLP;
    txpwr->elem_len  = txpwr_len - 2;
    
    if(!is_subelement) {
       channel = vap->iv_bsschan;
    }
    else {
       channel = ic->ic_chanchange_channel;
    }
    /* 
     * Max Transmit Power count = 2( 20,40 and 80MHz) and
     * Max Transmit Power units = 0 (EIRP)  
     */
    txpwr->txpwr_info = IEEE80211_VHT_TXPWR_NUM_POWER_SUPPORTED -1;
    /* Tx Power is specified in 0.5dB steps  2's complement representation */
    max_pwr = vap->iv_bsschan->ic_maxregpower;
    txpwr->local_max_txpwr[0] = txpwr->local_max_txpwr[1] =
    txpwr->local_max_txpwr[2] = ~(max_pwr * 2) + 1;

    return frm + txpwr_len;
}


u_int8_t *
ieee80211_add_vht_wide_bw_switch(u_int8_t *frm, struct ieee80211_node *ni,
                    struct ieee80211com *ic,  u_int8_t subtype)
{
    struct ieee80211_ie_wide_bw_switch *widebw = (struct ieee80211_ie_wide_bw_switch *)frm;
    int widebw_len = sizeof(struct ieee80211_ie_wide_bw_switch);
    u_int8_t    new_ch_width;    
    enum ieee80211_phymode new_phy_mode;

    OS_MEMSET(widebw, 0, sizeof(struct ieee80211_ie_wide_bw_switch));

    widebw->elem_id   = IEEE80211_ELEMID_WIDE_BAND_CHAN_SWITCH;
    widebw->elem_len  = widebw_len - 2;

    /* New channel width */
    switch(ic->ic_chanchange_chwidth)
    {
        case CHWIDTH_VHT40:
            new_ch_width = IEEE80211_VHTOP_CHWIDTH_2040;
            break;
        case CHWIDTH_VHT80:
            new_ch_width = IEEE80211_VHTOP_CHWIDTH_80;
            break;
        case CHWIDTH_VHT160:
            new_ch_width = IEEE80211_VHTOP_CHWIDTH_160;
            break;
        default:
            new_ch_width = IEEE80211_VHTOP_CHWIDTH_80_80;
            break;
    }

     /* Channel Center frequency 1 */
    if(new_ch_width != IEEE80211_VHTOP_CHWIDTH_2040) {

       widebw->new_ch_freq_seg1 = ic->ic_chanchange_channel->ic_vhtop_ch_freq_seg1;   
       if(new_ch_width == IEEE80211_VHTOP_CHWIDTH_80_80) {
           /* Channel Center frequency 2 */ 
           widebw->new_ch_freq_seg2 = ic->ic_chanchange_channel->ic_vhtop_ch_freq_seg2;
       }
    } 
    else {
        /* This check should updated with VHT160 also 
           It checks the cur phymode, if it 80/160/80+80 and new width is 40 then
           it fills the channel centre frequency 
         */
       if ((new_ch_width == IEEE80211_VHTOP_CHWIDTH_2040) && 
                     (ic->ic_curmode == IEEE80211_MODE_11AC_VHT80)) {

           new_phy_mode = ieee80211_chan2mode(ic->ic_chanchange_channel);
 
           if(new_phy_mode == IEEE80211_MODE_11AC_VHT40PLUS) {
               widebw->new_ch_freq_seg1 = ic->ic_chanchange_chan+2;
           } else if(new_phy_mode == IEEE80211_MODE_11AC_VHT40MINUS) {
               widebw->new_ch_freq_seg1 = ic->ic_chanchange_chan-2;
           }
       }
    }
    widebw->new_ch_width = new_ch_width;

    return frm + widebw_len;
}

u_int8_t *
ieee80211_add_chan_switch_wrp(u_int8_t *frm, struct ieee80211_node *ni,
                    struct ieee80211com *ic,  u_int8_t subtype, u_int8_t extchswitch)
{
    struct ieee80211vap *vap = ni->ni_vap;
    u_int8_t *efrm;
    u_int8_t ie_len;
    /* preserving efrm pointer, if no sub element is present, 
        Skip adding this element */
    efrm = frm;
     /* reserving 2 bytes for the element id and element len*/
    frm += 2;
 
    /*country element is added if it is extended channel switch*/
    if (extchswitch) {
        frm = ieee80211_add_country(frm, vap);
    }
    /*If channel width not 20 then add Wideband and txpwr evlp element*/
    if(ic->ic_chanchange_chwidth != CHWIDTH_VHT20) {
        frm = ieee80211_add_vht_wide_bw_switch(frm, ni, ic, subtype);

        frm = ieee80211_add_vht_txpwr_envlp(frm, ni, ic, subtype,
                                    IEEE80211_VHT_TXPWR_IS_SUB_ELEMENT);
    }
    /* If frame is filled with sub elements then add element id and len*/
    if((frm-2) != efrm)
    {
       ie_len = frm - efrm - 2;
       *efrm++ = IEEE80211_ELEMID_CHAN_SWITCH_WRAP;
       *efrm = ie_len;
       /* updating efrm with actual index*/
       efrm = frm;
    }
    return efrm;
}
