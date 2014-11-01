#!/bin/sh
#
# script file to start wlan applications (IAPP, Auth, Autoconf) daemon
#
# Usage: wlanapp.sh [start|kill] wlan_interface...br_interface
#

if [ $# -lt 2 ] || [ $1 != 'start' -a $1 != 'kill' ] ; then 
	echo "Usage: $0 [start|kill] wlan_interface...br_interface [digest] [qfirst]"
	exit 1 
fi

RTL8192CE_SCRIPT_ROOT=/usr/bin/rtl8192ce-script
GET_DIR=var/rtl8192c/wlan0
GET_VALUE=
GET_VALUE_TMP=
WLAN_PREFIX=wlan
KILLALL=killall
START=1
PARAM_NUM=$#
PARAM_ALL=$*
PARAM1=$1
PARAM_BR=
WLAN_INTERFACE=
WLAN_INTERFACE_LIST=wlan0,wlan0-va0,wlan0-va1,wlan0-va2,wlan0-va3

WLAN0_MODE=
WLAN0_DISABLED=
WLAN0_WSC_DISABLED=

WLAN1_MODE=0
WLAN1_DISABLED=1
WLAN1_WSC_DISABLED=1
both_band_ap=0

rtl_check_wlan_band(){

WLAN0_MODE=`cat /var/rtl8192c/wlan0/wlan_mode`
WLAN0_DISABLED=`cat /var/rtl8192c/wlan0/wlan_disabled`
WLAN0_WSC_DISABLED=`cat /var/rtl8192c/wlan0/wsc_disabled`

WLAN1_MODE=`cat /var/rtl8192c/wlan1/wlan_mode`
WLAN1_DISABLED=`cat /var/rtl8192c/wlan1/wlan_disabled`
WLAN1_WSC_DISABLED=`cat /var/rtl8192c/wlan1/wsc_disabled`


	if [ "$WLAN0_MODE" = "0" -o "$WLAN0_MODE" = "3" ] && [ "$WLAN1_MODE" = "0" -o "$WLAN1_MODE" = "3" ] && [ "$WLAN0_DISABLED" = "0" ] && [ "$WLAN1_DISABLED" = "0" ] && [ "$WLAN0_WSC_DISABLED" = "0" ] && [ "$WLAN1_WSC_DISABLED" = "0" ]; then
		both_band_ap = 1
	fi
}

rtl_check_wlan_if() {
	if [ $PARAM_NUM -ge 1 ]; then
		for ARG in $PARAM_ALL ; do
			NAME=`echo $ARG | cut -b -4`
			if [ "$NAME" = "$WLAN_PREFIX" ]; then
				WLAN_INTERFACE="$WLAN_INTERFACE $ARG"
			elif [ "$NAME" != "digest" -a "$NAME" != "qfirst" ]; then
				PARAM_BR=$ARG
			fi
			
		done	

	fi
}
	
DEBUG_EASYCONF=
VXD_INTERFACE=
BR_UTIL=brctl


## kill 802.1x, autoconf and IAPP daemon ##
rtl_kill_iwcontrol_pid() { 
	PIDFILE="/var/run/iwcontrol.pid"
	if [ -f $PIDFILE ] ; then
		PID=`cat $PIDFILE`
		echo "IWCONTROL_PID=$PID"
		if [ $PID != 0 ]; then
			kill -9 $PID 2>/dev/null
		fi
		rm -f $PIDFILE
	fi
}


rtl_kill_wlan_pid() {
	for WLAN in $WLAN_INTERFACE ; do
		PIDFILE=/var/run/auth-$WLAN.pid
		if [ -f $PIDFILE ] ; then
			PID=`cat $PIDFILE`
			if [ $PID != 0 ]; then
				kill -9 $PID 2>/dev/null
			fi
			rm -f $PIDFILE
			
			PIDFILE=/var/run/auth-$WLAN-vxd.pid 
			if [ -f $PIDFILE ] ; then		
				PID=`cat $PIDFILE`
				if [ "$PID" != 0 ]; then
				kill -9 $PID 2>/dev/null
				fi
				rm -f $PIDFILE       		
			fi
		fi
		
	# for WPS ---------------------------------->>
		PIDFILE=/var/run/wscd-$WLAN.pid
		if [ "$both_band_ap" = "1" ]; then
			PIDFILE=/var/run/wscd-wlan0-wlan1.pid
		fi
		
		if [ -f $PIDFILE ] ; then
			PID=`cat $PIDFILE`
			echo "WSCD_PID=$PID"
			if [ $PID != 0 ]; then
				kill -9 $PID 2>/dev/null
			fi
			rm -f $PIDFILE   
		fi 
	done
	#<<----------------------------------- for WPS
}

## start 802.1x daemon ##
DEAMON_CREATED=0
VALID_WLAN_INTERFACE=


rtl_start_wlan() {
	for WLAN in $WLAN_INTERFACE ; do
		_ENABLE_1X=0
		_USE_RS=0
		_DIR=var/rtl8192c/$WLAN
		GET_VALUE_WLAN_DISABLED=`cat /$_DIR/wlan_disabled`
		GET_VALUE_WLAN_MODE=`cat /$_DIR/wlan_mode`
		GET_WLAN_WPA_AUTH_TYPE=`cat /$_DIR/wpa_auth`
		GET_WLAN_ENCRYPT=`cat /$_DIR/encrypt`

		
		VAP=`echo $WLAN | cut -b 7-8`
		VAP_AUTH_ENABLE=0
		ROOT_AUTH_ENABLE=0

		if [ "$GET_WLAN_ENCRYPT" -lt 2 ]; then
			GET_ENABLE_1X=`cat /$_DIR/enable_1x`
			GET_MAC_AUTH_ENABLED=`cat /$GET_DIR/mac_auth_enabled`
			if [ "$GET_ENABLE_1X" != 0 ] || [ "$GET_MAC_AUTH_ENABLED" != 0 ]; then
				_ENABLE_1X=1
				_USE_RS=1
			fi
		else
			_ENABLE_1X=1
			if  [ "$GET_WLAN_WPA_AUTH_TYPE" = 1 ]; then
				_USE_RS=1
			fi		
		fi

	
		ROLE=
		if [ "$_ENABLE_1X" != 0 -a "$GET_VALUE_WLAN_DISABLED" = 0 ]; then	
			$RTL8192CE_SCRIPT_ROOT/flash wpa $WLAN /var/wpa-$WLAN.conf $WLAN
			if [ "$GET_VALUE_WLAN_MODE" = '1' ]; then
				GET_VALUE=`cat /$_DIR/network_type`
				if [ "$GET_VALUE" = '0' ]; then
					ROLE=client-infra
				else
					ROLE=client-adhoc			
				fi
			else
				ROLE=auth
			fi

			VAP_NOT_IN_PURE_AP_MODE=0		
		
			
			if [ "$GET_VALUE_WLAN_MODE" = '0' ] && [ "$VAP_NOT_IN_PURE_AP_MODE" = '0' ]; then
				if  [ "$GET_WLAN_WPA_AUTH_TYPE" != 2 ] || [ "$_USE_RS" != 0 ]; then
					$RTL8192CE_SCRIPT_ROOT/auth $WLAN $PARAM_BR $ROLE /var/wpa-$WLAN.conf
					DEAMON_CREATED=1
					ROOT_AUTH_ENABLE=1
				fi
		
			fi
		fi
		
		if [ "$VAP" = "vx" ] && [ "$GET_VALUE_WLAN_DISABLED" = 0 ]; then	
			if [ "$ROLE" != "auth" ] || [ "$ROLE" = "auth" -a "$_USE_RS" != 0 ]; then
				VXD_INTERFACE=$WLAN
			fi
		fi
		if [ "$VAP" != "vx" ]; then
				GET_WSC_DISABLE=`cat /$_DIR/wsc_disabled`
				if [ $ROOT_AUTH_ENABLE = 1 ] || [ $GET_WSC_DISABLE = 0 ]; then
					VALID_WLAN_INTERFACE="$VALID_WLAN_INTERFACE $WLAN"
				fi
		fi

		
	done

}

#end of start wlan



RPT_ENABLED=`cat /var/rtl8192c/repeater_enabled`

# for WPS ------------------------------------------------->>
rtl_start_wps() {
	if [ ! -e $RTL8192CE_SCRIPT_ROOT/wscd ]; then
		return;
	fi
	for WLAN in $VALID_WLAN_INTERFACE ; do
		if [ $WLAN = "wlan0" ]; then
			
			USE_IWCONTROL=1
			DEBUG_ON=0
			_ENABLE_1X=0
			WSC=1
			_DIR=var/rtl8192c/$WLAN
			CONF_FILE=/var/wsc-$WLAN.conf
			FiFO_File=/var/wscd-$WLAN.fifo
			
			
			GET_WSC_DISABLE=`cat /$_DIR/wsc_disabled`
			GET_VALUE_WLAN_DISABLED=`cat /$_DIR/wlan_disabled`
			GET_VALUE_WLAN_MODE=`cat /$_DIR/wlan_mode`
			GET_WLAN_ENCRYPT=`cat /$_DIR/encrypt`
			GET_WLAN_WPA_AUTH_TYPE=`cat /$_DIR/wpa_auth`
			
			if [ "$GET_WLAN_ENCRYPT" -lt 2 ]; then
				GET_ENABLE_1X=`cat /$_DIR/enable_1x`
				GET_MAC_AUTH_ENABLED=`cat /$_DIR/mac_auth_enabled`
				if [ "$GET_ENABLE_1X" != 0 ] || [ "$GET_MAC_AUTH_ENABLED" != 0 ]; then
					_ENABLE_1X=1
				fi
			else
				_ENABLE_1X=1
			fi

			if [ $WLAN = "wlan0-vxd" ] && [ $RPT_ENABLED = 1 ]; then
				GET_VALUE_WLAN_CURR_MODE=`cat /$_DIR/wlan_mode`
				if [ $GET_VALUE_WLAN_CURR_MODE = 1 ]; then
					GET_WSC_DISABLE = 1
				fi
			fi
			
			if [ $GET_WSC_DISABLE != 0 ]; then
				WSC=0
			else
				if  [ "$GET_VALUE_WLAN_DISABLED" != 0 ] || [ "$GET_VALUE_WLAN_MODE" = 2 ]; then
					WSC=0
				else  
					if [ $GET_VALUE_WLAN_MODE = 1 ]; then	
						GET_VALUE=`cat /$_DIR/network_type`
						if [ "$GET_VALUE" != 0 ]; then
							WSC=0
						fi
					fi
					if [ $GET_VALUE_WLAN_MODE = 0 ]; then	
						if [ $GET_WLAN_ENCRYPT -lt 2 ] && [ $_ENABLE_1X != 0 ]; then
							WSC=0
						fi			
						if [ $GET_WLAN_ENCRYPT -ge 2 ] && [ $GET_WLAN_WPA_AUTH_TYPE = 1 ]; then
							WSC=0
						fi			
					fi
				fi
			fi

			if [ $WSC = 1 ]; then
				if [ ! -f /var/wps/simplecfgservice.xml ]; then
					if [ -e /var/wps ]; then
						rm /var/wps -rf
					fi
					mkdir /var/wps
					cp /etc/simplecfg*.xml /var/wps
				fi

				if [ $GET_VALUE_WLAN_MODE = 1 ]; then			
					UPNP=0
					_CMD="-mode 2"
				else		
					GET_WSC_UPNP_ENABLED=`cat /$_DIR/wsc_upnp_enabled`
					UPNP=$GET_WSC_UPNP_ENABLED
					_CMD="-start"
				fi

				if [ $UPNP = 1 ]; then
					route del -net 239.255.255.250 netmask 255.255.255.255 dev "$PARAM_BR"
					route add -net 239.255.255.250 netmask 255.255.255.255 dev "$PARAM_BR"
				fi
		
				if [ "$both_band_ap" = "1" ]; then
						_CMD="$_CMD -both_band_ap"	
				fi
				
				$RTL8192CE_SCRIPT_ROOT/flash upd-wsc-conf /etc/wscd.conf $CONF_FILE $WLAN
				
				_CMD="$_CMD -c $CONF_FILE -w $WLAN"
		
				if [ $DEBUG_ON = 1 ]; then
					_CMD="$_CMD -debug"	
				fi	
				if [ $USE_IWCONTROL = 1 ]; then
					_CMD="$_CMD -fi $FiFO_File"
					DEAMON_CREATED=1
				fi
		
				if [ -e /var/wps_start_pbc ]; then		
					_CMD="$_CMD -start_pbc"
					rm -f /var/wps_pbc
				fi
				if [ -e /var/wps_start_pin ]; then		
					_CMD="$_CMD -start"
					rm -f /var/wps_start_pin
				fi	
				if [ -e /var/wps_local_pin ]; then		
					PIN=`cat /var/wps_local_pin`		
					_CMD="$_CMD -local_pin $PIN"
					rm -f /var/wps_local_pin
				fi
				if [ -e /var/wps_peer_pin ]; then		
					PIN=`cat /var/wps_peer_pin`		
					_CMD="$_CMD -peer_pin $PIN"
					rm -f /var/wps_peer_pin
				fi				
				WSC_CMD=$_CMD	
				$RTL8192CE_SCRIPT_ROOT/wscd $WSC_CMD -daemon
		
				
				WAIT=5
				while [ $USE_IWCONTROL != 0 -a $WAIT != 0 ]		
				do	
					if [ -e $FiFO_File ]; then
						WAIT=0
					else
						sleep 1
						WAIT=`expr $WAIT - 1`
					fi
				done
			fi
		fi
	done
	if [ $DEAMON_CREATED = 1 ]; then
		$RTL8192CE_SCRIPT_ROOT/iwcontrol $VALID_WLAN_INTERFACE $VXD_INTERFACE $POLL
	fi
}
#<<--------------------------------------------------- for WPS
rtl_start_iwcontrol() {
	if [ $DEAMON_CREATED = 1 ]; then
		$RTL8192CE_SCRIPT_ROOT/iwcontrol $VALID_WLAN_INTERFACE $VXD_INTERFACE $POLL
	fi
}






rtl_wlanapp() {
	if [ $PARAM1 = 'kill' ]; then
		START=0
	fi

	rtl_check_wlan_if

	if [ -z "$WLAN_INTERFACE" ]; then
		echo 'Error in wlanapp.sh, no wlan interface is given!'
		exit 0
	fi
	
	rtl_kill_iwcontrol_pid
	rtl_kill_wlan_pid


	rm -f /var/*.fifo

	if [ $START = 0 ]; then
		exit 1
	fi

	rtl_check_wlan_band
	rtl_start_wlan
	rtl_start_wps
	##rtl_start_iwcontrol
}

rtl_wlanapp
