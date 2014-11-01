#!/bin/sh

if [ $# -lt 2 ]; then echo "Usage: $0 iface mode";  exit 1 ; fi

RTL8192CE_SCRIPT_ROOT=/usr/bin/rtl8192ce-script

if [ $1 = 'wlan0' ]; then
	$RTL8192CE_SCRIPT_ROOT/default_setting.sh wlan0
fi
if [ $1 = 'wlan1' ]; then
	$RTL8192CE_SCRIPT_ROOT/default_setting.sh wlan1
fi
if [ $2 = 'ap' ]; then
echo "0" > /var/rtl8192c/$1/wlan_mode
fi

echo "6" > /var/rtl8192c/$1/encrypt
echo "0" > /var/rtl8192c/$1/enable_1x
echo "2" > /var/rtl8192c/$1/wpa_auth
echo "2" > /var/rtl8192c/$1/wpa_cipher
echo "2" > /var/rtl8192c/$1/wpa2_cipher

echo "87654321" > /var/rtl8192c/$1/wpa_psk

echo "1" > /var/rtl8192c/$1/wsc_configured
echo "34" > /var/rtl8192c/$1/wsc_auth
echo "12" > /var/rtl8192c/$1/wsc_enc
echo "0" > /var/rtl8192c/$1/wsc_configbyextreg
echo 87654321 > /var/rtl8192c/$1/wsc_psk
$RTL8192CE_SCRIPT_ROOT/init.sh

