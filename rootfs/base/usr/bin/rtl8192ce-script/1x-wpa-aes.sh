#!/bin/sh

if [ $# -lt 1 ]; then echo "Usage: $0 iface";  exit 1 ; fi

if [ $1 != 'wlan0' -a $1 != 'wlan1' ]; then
	echo "iface should be wlan0 or wlan1"
	exit
fi

RTL8192CE_SCRIPT_ROOT=/usr/bin/rtl8192ce-script

if [ $1 = 'wlan0' ]; then
	$RTL8192CE_SCRIPT_ROOT/default_setting.sh wlan0
fi
if [ $1 = 'wlan1' ]; then
	$RTL8192CE_SCRIPT_ROOT/default_setting.sh wlan1
fi

###### setting ######
WLAN_IP=172.20.10.2
WLAN_NETMASK=255.255.0.0
WLAN_GW=172.20.10.254
RADIUS_SERVER_IP=172.20.10.250
RADIUS_SERVER_PORT=1812
RADIUS_SERVER_PASSWORD=12345678
#####################

echo "0" > /var/rtl8192c/$1/wlan_mode
echo "$RADIUS_SERVER_IP" > /var/rtl8192c/$1/rs_ip
echo "$RADIUS_SERVER_PORT" > /var/rtl8192c/$1/rs_port
echo "$RADIUS_SERVER_PASSWORD" > /var/rtl8192c/$1/rs_password


echo "2" > /var/rtl8192c/$1/encrypt
echo "1" > /var/rtl8192c/$1/wep
echo "1" > /var/rtl8192c/$1/wpa_auth
echo "2" > /var/rtl8192c/$1/wpa_cipher
echo "2" > /var/rtl8192c/$1/wpa2_cipher

echo "1" > /var/rtl8192c/$1/wsc_configured
echo "2" > /var/rtl8192c/$1/wsc_auth
echo "8" > /var/rtl8192c/$1/wsc_enc
echo "" > /var/rtl8192c/$1/wsc_psk
echo "0" > /var/rtl8192c/$1/wsc_configbyextreg

echo "87654321" > /var/rtl8192c/$1/wpa_psk
echo "0" > /var/rtl8192c/$1/psk_format

$RTL8192CE_SCRIPT_ROOT/init.sh

brctl delif br-lan eth0
ifconfig eth1 0.0.0.0
ifconfig -a br-lan $WLAN_IP netmask $WLAN_NETMASK
route add default gw $WLAN_GW
brctl addif br-lan eth1
brctl addif br-lan wlan0
ifconfig wlan0 up

