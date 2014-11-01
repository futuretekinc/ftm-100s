#!/bin/sh
#
# script file to start bridge
#
# Usage: bridge.sh br_interface lan1_interface wlan_interface[1]..wlan_interface[N]
#

if [ $# -lt 3 ]; then echo "Usage: $0 br_interface lan1_interface wlan_interface lan2_interface...";  exit 1 ; fi

GET_DIR=/var/rtl8192c/wlan0
GET_VALUE=
BR_UTIL=/usr/sbin/brctl
IFCONFIG=ifconfig
WLAN_PREFIX=wlan
LAN_PREFIX=eth
INITFILE=/tmp/bridge_init

#set PARA for $i can't pass to function
PARA1=$1
PARA2=$2
PARA3=$3
PARA_ALL=$*


rtl_shutdown_lan_if() {	
	# shutdown LAN interface (ethernt, wlan)
	for ARG in $PARA_ALL ; do
		INTERFACE=`echo $ARG | cut -b -4`
			$IFCONFIG $ARG down	
			if [ $ARG != $PARA1 ]; then
				$BR_UTIL delif $PARA1 $ARG 2> /dev/null
			fi		
	done
}



rtl_del_wlan0_eth1() {
	#delete wlan0 eth1 interface first always, wlan0 eth1 will be added later if mode is opmode = bridge and gw platform
	$BR_UTIL delif $PARA1 eth1 2> /dev/null  
	$BR_UTIL delif $PARA1 wlan0 2> /dev/null  	
	$BR_UTIL delif $PARA1 wlan0-vxd 2> /dev/null  
	if [ ! -f $INITFILE ]; then
	$BR_UTIL delbr $PARA1
	fi	
}

rtl_enable_lan_if() {
	# Enable LAN interface (Ethernet, wlan, WDS, bridge)
	echo 'Setup bridge...'
	if [ ! -f $INITFILE ]; then
	$BR_UTIL addbr $PARA1
	fi
	$BR_UTIL setfd $PARA1 0
	$BR_UTIL stp $PARA1 0

	#Add lan port to bridge interface
	for ARG in $PARA_ALL ; do
		INTERFACE=`echo $ARG | cut -b -3`
		if [ $INTERFACE = $LAN_PREFIX ]; then	
			up_interface=1
			if [ $up_interface != 0 ]; then		
			$BR_UTIL addif $PARA1 $ARG 2> /dev/null
			$IFCONFIG $ARG  0.0.0.0
			fi	
		fi	
	done
	
	START_WLAN=1
	HAS_WLAN=0
	for ARG in $PARA_ALL ; do
	sleep 1
		INTERFACE=`echo $ARG | cut -b -4`
		if [ $INTERFACE = $WLAN_PREFIX ]; then
			HAS_WLAN=1
			WLAN_DISABLED_VALUE=/var/rtl8192c/$ARG/wlan_disabled
			GET_VALUE_WLAN_DISABLED=`cat $WLAN_DISABLED_VALUE`
			if [ "$GET_VALUE_WLAN_DISABLED" = 0 ]; then
				if [ $START_WLAN != 0 ]; then
					$BR_UTIL addif $PARA1 $ARG 2> /dev/null
					$IFCONFIG $ARG 0.0.0.0
					$IFCONFIG $ARG up
				fi		
			fi
		fi	
	done	
	
	if [ ! -f $INITFILE ]; then
	$IFCONFIG $PARA1 0.0.0.0
		echo 1 > $INITFILE 	
	fi
}
#end of rtl_enable_lan_if

rtl_set_lan_ip() {
IP_ADDR=`cat /var/rtl8192c/ip_addr`
SUBNET_MASK=`cat /var/rtl8192c/net_mask`
	ifconfig $PARA1 $IP_ADDR netmask $SUBNET_MASK
}

rtl_bridge() {
	if [ "$PARA3" != "null" ]; then
		rtl_shutdown_lan_if		
		rtl_del_wlan0_eth1
		rtl_enable_lan_if
	fi
	rtl_set_lan_ip
}


rtl_bridge

