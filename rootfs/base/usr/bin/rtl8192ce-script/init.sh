#!/bin/sh
#
# script file to start network
#
# Usage: init.sh {gw | ap} {all | bridge | wan}
#

##if [ $# -lt 2 ]; then echo "Usage: $0 {gw | ap} {all | bridge | wan}"; exit 1 ; fi
RTL8192CE_SCRIPT_ROOT=/usr/bin/rtl8192ce-script
START_BRIDGE=$RTL8192CE_SCRIPT_ROOT/bridge.sh
START_WLAN_APP=$RTL8192CE_SCRIPT_ROOT/wlanapp_8192c.sh
START_WLAN=$RTL8192CE_SCRIPT_ROOT/wlan_8192c.sh
WLAN_PREFIX=wlan
GET_DIR=var/rtl8192c/wlan0
GET_VALUE=
WLAN_INTERFACE=
NUM_INTERFACE=
VIRTUAL_NUM_INTERFACE=
VIRTUAL_WLAN_INTERFACE=

# Query number of wlan interface
rtl_query_wlan_if() {
	NUM=0
	VIRTUAL_NUM=0
	VIRTUAL_WLAN_PREFIX=
	V_DATA=
	V_LINE=
	V_NAME=
	HAS_WLAN=0

	DATA=`ifconfig -a | grep $WLAN_PREFIX`
	LINE=`echo $DATA | grep $WLAN_PREFIX$NUM`
	NAME=`echo $LINE | cut -b -5`
	if [ -n "$NAME" ]; then
		HAS_WLAN=1
	fi
	while [ -n "$NAME" ] 
	do
		WLAN_INTERFACE="$WLAN_INTERFACE $WLAN_PREFIX$NUM"

		VIRTUAL_WLAN_PREFIX="$WLAN_PREFIX$NUM-va"
		V_DATA=`ifconfig -a | grep $VIRTUAL_WLAN_PREFIX`
		V_LINE=`echo $V_DATA | grep $VIRTUAL_WLAN_PREFIX$VIRTUAL_NUM`
		V_NAME=`echo $V_LINE | cut -b -9`
		while [ -n "$V_NAME" ] 
		do
			VIRTUAL_WLAN_INTERFACE="$VIRTUAL_WLAN_INTERFACE $VIRTUAL_WLAN_PREFIX$VIRTUAL_NUM"
			VIRTUAL_NUM=`expr $VIRTUAL_NUM + 1`
			V_LINE=`echo $V_DATA | grep $VIRTUAL_WLAN_PREFIX$VIRTUAL_NUM`
			V_NAME=`echo $V_LINE | cut -b -9`
		done
		
		VXD_INTERFACE="$WLAN_PREFIX$NUM-vxd"
		VIRTUAL_WLAN_INTERFACE="$VIRTUAL_WLAN_INTERFACE $VXD_INTERFACE"
		##echo "<<<$VIRTUAL_WLAN_INTERFACE>>>"
		NUM=`expr $NUM + 1`
		LINE=`echo $DATA | grep $WLAN_PREFIX$NUM`
		NAME=`echo $LINE | cut -b -5`
	done
	NUM_INTERFACE=$NUM
	VIRTUAL_NUM_INTERFACE=$VIRTUAL_NUM
}

PARA0=$0
PARA1=$1
PARA2=$2
BR_INTERFACE=br-lan
BR_LAN1_INTERFACE=eth1
BR_LAN2_INTERFACE=eth2

ENABLE_BR=1

RPT_ENABLED=`cat /var/rtl8192c/repeater_enabled`


# Generate WPS PIN number
rtl_generate_wps_pin() {
	GET_VALUE=`cat /$GET_DIR/wsc_pin`
	if [ "$GET_VALUE" = "00000000" ]; then
		##echo "27006672" > /$GET_DIR/wsc_pin
		$RTL8192CE_SCRIPT_ROOT/flash gen-pin wlan0
		$RTL8192CE_SCRIPT_ROOT/flash gen-pin wlan0-vxd
	fi
}

rtl_set_mac_addr() {
	# Set Ethernet 0 MAC address
	GET_VALUE=`cat /$GET_DIR/nic0_addr`
	ELAN_MAC_ADDR=$GET_VALUE
	ifconfig $BR_LAN1_INTERFACE down
	##ifconfig $BR_LAN1_INTERFACE hw ether $ELAN_MAC_ADDR
}


# Start WLAN interface
rtl_start_wlan_if() {
	NUM=0
	while [ $NUM -lt $NUM_INTERFACE -a $ENABLE_BR = 1  ]
	do
		echo 'Initialize '$WLAN_PREFIX$NUM' interface'
		ifconfig $WLAN_PREFIX$NUM down	
		echo "<<<$START_WLAN $WLAN_PREFIX$NUM>>>"
		$START_WLAN $WLAN_PREFIX$NUM
		
		
		if [ $RPT_ENABLED = 1 ]; then
			RP_NAME=-vxd
			ifconfig $WLAN_PREFIX$NUM$RP_NAME down
			/usr/sbin/iwpriv $WLAN_PREFIX$NUM$RP_NAME copy_mib
			echo "<<<$START_WLAN $WLAN_PREFIX$NUM$RP_NAME>>>"
			$START_WLAN $WLAN_PREFIX$NUM$RP_NAME
		fi
	NUM=`expr $NUM + 1`
	done
}

rtl_start_no_gw() {

if [ $RPT_ENABLED = 1 ]; then
echo "<<<$START_BRIDGE $BR_INTERFACE $BR_LAN1_INTERFACE $WLAN_INTERFACE $VIRTUAL_WLAN_INTERFACE>>>"
$START_BRIDGE $BR_INTERFACE $BR_LAN1_INTERFACE $WLAN_INTERFACE $VIRTUAL_WLAN_INTERFACE
else
echo "<<<$START_BRIDGE $BR_INTERFACE $BR_LAN1_INTERFACE $WLAN_INTERFACE>>>"
$START_BRIDGE $BR_INTERFACE $BR_LAN1_INTERFACE $WLAN_INTERFACE
fi

if [ $RPT_ENABLED = 1 ]; then
echo "<<<$START_WLAN_APP start $WLAN_INTERFACE $VIRTUAL_WLAN_INTERFACE $BR_INTERFACE>>>"
$START_WLAN_APP start $WLAN_INTERFACE $VIRTUAL_WLAN_INTERFACE $BR_INTERFACE
else
echo "<<<$START_WLAN_APP start $WLAN_INTERFACE $BR_INTERFACE>>>"
$START_WLAN_APP start $WLAN_INTERFACE $BR_INTERFACE
fi
}


rtl_init() {
echo "Init start....."
	killall webs 2>/dev/null
		$RTL8192CE_SCRIPT_ROOT/webs -x
	rtl_query_wlan_if
	rtl_set_mac_addr
	rtl_generate_wps_pin
	rtl_start_wlan_if
	
	rtl_start_no_gw
}



rtl_init

