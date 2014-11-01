#!/bin/sh

CONFIG_DIR=$1/var/rtl8192c/$2
##mkdir -p $1/var/rtl8192c
mkdir -p $1/var/rtl8192c/$2


echo "1" >  $CONFIG_DIR/board_ver
echo "00017301FF10" > $CONFIG_DIR/nic0_addr
echo "00017301FF19" > $CONFIG_DIR/nic1_addr
echo "00017301FF10" > $CONFIG_DIR/wlan0_addr
echo "00017301FF11" > $CONFIG_DIR/wlan1_addr
echo "00017301FF12" > $CONFIG_DIR/wlan2_addr
echo "00017301FF13" > $CONFIG_DIR/wlan3_addr
echo "00017301FF14" > $CONFIG_DIR/wlan4_addr
echo "00017301FF15" > $CONFIG_DIR/wlan5_addr
echo "00017301FF16" > $CONFIG_DIR/wlan6_addr
echo "00017301FF17" > $CONFIG_DIR/wlan7_addr
echo "0000000000000000000000000000" > $CONFIG_DIR/tx_power_cck_a
echo "0000000000000000000000000000" > $CONFIG_DIR/tx_power_cck_b
echo "0000000000000000000000000000" > $CONFIG_DIR/tx_power_ht40_1s_a
echo "0000000000000000000000000000" > $CONFIG_DIR/tx_power_ht40_1s_b
echo "0000000000000000000000000000" > $CONFIG_DIR/tx_power_diff_ht40_2s
echo "0000000000000000000000000000" > $CONFIG_DIR/tx_power_diff_ht20
echo "0000000000000000000000000000" > $CONFIG_DIR/tx_power_diff_ofdm
echo "1" > $CONFIG_DIR/reg_domain
echo "10" > $CONFIG_DIR/rf_type
echo "0" > $CONFIG_DIR/11n_xcap
echo "0" > $CONFIG_DIR/led_type
echo "0" > $CONFIG_DIR/tssi_1
echo "0" > $CONFIG_DIR/tssi_2
echo "0" > $CONFIG_DIR/11n_ther
echo "0" > $CONFIG_DIR/trswitch
echo "27006672" > $CONFIG_DIR/wsc_pin


echo "0" >  $CONFIG_DIR/wlan_mode
echo "0" >  $CONFIG_DIR/wlan_disabled
echo "Klondike_AP_Test" >  $CONFIG_DIR/ssid
echo "3" > $CONFIG_DIR/MIMO_TR_mode

echo "9" > $CONFIG_DIR/channel
echo "11" > $CONFIG_DIR/ch_hi
echo "0" > $CONFIG_DIR/ch_low
echo "11" > $CONFIG_DIR/band
echo "15" > $CONFIG_DIR/basic_rates
echo "1" > $CONFIG_DIR/rate_adaptive_enabled
echo "2347" > $CONFIG_DIR/rts_threshold
echo "2346" > $CONFIG_DIR/frag_threshold
echo "30000" >  $CONFIG_DIR/inactivity_time
echo "0" > $CONFIG_DIR/preamble_type
echo "0" > $CONFIG_DIR/hidden_ssid
echo "1" > $CONFIG_DIR/protection_disabled
echo "0" > $CONFIG_DIR/block_relay
echo "0" > $CONFIG_DIR/wds_enable
echo "0" > $CONFIG_DIR/wds_pure
echo "1" > $CONFIG_DIR/dtim_period
echo "100" > $CONFIG_DIR/beacon_interval
echo "0" > $CONFIG_DIR/macac_num
echo "0" > $CONFIG_DIR/macac_enabled
echo "0" > $CONFIG_DIR/macclone_enable
echo "2" >  $CONFIG_DIR/auth_type
echo "0" > $CONFIG_DIR/encrypt

echo "0" > $CONFIG_DIR/iapp_enable
echo "2" > $CONFIG_DIR/wifi_specific
echo "0" > $CONFIG_DIR/vap_enable
echo "0" > $CONFIG_DIR/wep
echo "0" > $CONFIG_DIR/wep_default_key
echo "1" > $CONFIG_DIR/wep_key_type
echo "0987654321" > $CONFIG_DIR/wepkey1_64_hex
echo "0987654321" > $CONFIG_DIR/wepkey2_64_hex
echo "0987654321" > $CONFIG_DIR/wepkey3_64_hex
echo "0987654321" > $CONFIG_DIR/wepkey4_64_hex
echo "3534333231" > $CONFIG_DIR/wepkey1_64_asc
echo "3534333231" > $CONFIG_DIR/wepkey2_64_asc
echo "3534333231" > $CONFIG_DIR/wepkey3_64_asc
echo "3534333231" > $CONFIG_DIR/wepkey4_64_asc
echo "12345678901234567890123456" > $CONFIG_DIR/wepkey1_128_hex
echo "12345678901234567890123456" > $CONFIG_DIR/wepkey2_128_hex
echo "12345678901234567890123456" > $CONFIG_DIR/wepkey3_128_hex
echo "12345678901234567890123456" > $CONFIG_DIR/wepkey4_128_hex
echo "31323334353637383930313233" > $CONFIG_DIR/wepkey1_128_asc
echo "31323334353637383930313233" > $CONFIG_DIR/wepkey2_128_asc
echo "31323334353637383930313233" > $CONFIG_DIR/wepkey3_128_asc
echo "31323334353637383930313233" > $CONFIG_DIR/wepkey4_128_asc
echo "4095" > $CONFIG_DIR/supported_rate
echo "0" > $CONFIG_DIR/network_type
echo "000000000000" > $CONFIG_DIR/wlan_mac_addr
echo "" > $CONFIG_DIR/default_ssid
echo "0" > $CONFIG_DIR/macclone_enabled
echo "0" > $CONFIG_DIR/fix_rate
echo "0" > $CONFIG_DIR/power_scale
echo "1" > $CONFIG_DIR/wmm_enabled
echo "0" > $CONFIG_DIR/access

echo "1" > $CONFIG_DIR/channel_bonding
echo "0" > $CONFIG_DIR/control_sideband
echo "1" > $CONFIG_DIR/aggregation
echo "1" > $CONFIG_DIR/short_gi
echo "0" > $CONFIG_DIR/stbc_enabled
echo "0" > $CONFIG_DIR/coexist_enabled

echo "2" > $CONFIG_DIR/wpa_auth
echo "" > $CONFIG_DIR/wpa_psk
echo "2" > $CONFIG_DIR/wpa_cipher
echo "2" > $CONFIG_DIR/wpa2_cipher
echo "0" > $CONFIG_DIR/psk_enable
echo "86400" > $CONFIG_DIR/gk_rekey
echo "0" > $CONFIG_DIR/psk_format

echo "0" > $CONFIG_DIR/enable_1x
echo "0.0.0.0" > $CONFIG_DIR/rs_ip
echo "1812" > $CONFIG_DIR/rs_port
echo "" > $CONFIG_DIR/rs_password
echo "3" > $CONFIG_DIR/rs_maxretry
echo "5" > $CONFIG_DIR/rs_interval_time
echo "0" > $CONFIG_DIR/mac_auth_enabled
echo "0" > $CONFIG_DIR/enable_supp_nonwpa
echo "0" > $CONFIG_DIR/supp_nonwpa
echo "0" > $CONFIG_DIR/wpa2_pre_auth

echo "0" > $CONFIG_DIR/account_rs_enabled
echo "0.0.0.0" > $CONFIG_DIR/account_rs_ip
echo "0" > $CONFIG_DIR/account_rs_port
echo "" > $CONFIG_DIR/account_rs_password
echo "0" > $CONFIG_DIR/account_rs_update_enabled
echo "0" > $CONFIG_DIR/account_rs_update_delay
echo "0" > $CONFIG_DIR/account_rs_maxretry
echo "0" > $CONFIG_DIR/account_rs_interval_time


echo "0" > $CONFIG_DIR/wds_enabled

echo "1" > $CONFIG_DIR/wsc_disabled
echo "3" > $CONFIG_DIR/wsc_method
echo "0" > $CONFIG_DIR/wsc_configured
echo "1" > $CONFIG_DIR/wsc_auth
echo "1" > $CONFIG_DIR/wsc_enc
echo "0" > $CONFIG_DIR/wsc_manual_enabled
echo "1" > $CONFIG_DIR/wsc_upnp_enabled
echo "1" > $CONFIG_DIR/wsc_registrar_enabled
echo "" > $CONFIG_DIR/wsc_ssid
echo "" > $CONFIG_DIR/wsc_psk
echo "0" > $CONFIG_DIR/wsc_configbyextreg



echo "192.168.1.1" > $1/var/rtl8192c/ip_addr
echo "255.255.255.0" > $1/var/rtl8192c/net_mask
echo "RTL8192C" > $1/var/rtl8192c/device_name
echo "0" > $1/var/rtl8192c/repeater_enabled
echo "" > $1/var/rtl8192c/repeater_ssid
echo "0" > $1/var/rtl8192c/band2g5g_select










