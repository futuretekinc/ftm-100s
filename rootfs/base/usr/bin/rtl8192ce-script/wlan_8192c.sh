#!/bin/sh
#
# script file to start WLAN
#
if [ $# -lt 1 ]; then echo "Usage: $0 wlan_interface";  exit 1 ; fi

RTL8192CE_SCRIPT_ROOT=/usr/bin/rtl8192ce-script
SET_WLAN="/usr/sbin/iwpriv $1"
SET_WLAN_PARAM="$SET_WLAN set_mib"
IFCONFIG=ifconfig
START_WLAN_APP=$RTL8192CE_SCRIPT_ROOT/wlanapp_8192c.sh

## Disable WLAN MAC driver and shutdown interface first ##
$IFCONFIG $1 down

GET_DIR=var/rtl8192c/$1
GET_VALUE=
GET_VALUE_TMP=
GET_VALUE_RF_TYPE=`cat /$GET_DIR/rf_type`
GET_VALUE_WLAN_DISABLED=`cat /$GET_DIR/wlan_disabled`
GET_VALUE_WLAN_MODE=`cat /$GET_DIR/wlan_mode`

##$SET_WLAN_PARAM vap_enable=0

## kill wlan application daemon ##

###$START_WLAN_APP kill $1

## Set parameters to driver ##

GET_VALUE=`cat /$GET_DIR/reg_domain`
$SET_WLAN_PARAM regdomain=$GET_VALUE

##GET_VALUE=`cat /$GET_DIR/wlan_mac_addr`
##if [ "$GET_VALUE" = "000000000000" ]; then
##		GET_VALUE=`cat /$GET_DIR/wlan0_addr`
##		WLAN_MAC_ADDR=$GET_VALUE
##fi
GET_VALUE=`cat /$GET_DIR/led_type`
$SET_WLAN_PARAM led_type=$GET_VALUE

if [ "$GET_VALUE_WLAN_MODE" = '1' ]; then
	## client mode
	GET_VALUE=`cat /$GET_DIR/network_type`
		if  [ "$GET_VALUE" = '0' ]; then
			$SET_WLAN_PARAM opmode=8
		else
			$SET_WLAN_PARAM opmode=32
			GET_VALUE_TMP=`cat /$GET_DIR/default_ssid`
			$SET_WLAN_PARAM defssid="$GET_VALUE_TMP"
		fi
	else
	## AP mode
		$SET_WLAN_PARAM opmode=16
fi
##$IFCONFIG $1 hw ether $WLAN_MAC_ADDR
ifconfig -a | awk '$1 ~ /^wlan0$/ {print $5;}' > /$GET_DIR/nic0_addr

##if [ "$GET_VALUE_WLAN_MODE" = '2' ]; then
##		$SET_WLAN_PARAM wds_pure=1
##else
##		$SET_WLAN_PARAM wds_pure=0
##fi

GET_VALUE=`cat /$GET_DIR/MIMO_TR_mode`
$SET_WLAN_PARAM MIMO_TR_mode=$GET_VALUE

# set RF parameters
##$SET_WLAN_PARAM RFChipID=$GET_VALUE_RF_TYPE
GET_TX_POWER_CCK_A=`cat /$GET_DIR/tx_power_cck_a`
GET_TX_POWER_CCK_B=`cat /$GET_DIR/tx_power_cck_b`
GET_TX_POWER_HT40_1S_A=`cat /$GET_DIR/tx_power_ht40_1s_a`
GET_TX_POWER_HT40_1S_B=`cat /$GET_DIR/tx_power_ht40_1s_b`

GET_TX_POWER_DIFF_HT40_2S=`cat /$GET_DIR/tx_power_diff_ht40_2s`
GET_TX_POWER_DIFF_HT20=`cat /$GET_DIR/tx_power_diff_ht20`
GET_TX_POWER_DIFF_OFDM=`cat /$GET_DIR/tx_power_diff_ofdm`

	$SET_WLAN_PARAM pwrlevelCCK_A=$GET_TX_POWER_CCK_A
	$SET_WLAN_PARAM pwrlevelCCK_B=$GET_TX_POWER_CCK_B
	$SET_WLAN_PARAM pwrlevelHT40_1S_A=$GET_TX_POWER_HT40_1S_A
	$SET_WLAN_PARAM pwrlevelHT40_1S_B=$GET_TX_POWER_HT40_1S_B
	$SET_WLAN_PARAM pwrdiffHT40_2S=$GET_TX_POWER_DIFF_HT40_2S
	$SET_WLAN_PARAM pwrdiffHT20=$GET_TX_POWER_DIFF_HT20
	$SET_WLAN_PARAM pwrdiffOFDM=$GET_TX_POWER_DIFF_OFDM
	
	GET_11N_TSSI1=`cat /$GET_DIR/tssi_1`
	$SET_WLAN_PARAM tssi1=$GET_11N_TSSI1
	GET_11N_TSSI2=`cat /$GET_DIR/tssi_2`
	$SET_WLAN_PARAM tssi2=$GET_11N_TSSI2
	
	GET_VALUE=`cat /$GET_DIR/11n_ther`
	$SET_WLAN_PARAM ther=$GET_VALUE
	
	GET_VALUE=`cat /$GET_DIR/trswitch`
	$SET_WLAN_PARAM trswitch=$GET_VALUE

	GET_VALUE=`cat /$GET_DIR/11n_xcap`
	$SET_WLAN_PARAM xcap=$GET_VALUE
	
	GET_VALUE=`cat /$GET_DIR/beacon_interval`
	$SET_WLAN_PARAM bcnint=$GET_VALUE

	GET_VALUE=`cat /$GET_DIR/basic_rates`
	$SET_WLAN_PARAM basicrates=$GET_VALUE

	GET_VALUE=`cat /$GET_DIR/supported_rate`
	$SET_WLAN_PARAM oprates=$GET_VALUE

	GET_RATE_ADAPTIVE_VALUE=`cat /$GET_DIR/rate_adaptive_enabled`
	if [ "$GET_RATE_ADAPTIVE_VALUE" = '0' ]; then
		$SET_WLAN_PARAM autorate=0
		GET_FIX_RATE_VALUE=`cat /$GET_DIR/fix_rate`
		$SET_WLAN_PARAM fixrate=$GET_FIX_RATE_VALUE
	else
		$SET_WLAN_PARAM autorate=1
	fi
	
	
GET_VALUE=`cat /$GET_DIR/rts_threshold`
$SET_WLAN_PARAM rtsthres=$GET_VALUE

GET_VALUE=`cat /$GET_DIR/frag_threshold`
$SET_WLAN_PARAM fragthres=$GET_VALUE

GET_VALUE=`cat /$GET_DIR/inactivity_time`
$SET_WLAN_PARAM expired_time=$GET_VALUE

GET_VALUE=`cat /$GET_DIR/preamble_type`
$SET_WLAN_PARAM preamble=$GET_VALUE


GET_VALUE=`cat /$GET_DIR/hidden_ssid`
$SET_WLAN_PARAM hiddenAP=$GET_VALUE

GET_VALUE=`cat /$GET_DIR/dtim_period`
$SET_WLAN_PARAM dtimperiod=$GET_VALUE



GET_VALUE=`cat /$GET_DIR/channel`
$SET_WLAN_PARAM channel=$GET_VALUE

GET_VALUE=`cat /$GET_DIR/ch_hi`
$SET_WLAN_PARAM ch_hi=$GET_VALUE

GET_VALUE=`cat /$GET_DIR/ch_low`
$SET_WLAN_PARAM ch_low=$GET_VALUE


if [ $1 = "wlan0-vxd" ]; then
	GET_VALUE=`cat /var/rtl8192c/repeater_ssid`
else
	GET_VALUE=`cat /$GET_DIR/ssid`
fi
	$SET_WLAN_PARAM ssid=$GET_VALUE

GET_VALUE=`cat /$GET_DIR/macac_num`
$SET_WLAN_PARAM aclnum=$GET_VALUE

GET_VALUE=`cat /$GET_DIR/macac_enabled`
$SET_WLAN_PARAM aclmode=$GET_VALUE

GET_WLAN_AUTH_TYPE=`cat /$GET_DIR/auth_type`
AUTH_TYPE=$GET_WLAN_AUTH_TYPE
GET_WLAN_ENCRYPT=`cat /$GET_DIR/encrypt`
if [ "$GET_WLAN_AUTH_TYPE" = '1' ] && [ "$GET_WLAN_ENCRYPT" != '1' ]; then
	# shared-key and not WEP enabled, force to open-system
	AUTH_TYPE=0
fi
$SET_WLAN_PARAM authtype=$AUTH_TYPE

if [ "$GET_WLAN_ENCRYPT" = '0' ]; then
	$SET_WLAN_PARAM encmode=0
elif [ "$GET_WLAN_ENCRYPT" = '1' ]; then
	### WEP mode ##
	GET_WEP=`cat /$GET_DIR/wep`
	GET_WEP_KEY_TYPE=`cat /$GET_DIR/wep_key_type`
	GET_WEP_KEY_ID=`cat /$GET_DIR/wep_default_key`
	
	if [ "$GET_WEP" = '1' ]; then
	if [ "$GET_WEP_KEY_TYPE" = 0 ]; then
		GET_WEP_KEY_1=`cat /$GET_DIR/wepkey1_64_asc`
		GET_WEP_KEY_2=`cat /$GET_DIR/wepkey2_64_asc`
		GET_WEP_KEY_3=`cat /$GET_DIR/wepkey3_64_asc`
		GET_WEP_KEY_4=`cat /$GET_DIR/wepkey4_64_asc`
	else
		GET_WEP_KEY_1=`cat /$GET_DIR/wepkey1_64_hex`
		GET_WEP_KEY_2=`cat /$GET_DIR/wepkey2_64_hex`
		GET_WEP_KEY_3=`cat /$GET_DIR/wepkey3_64_hex`
		GET_WEP_KEY_4=`cat /$GET_DIR/wepkey4_64_hex`
	fi
		
		
		$SET_WLAN_PARAM encmode=1
		$SET_WLAN_PARAM wepkey1=$GET_WEP_KEY_1
		$SET_WLAN_PARAM wepkey2=$GET_WEP_KEY_2
		$SET_WLAN_PARAM wepkey3=$GET_WEP_KEY_3
		$SET_WLAN_PARAM wepkey4=$GET_WEP_KEY_4
		$SET_WLAN_PARAM wepdkeyid=$GET_WEP_KEY_ID
	else
		if [ "$GET_WEP_KEY_TYPE" = 0 ]; then
		GET_WEP_KEY_1=`cat /$GET_DIR/wepkey1_128_asc`
		GET_WEP_KEY_2=`cat /$GET_DIR/wepkey2_128_asc`
		GET_WEP_KEY_3=`cat /$GET_DIR/wepkey3_128_asc`
		GET_WEP_KEY_4=`cat /$GET_DIR/wepkey4_128_asc`
	else
		GET_WEP_KEY_1=`cat /$GET_DIR/wepkey1_128_hex`
		GET_WEP_KEY_2=`cat /$GET_DIR/wepkey2_128_hex`
		GET_WEP_KEY_3=`cat /$GET_DIR/wepkey3_128_hex`
		GET_WEP_KEY_4=`cat /$GET_DIR/wepkey4_128_hex`
	fi
		$SET_WLAN_PARAM encmode=5
		$SET_WLAN_PARAM wepkey1=$GET_WEP_KEY_1
		$SET_WLAN_PARAM wepkey2=$GET_WEP_KEY_2
		$SET_WLAN_PARAM wepkey3=$GET_WEP_KEY_3
		$SET_WLAN_PARAM wepkey4=$GET_WEP_KEY_4
		$SET_WLAN_PARAM wepdkeyid=$GET_WEP_KEY_ID
	fi
else
        ## WPA mode ##
	$SET_WLAN_PARAM encmode=2
fi
##$SET_WLAN_PARAM wds_enable=0
##$SET_WLAN_PARAM wds_encrypt=0
$SET_WLAN_PARAM iapp_enable=0

## Set 802.1x flag ##
_ENABLE_1X=0
if [ $GET_WLAN_ENCRYPT -lt 2 ]; then
	GET_ENABLE_1X=`cat /$GET_DIR/enable_1x`
	GET_MAC_AUTH_ENABLED=`cat /$GET_DIR/mac_auth_enabled`
	if [ "$GET_ENABLE_1X" != 0 ] || [ "$GET_MAC_AUTH_ENABLED" != 0 ]; then
		_ENABLE_1X=1
	fi
else
	_ENABLE_1X=1
fi
$SET_WLAN_PARAM 802_1x=$_ENABLE_1X


#set band
GET_BAND=`cat /$GET_DIR/band`
GET_WIFI_SPECIFIC=`cat /$GET_DIR/wifi_specific`
if [ "$GET_VALUE_WLAN_MODE" != '1' ] && [ "$GET_WIFI_SPECIFIC" = 1 ] &&  [ "$GET_BAND" = '2' ] ; then
	GET_BAND=3
fi
if [ "$GET_BAND" = '8' ]; then
	GET_BAND=11
	$SET_WLAN_PARAM deny_legacy=3
elif [ "$GET_BAND" = '2' ]; then
	GET_BAND=3
	$SET_WLAN_PARAM deny_legacy=1
elif [ "$GET_BAND" = '10' ]; then
	GET_BAND=11
	$SET_WLAN_PARAM deny_legacy=1
else
	$SET_WLAN_PARAM deny_legacy=0
fi
$SET_WLAN_PARAM band=$GET_BAND

###Set 11n parameter
if [ $GET_BAND = 10 ] || [ $GET_BAND = 11 ]; then
GET_CHANNEL_BONDING=`cat /$GET_DIR/channel_bonding`
$SET_WLAN_PARAM use40M=$GET_CHANNEL_BONDING

GET_CONTROL_SIDEBAND=`cat /$GET_DIR/control_sideband`

if [ "$GET_CHANNEL_BONDING" = 0 ]; then
$SET_WLAN_PARAM 2ndchoffset=0
else
if [ "$GET_CONTROL_SIDEBAND" = 0 ]; then
	 $SET_WLAN_PARAM 2ndchoffset=1
fi
if [ "$GET_CONTROL_SIDEBAND" = 1 ]; then
	 $SET_WLAN_PARAM 2ndchoffset=2
fi
fi

GET_SHORT_GI=`cat /$GET_DIR/short_gi`
$SET_WLAN_PARAM shortGI20M=$GET_SHORT_GI
$SET_WLAN_PARAM shortGI40M=$GET_SHORT_GI

GET_AGGREGATION=`cat /$GET_DIR/aggregation`

if [ "$GET_AGGREGATION" = 0 ]; then
	$SET_WLAN_PARAM ampdu=$GET_AGGREGATION
	$SET_WLAN_PARAM amsdu=$GET_AGGREGATION
elif [ "$GET_AGGREGATION" = 1 ]; then
	$SET_WLAN_PARAM ampdu=1
	$SET_WLAN_PARAM amsdu=0
elif [ "$GET_AGGREGATION" = 2 ]; then
	$SET_WLAN_PARAM ampdu=0
	$SET_WLAN_PARAM amsdu=1
elif [ "$GET_AGGREGATION" = 3 ]; then
	$SET_WLAN_PARAM ampdu=1
	$SET_WLAN_PARAM amsdu=1
fi

GET_STBC_ENABLED=`cat /$GET_DIR/stbc_enabled`
$SET_WLAN_PARAM stbc=$GET_STBC_ENABLED
GET_COEXIST_ENABLED=`cat /$GET_DIR/coexist_enabled`
$SET_WLAN_PARAM coexist=$GET_COEXIST_ENABLED
fi
##########

#set nat2.5 disable when client and mac clone is set
##GET_MACCLONE_ENABLED=`cat /$GET_DIR/macclone_enable`
##if [ "$GET_MACCLONE_ENABLED" = '1' -a "$GET_VALUE_WLAN_MODE" = '1' ]; then
##	$SET_WLAN_PARAM nat25_disable=1
##	$SET_WLAN_PARAM macclone_enable=1
##else
##	$SET_WLAN_PARAM nat25_disable=0
##	$SET_WLAN_PARAM macclone_enable=0
##fi

# set 11g protection mode
GET_PROTECTION_DISABLED=`cat /$GET_DIR/protection_disabled`
if  [ "$GET_PROTECTION_DISABLED" = '1' ] ;then
	$SET_WLAN_PARAM disable_protection=1
else
	$SET_WLAN_PARAM disable_protection=0
fi

# set block relay
GET_BLOCK_RELAY=`cat /$GET_DIR/block_relay`
$SET_WLAN_PARAM block_relay=$GET_BLOCK_RELAY

# set WiFi specific mode
GET_WIFI_SPECIFIC=`cat /$GET_DIR/wifi_specific`
$SET_WLAN_PARAM wifi_specific=$GET_WIFI_SPECIFIC

# for WMM
GET_WMM_ENABLED=`cat /$GET_DIR/wmm_enabled`
$SET_WLAN_PARAM qos_enable=$GET_WMM_ENABLED

# for guest access
GET_ACCESS=`cat /$GET_DIR/access`
$SET_WLAN_PARAM guest_access=$GET_ACCESS


#
# following settings is used when driver WPA module is included
#

GET_WPA_AUTH=`cat /$GET_DIR/wpa_auth`
#if [ $GET_VALUE_WLAN_MODE != 1 ] && [ $GET_WLAN_ENCRYPT -ge 2 ]  && [ $GET_WLAN_ENCRYPT -lt 7 ] && [ $GET_WPA_AUTH = 2 ]; then
if [ $GET_WLAN_ENCRYPT -ge 2 ]  && [ $GET_WLAN_ENCRYPT -lt 7 ] && [ $GET_WPA_AUTH = 2 ]; then
	if [ $GET_WLAN_ENCRYPT = 2 ]; then
		ENABLE=1
	elif [ $GET_WLAN_ENCRYPT = 4 ]; then
		ENABLE=2
	elif [ $GET_WLAN_ENCRYPT = 6 ]; then
		ENABLE=3
	else
		echo "invalid ENCRYPT value!"; exit
	fi
	$SET_WLAN_PARAM psk_enable=$ENABLE

	if [ $GET_WLAN_ENCRYPT = 2 ] || [ $GET_WLAN_ENCRYPT = 6 ]; then
		GET_WPA_CIPHER_SUITE=`cat /$GET_DIR/wpa_cipher`
		if [ $GET_WPA_CIPHER_SUITE = 1 ]; then
			CIPHER=2
		elif [ $GET_WPA_CIPHER_SUITE = 2 ]; then
			CIPHER=8
		elif [ $GET_WPA_CIPHER_SUITE = 3 ]; then
			CIPHER=10
		else
			echo "invalid WPA_CIPHER_SUITE value!"; exit 1
		fi
	fi
	$SET_WLAN_PARAM wpa_cipher=$CIPHER

	if [ $GET_WLAN_ENCRYPT = 4 ] || [ $GET_WLAN_ENCRYPT = 6 ]; then
		GET_WPA2_CIPHER_SUITE=`cat /$GET_DIR/wpa2_cipher`
		if [ $GET_WPA2_CIPHER_SUITE = 1 ]; then
			CIPHER=2
		elif [ $GET_WPA2_CIPHER_SUITE = 2 ]; then
			CIPHER=8
		elif [ $GET_WPA2_CIPHER_SUITE = 3 ]; then
			CIPHER=10
		else
			echo "invalid WPA2_CIPHER_SUITE value!"; exit 1
		fi
	fi
	$SET_WLAN_PARAM wpa2_cipher=$CIPHER

	GET_WPA_PSK=`cat /$GET_DIR/wpa_psk`
	$SET_WLAN_PARAM passphrase=$GET_WPA_PSK

	
	GET_WPA_GROUP_REKEY_TIME=`cat /$GET_DIR/gk_rekey`
	$SET_WLAN_PARAM gk_rekey=$GET_WPA_GROUP_REKEY_TIME
else
	$SET_WLAN_PARAM psk_enable=0
fi
