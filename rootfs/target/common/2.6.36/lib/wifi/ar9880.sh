# This is the OpenWRT "driver" for the ar9880.
#
append DRIVERS "ar9880"

SCRIPT_DIR=/etc/cs75xx/hw_accel/demo

# I guess this routine scans for correct configuration,
# and can attach additional information to the cfg structs.
# See the following files for examples:
#  openwrt-2.4.2011-trunk/package/broadcom-wl/files/lib/wifi/broadcom.sh
#  openwrt-2.4.2011-trunk/package/madwifi/files/lib/wifi/madwifi.sh
#  openwrt-2.4.2011-trunk/package/acx/files/lib/wifi/acx.sh
#
scan_ar9880() {
    local device="$1"

    config_get vifs "$device" vifs
    for vif in $vifs; do
        config_get ifname "$vif" ifname
        config_set "$vif" ifname "${ifname:-$device}"
    done
}

# Disable the device and remove from
# the bridge.
disable_ar9880() {
    local device="$1"
    include /lib/network
    ifconfig "$device" down 2>/dev/null >/dev/null && {
        unbridge "$device"
    }
    true
}

# Enable the device (ifconfig $dev up), then
# configure the device, then set up the
# network (including adding the device to the bridge).
enable_ar9880() {
    local device="$1"

    config_get vifs "$device" vifs

    local first=1
    for vif in $vifs; do
	config_get ifname "$vif" ifname

        ifname=${ifname/_/-}
        echo "================================="
        echo ifname=$ifname

        config_get channel "$device" channel
        config_get ssid "$device" ssid
        config_get ch_hi "$device" ch_hi
        config_get ch_lo "$device" ch_lo
        config_get macaddr "$device" macaddr
        config_get repeater "$device" repeater
        config_get hwmode "$device" hwmode
        config_get htmode "$device" htmode
        config_get ext_channel "$device" ext_channel
        config_get wps_pin "$vif" wps_pin
        config_get beacon_int "$device" beacon_int
        config_get country "$vif" country
        config_get vifs "$device" vifs

        if [ "$device" = "wlan0" ]; then
        echo "============== device=wlan0 =============="

        # AP Start Mode settings
        config_get start_mode "wlan0" start_mode
        config_get hidden_wlan0 "wlan0" hidden
        config_get hidden_wlan1 "wlan1" hidden
        config_get auth_wlan0 "wlan0" auth
        config_get auth_wlan1 "wlan1" auth
        config_get cipher_wlan0 "wlan0" encryption
        config_get cipher_wlan1 "wlan1" encryption
        config_get wfo_ar9880 "wlan0" wfo_ar9880
        config_get mode_id "wlan0" mode_id

	# Shutdown all WiFi interface
	ifconfig wlan0 down
	ifconfig wlan1 down

        # MODE_ID w/ WFO
        case "$mode_id" in
                "8")
                        echo $mode_id > $SCRIPT_DIR/mode_id
                        echo " MODE_ID has been changed to 8, please reboot system"
		        echo "  WFO(Bridge Mode):       Enable"
		        echo "          load rt3593ap_wfo.ko"
		        echo "  IPSEC(HW ENCP/DECP):    N/A"
		        echo "  L2TP:                   N/A"
		        echo "  NAT(HW):                Disable"
		        echo "  hw_accel_enable:        0x8004"
		        sleep 1
		        echo 0x8004 > /proc/driver/cs752x/ne/accel_manager/hw_accel_enable
		        sleep 1
		        #$SCRIPT_DIR/set_default_network.sh
		        #$SCRIPT_DIR/set_wifi_network.sh 1               # WiFi-Offload: 1
                ;;
                "9")
                        echo $mode_id > $SCRIPT_DIR/mode_id
                        echo " MODE_ID has been changed to 9, please reboot system"
		        echo "  WFO(Bridge Mode):       Enable"
		        echo "          load rt3593ap_wfo.ko"
		        echo "  IPSEC(HW ENCP/DECP):    N/A"
		        echo "  L2TP:                   N/A"
		        echo "  NAT(HW):                Disable"
		        echo "  hw_accel_enable:        0x8004"
		        sleep 1
		        echo 0x8024 > /proc/driver/cs752x/ne/accel_manager/hw_accel_enable
		        sleep 1	
		        #$SCRIPT_DIR/set_default_network.sh
		        #$SCRIPT_DIR/set_wifi_network.sh 1               # WiFi-Offload: 1
                ;;
                "10")
                        echo $mode_id > $SCRIPT_DIR/mode_id
                        echo " MODE_ID has been changed to $mode_id, please reboot system"
		        echo "  WFO(Bridge Mode):       Enable"
		        echo "          load rt3593ap_wfo.ko"
		        echo "  IPSEC(HW ENCP/DECP):    N/A"
		        echo "  L2TP:                   Enable"
		                echo "          load openswan / cs75xx_spacc.ko"
		        echo "  NAT(HW):                Disable"
		        echo "  hw_accel_enable:        0x8004"
		        sleep 1
		        echo 0x8004 > /proc/driver/cs752x/ne/accel_manager/hw_accel_enable
		        insmod /lib/modules/2.6.36/cs75xx_spacc.ko
		        sleep 1
		        #$SCRIPT_DIR/set_default_network.sh
		        #$SCRIPT_DIR/set_wifi_network.sh 1               # WiFi-Offload: 1
		        #$SCRIPT_DIR/set_openswan_application.sh
                ;;
                "12")
                        echo $mode_id > $SCRIPT_DIR/mode_id
                        echo " MODE_ID has been changed to $mode_id, please reboot system"
		        echo "  WFO(Bridge Mode):       Enable"
		        echo "          load rt3593ap_wfo.ko / wfo_rl_pe0.bin / wfo_rl_pe1.bin"
		        echo "  IPSEC(HW ENCP/DECP):    Disable"
		        echo "          load racoon2 / cs75xx_spacc.ko"
		        echo "  L2TP:                   N/A"
		        echo "  NAT(HW):                Disable"
		        echo "  hw_accel_enable:        0x8004"
		        sleep 1
		        echo 0x8004 > /proc/driver/cs752x/ne/accel_manager/hw_accel_enable
		        insmod /lib/modules/2.6.36/cs75xx_spacc.ko
		        sleep 1
		        #$SCRIPT_DIR/set_default_network.sh
		        #$SCRIPT_DIR/set_wifi_network.sh 1               # WiFi-Offload: 1
		        #$SCRIPT_DIR/set_ipsec_network.sh 0      # IPSEC HW Acceleration: 0
                ;;
                "13")
                        echo $mode_id > $SCRIPT_DIR/mode_id
                        echo " MODE_ID has been changed to $mode_id, please reboot system"
		        echo "  WFO(Bridge Mode):       Enable"
		        echo "          load rt3593ap_wfo.ko"
		        echo "  IPSEC(HW ENCP/DECP):    N/A"
		        echo "  L2TP:                   N/A"
		        echo "  NAT(HW):                Disable"
		        echo "  hw_accel_enable:        0x8004"
		        sleep 1
		        echo 0x9024 > /proc/driver/cs752x/ne/accel_manager/hw_accel_enable
		        sleep 1
		        #$SCRIPT_DIR/set_default_network.sh
		        #$SCRIPT_DIR/set_wifi_network.sh 1               # WiFi-Offload: 1
		        #$SCRIPT_DIR/set_pppoe_client.sh
		;;
                "14")
                        echo $mode_id > $SCRIPT_DIR/mode_id
                        echo " MODE_ID has been changed to $mode_id, please reboot system"
		        echo "  WFO(Bridge Mode):       Enable"
		        echo "          load 11ac wfo and 11n A9 wifi"
		        echo "  IPSEC(HW ENCP/DECP):    Enable at PE#1"
		        echo "  L2TP:                   N/A"
		        echo "  NAT(HW):                Enable"
		        echo "  hw_accel_enable:        0xf1ff"
		        echo "  ipsec_offload_mode:     3"
		        sleep 1
		        echo 3 > /proc/driver/cs752x/ne/accel_manager/ipsec_offload_mode
		        echo 0xf1ff > /proc/driver/cs752x/ne/accel_manager/hw_accel_enable
		        sleep 1
		        #$SCRIPT_DIR/set_default_network.sh
		        #$SCRIPT_DIR/set_wifi_network.sh 14               # WiFi-Offload: 1
		        #$SCRIPT_DIR/set_ipsec_network.sh 0      # IPSEC HW Acceleration: 1 but PE image is loaded in wifi script
                ;;
        esac

        # MODE_ID w/o WFO
        case "$mode_id" in
                "-1")
                        echo $mode_id > $SCRIPT_DIR/mode_id
                        echo " MODE_ID has been changed to $mode_id, please reboot system"
		;;
                "0")
                        echo $mode_id > $SCRIPT_DIR/mode_id
                        echo " MODE_ID has been changed to $mode_id, please reboot system"
			echo "  WFO(Bridge Mode):       Disable"
	                echo "          load rt3593ap_wfo.ko / wfo_rl_pe0.bin / wfo_rl_pe1.bin"
		        echo "  IPSEC(HW ENCP/DECP):    N/A"
		        echo "  L2TP:                   N/A"
		        echo "  NAT(HW):                Disable"
		        echo "  hw_accel_enable:        0xFFFF"
		        echo 0 > /proc/driver/cs752x/ne/accel_manager/hw_accel_enable
		;;
                "1")
                        echo $mode_id > $SCRIPT_DIR/mode_id
                        echo " MODE_ID has been changed to $mode_id, please reboot system"
		        echo "  WFO(Bridge Mode):       Disable"
		        echo "          load rt3593ap_cs.ko"
		        echo "  IPSEC(HW ENCP/DECP):    N/A"
		        echo "  L2TP:                   N/A"
		        echo "  NAT(HW):                Enable"
		        echo "  hw_accel_enable:        0xf0ff"
		        echo 0xf0ff > /proc/driver/cs752x/ne/accel_manager/hw_accel_enable
		        #$SCRIPT_DIR/set_default_network.sh
		        #$SCRIPT_DIR/set_wifi_network.sh 0               # WiFi-Offload: 0
                ;;
                "2")
                        echo $mode_id > $SCRIPT_DIR/mode_id
                        echo " MODE_ID has been changed to $mode_id, please reboot system"
		        echo "  WFO(Bridge Mode):       Disable"
		        echo "          load rt3593ap_cs.ko"
		        echo "  IPSEC(HW ENCP/DECP):    N/A"
		        echo "  L2TP:                   Enable"
		        echo "          load openswan / cs75xx_spacc.ko"
		        echo "  NAT(HW):                Disable"
		        echo "  hw_accel_enable:        0x0000"
		        sleep 1
		        echo 0x0 > /proc/driver/cs752x/ne/accel_manager/hw_accel_enable
		        insmod /lib/modules/2.6.36/cs75xx_spacc.ko
		        sleep 1
		        #$SCRIPT_DIR/set_default_network.sh
		        #$SCRIPT_DIR/set_wifi_network.sh 0               # WiFi-Offload: 0
		        #$SCRIPT_DIR/set_openswan_application.sh
                ;;
                "3")
                        echo $mode_id > $SCRIPT_DIR/mode_id
                        echo " MODE_ID has been changed to $mode_id, please reboot system"
		        echo "  WFO(Bridge Mode):       Disable"
		        echo "          load rt3593ap_cs.ko"
		        echo "  IPSEC(HW ENCP/DECP):    N/A"
		        echo "  L2TP:                   N/A"
		        echo "  NAT(HW):                Disable"
		        echo "  hw_accel_enable:        0x0000"
		        sleep 1
		        echo 0x0 > /proc/driver/cs752x/ne/accel_manager/hw_accel_enable
		        sleep 1
		        $SCRIPT_DIR/set_default_network.sh
		        $SCRIPT_DIR/set_wifi_network.sh 0               # WiFi-Offload: 0
                ;;
                "4")
                        echo $mode_id > $SCRIPT_DIR/mode_id
                        echo " MODE_ID has been changed to $mode_id, please reboot system"
		        echo "  WFO(Bridge Mode):       Disable"
		        echo "          load rt3593ap_cs.ko"
		        echo "  IPSEC(HW ENCP/DECP):    Enable"
		        echo "          load racoon2 / cs75xx_spacc.ko"
		        echo "  L2TP:                   N/A"
		        echo "  NAT(HW):                Disable"
		        echo "  hw_accel_enable:        0xf0ff"
		        sleep 1
		        echo 0xf0ff > /proc/driver/cs752x/ne/accel_manager/hw_accel_enable
		        insmod /lib/modules/2.6.36/cs75xx_spacc.ko
		        sleep 1
		        #$SCRIPT_DIR/set_default_network.sh
		        echo 0 > /proc/driver/cs752x/rt3593/noncacheable_buffer
		        #$SCRIPT_DIR/set_wifi_network.sh 0               # WiFi-Offload: 0
		        #$SCRIPT_DIR/set_ipsec_network.sh 1      # IPSEC HW Acceleration: 0
                ;;
                "5")
                        echo $mode_id > $SCRIPT_DIR/mode_id
                        echo " MODE_ID has been changed to $mode_id, please reboot system"
		        echo "  WFO(Bridge Mode):       Disable"
		        echo "          load rt3593ap_cs.ko"
		        echo "  IPSEC(HW ENCP/DECP):    Disable"
		        echo "          load racoon2 / cs75xx_spacc.ko"
		        echo "  L2TP:                   N/A"
		        echo "  NAT(HW):                Disable"
		        echo "  hw_accel_enable:        0x0000"
		        sleep 1
		        echo 0x0 > /proc/driver/cs752x/ne/accel_manager/hw_accel_enable
		        insmod /lib/modules/2.6.36/cs75xx_spacc.ko
		        sleep 1
		        #$SCRIPT_DIR/set_default_network.sh
		        echo 0 > /proc/driver/cs752x/rt3593/noncacheable_buffer
		        #$SCRIPT_DIR/set_wifi_network.sh 0               # WiFi-Offload: 0
		        #$SCRIPT_DIR/set_ipsec_network.sh 0      # IPSEC HW Acceleration: 0
                ;;
                "6")
                        echo $mode_id > $SCRIPT_DIR/mode_id
                        echo " MODE_ID has been changed to $mode_id, please reboot system"
		        echo "  WFO(Bridge Mode):       Disable"
		        echo "          load rt3593ap_cs.ko"
		        echo "  IPSEC(HW ENCP/DECP):    N/A"
		        echo "  L2TP:                   N/A"
		        echo "  NAT(HW):                Disable"
		        echo "  hw_accel_enable:        0x0000"
		        sleep 1
		        echo 0x0 > /proc/driver/cs752x/ne/accel_manager/hw_accel_enable
		        sleep 1
		        #$SCRIPT_DIR/set_default_network.sh
		        #$SCRIPT_DIR/set_wifi_network.sh 0               # WiFi-Offload: 0
                ;;
        esac

	# Load 11AC driver
        lsmod | grep umac >& /dev/null
        if [ $? -eq 0 ]; then
        echo "umac has been loaded, remove first!"
	else
	cd /lib/modules/2.6.36/
	#insmod adf.ko
	#insmod asf.ko
	#insmod ath_hal.ko
	#insmod ath_rate_atheros.ko
	#insmod ath_dfs.ko
	#insmod ath_dev.ko
	#sleep 2
	#insmod umac.ko
	#sleep 2
	fi 

	# Create ap device
	wlanconfig wlan0 create wlandev wifi0 wlanmode ap
	sleep 2
	
	# Restart WFO procedure
	#echo 0 > /proc/driver/cs752x/wfo/wifi_offload_enable
	#cd /rboot/wfo_atheros_11AC/
	#/rboot/rboot ar988x_pe0.bin
	#sleep 2
	#echo 1 > /proc/driver/cs752x/wfo/wifi_offload_enable
	#echo 0x605 > /proc/driver/cs752x/acp/acp_enable

	# Install Normal 11.ac driver
        #lsmod | grep umac >& /dev/null
        #if [ $? -eq 0 ]; then
        #echo "umac has been loaded, remove first!"
        #else
        #cd /lib/modules/2.6.36/
        #insmod adf.ko
        #insmod asf.ko
        #insmod ath_hal.ko
        #insmod ath_rate_atheros.ko
        #insmod ath_dfs.ko
        #insmod ath_dev.ko
        #sleep 2
        #insmod umac.ko
        #sleep 2
        #fi

	# End of WFO

        if [ "$start_mode" = "0" ]; then
        echo "Single mode"

	# Create ap(11AC) device
	wlanconfig wlan0 create wlandev wifi0 wlanmode ap
        # Encryption
        case "$auth_wlan0" in
		"wep")
        		sed -i 's/EncrypType=NONE/EncrypType=WEP/g' /etc/Wireless/RT2860AP/RT2860AP.dat
		;;
		"wpa")
        		sed -i 's/AuthMode=OPEN/AuthMode=WPAPSK/g' /etc/Wireless/RT2860AP/RT2860AP.dat
                        case "$cipher_wlan0" in
                                  "CCMP") sed -i 's/EncrypType=NONE/EncrypType=AES/g' /etc/Wireless/RT2860AP/RT2860AP.dat;;
                                  "TKIP") sed -i 's/EncrypType=NONE/EncrypType=TKIP/g' /etc/Wireless/RT2860AP/RT2860AP.dat;;
                                  "CCMP TKIP") sed -i 's/EncrypType=NONE/EncrypType=TKIPAES/g' /etc/Wireless/RT2860AP/RT2860AP.dat;;
                        esac
		;;	
		"wpa2")
        		sed -i 's/AuthMode=OPEN/AuthMode=WPA2PSK/g' /etc/Wireless/RT2860AP/RT2860AP.dat
                        case "$cipher_wlan0" in
                                  "CCMP") sed -i 's/EncrypType=NONE/EncrypType=AES/g' /etc/Wireless/RT2860AP/RT2860AP.dat;;
                                  "TKIP") sed -i 's/EncrypType=NONE/EncrypType=TKIP/g' /etc/Wireless/RT2860AP/RT2860AP.dat;;
                                  "CCMP TKIP") sed -i 's/EncrypType=NONE/EncrypType=TKIPAES/g' /etc/Wireless/RT2860AP/RT2860AP.dat;;
                        esac
		;;
		"wpawpa2")
        		sed -i 's/AuthMode=OPEN/AuthMode=WPAPSKWPA2PSK/g' /etc/Wireless/RT2860AP/RT2860AP.dat
                        case "$cipher_wlan0" in
                                  "CCMP") sed -i 's/EncrypType=NONE/EncrypType=AES/g' /etc/Wireless/RT2860AP/RT2860AP.dat;;
                                  "TKIP") sed -i 's/EncrypType=NONE/EncrypType=TKIP/g' /etc/Wireless/RT2860AP/RT2860AP.dat;;
                                  "CCMP TKIP") sed -i 's/EncrypType=NONE/EncrypType=TKIPAES/g' /etc/Wireless/RT2860AP/RT2860AP.dat;;
                        esac
		;;
	esac
        #ifconfig wlan0 up
        elif [ "$start_mode" = "1" ]; then
        echo "DBDC"
        # Create ap(11AC) 5GHz device
        wlanconfig wlan0 create wlandev wifi0 wlanmode ap

        # Encryption
        case "$auth_wlan0" in
		"wep")
        		sed -i 's/EncrypType=NONE/EncrypType=WEP/g' /etc/Wireless/RT2860AP/RT2860AP.dat
		;;
		"wpa")
        		sed -i 's/AuthMode=OPEN/AuthMode=WPAPSK/g' /etc/Wireless/RT2860AP/RT2860AP.dat
                        case "$cipher_wlan0" in
                                  "CCMP") sed -i 's/EncrypType=NONE/EncrypType=AES/g' /etc/Wireless/RT2860AP/RT2860AP.dat;;
                                  "TKIP") sed -i 's/EncrypType=NONE/EncrypType=TKIP/g' /etc/Wireless/RT2860AP/RT2860AP.dat;;
                                  "CCMP TKIP") sed -i 's/EncrypType=NONE/EncrypType=TKIPAES/g' /etc/Wireless/RT2860AP/RT2860AP.dat;;
                        esac
		;;	
		"wpa2")
        		sed -i 's/AuthMode=OPEN/AuthMode=WPA2PSK/g' /etc/Wireless/RT2860AP/RT2860AP.dat
                        case "$cipher_wlan0" in
                                  "CCMP") sed -i 's/EncrypType=NONE/EncrypType=AES/g' /etc/Wireless/RT2860AP/RT2860AP.dat;;
                                  "TKIP") sed -i 's/EncrypType=NONE/EncrypType=TKIP/g' /etc/Wireless/RT2860AP/RT2860AP.dat;;
                                  "CCMP TKIP") sed -i 's/EncrypType=NONE/EncrypType=TKIPAES/g' /etc/Wireless/RT2860AP/RT2860AP.dat;;
                        esac
		;;
		"wpawpa2")
        		sed -i 's/AuthMode=OPEN/AuthMode=WPAPSKWPA2PSK/g' /etc/Wireless/RT2860AP/RT2860AP.dat
                        case "$cipher_wlan0" in
                                  "CCMP") sed -i 's/EncrypType=NONE/EncrypType=AES/g' /etc/Wireless/RT2860AP/RT2860AP.dat;;
                                  "TKIP") sed -i 's/EncrypType=NONE/EncrypType=TKIP/g' /etc/Wireless/RT2860AP/RT2860AP.dat;;
                                  "CCMP TKIP") sed -i 's/EncrypType=NONE/EncrypType=TKIPAES/g' /etc/Wireless/RT2860AP/RT2860AP.dat;;
                        esac
		;;
	esac
        #ifconfig wlan0 up
        # Create ap(11N) 2.4Ghz device
	wlanconfig wlan1 create wlandev wifi1 wlanmode ap

        # Encryption
        case "$auth_wlan1" in
		"wep")
        		sed -i 's/EncrypType=NONE/EncrypType=WEP/g' /etc/Wireless/RT2860AP/RT2860AP.dat
		;;
		"wpa")
        		sed -i 's/AuthMode=OPEN/AuthMode=WPAPSK/g' /etc/Wireless/RT2860AP/RT2860AP.dat
                        case "$cipher_wlan1" in
                                  "CCMP") sed -i 's/EncrypType=NONE/EncrypType=AES/g' /etc/Wireless/RT2860AP/RT2860AP.dat;;
                                  "TKIP") sed -i 's/EncrypType=NONE/EncrypType=TKIP/g' /etc/Wireless/RT2860AP/RT2860AP.dat;;
                                  "CCMP TKIP") sed -i 's/EncrypType=NONE/EncrypType=TKIPAES/g' /etc/Wireless/RT2860AP/RT2860AP.dat;;
                        esac
		;;	
		"wpa2")
        		sed -i 's/AuthMode=OPEN/AuthMode=WPA2PSK/g' /etc/Wireless/RT2860AP/RT2860AP.dat
                        case "$cipher_wlan1" in
                                  "CCMP") sed -i 's/EncrypType=NONE/EncrypType=AES/g' /etc/Wireless/RT2860AP/RT2860AP.dat;;
                                  "TKIP") sed -i 's/EncrypType=NONE/EncrypType=TKIP/g' /etc/Wireless/RT2860AP/RT2860AP.dat;;
                                  "CCMP TKIP") sed -i 's/EncrypType=NONE/EncrypType=TKIPAES/g' /etc/Wireless/RT2860AP/RT2860AP.dat;;
                        esac
		;;
		"wpawpa2")
        		sed -i 's/AuthMode=OPEN/AuthMode=WPAPSKWPA2PSK/g' /etc/Wireless/RT2860AP/RT2860AP.dat
                        case "$cipher_wlan1" in
                                  "CCMP") sed -i 's/EncrypType=NONE/EncrypType=AES/g' /etc/Wireless/RT2860AP/RT2860AP.dat;;
                                  "TKIP") sed -i 's/EncrypType=NONE/EncrypType=TKIP/g' /etc/Wireless/RT2860AP/RT2860AP.dat;;
                                  "CCMP TKIP") sed -i 's/EncrypType=NONE/EncrypType=TKIPAES/g' /etc/Wireless/RT2860AP/RT2860AP.dat;;
                        esac
		;;
	esac
        #ifconfig wlan1 up
        echo "########## ifconfig wlan1 up ##########"
        fi

	# Apply any global radio config 
	[ "$first" = 1 ] && {
	    config_get hwmode "$device" hwmode
	    config_get txpower "$device" txpower
	    config_get country "$device" country
	    config_get channel "$device" channel

	    iwpriv "$ifname" mode $(find_hwmode $hwmode)
	    [ -z "$txpower" ] || {
		iwconfig "$ifname" txpower $txpower
	    }

	}
	# Apply the configuration
	config_get ssid "$device" ssid
	config_get hidden "$device" hidden
	config_get auth "$device" auth
	config_get wpapsk "$device" wpapsk
	config_get encryption "$device" encryption

	# * programming is apparently order sensitive!

        # Check A-Only mode
        if [ "$hwmode" = "11A" ]; then
                echo 5GHz 11A-Only
	        iwpriv "$ifname" mode $hwmode
        fi
        # Check HT bandwith / extension channel
        if [ "$hwmode" = "11NAHT40MINUS" ] && [ $htmode = "HT20" ]; then
                echo 802.11A/N-Mixed HT20
	        iwpriv "$ifname" mode 11NAHT20
        elif [ "$hwmode" = "11NAHT40MINUS" ] && [ $htmode = "HT40" ] && [ $ext_channel = "MINUS" ]; then
                echo 802.11A/N-Mixed HT40-
                iwpriv "$ifname" mode 11NAHT40MINUS
        elif [ "$hwmode" = "11NAHT40MINUS" ] && [ $htmode = "HT40" ] && [ $ext_channel = "PLUS" ]; then
                echo 802.11A/N-Mixed HT40+
                iwpriv "$ifname" mode 11NAHT40PLUS
	fi

	# 11AC/N/A mode
        if [ "$hwmode" = "11ACVHT80" ] && [ $htmode = "HT80" ]; then
                echo 5GHz 11AC/N/A HT80
                iwpriv "$ifname" mode $hwmode
	elif [ "$hwmode" = "11ACVHT80" ] && [ $htmode = "HT40" ]; then
		iwpriv "$ifname" mode 11ACVHT40
	elif [ "$hwmode" = "11ACVHT80" ] && [ $htmode = "HT20" ]; then
		iwpriv "$ifname" mode 11ACVHT20
        fi
	#iwpriv "$ifname" mode $hwmode
	iwpriv "$ifname" wds 1
	iwconfig "$ifname" essid $ssid
	#iwpriv "$ifname" set HtBw=$htmode
	#iwpriv "$ifname" set HtExtcha=$ext_channel
	iwconfig "$ifname" channel $channel
	iwpriv "$ifname" shortgi 1
	iwpriv "$ifname" ldpc 1
	iwpriv "$ifname" hide_ssid $hidden
	#iwpriv "$ifname" set AuthMode=$auth
	#iwpriv "$ifname" set EncrypType=$encryption
	#iwpriv "$ifname" set IEEE8021X=0
	#iwpriv "$ifname" set WPAPSK=$wpapsk
	#iwpriv "$ifname" set DefaultKeyID=2

	# AutoChannelSel
        if [ "$channel" = "auto" ]; then
        echo "AutoChannel"
        iwpriv "$ifname" set AutoChannelSel=2
        fi

	# MAC Filter
        config_get macpolicy "$ifname" macpolicy
        case "$macpolicy" in
                   "0")
			iwpriv "$ifname" maccmd 0
                        ;;
                   "1")
			iwpriv "$ifname" maccmd 1
                        ;;
                   "2")
			iwpriv "$ifname" maccmd 2
                        ;;
        esac
        config_get maclist "$ifname" maclist
        [ -n "$maclist" ] && {
                for mac in $maclist; do
                        echo "$mac"
			iwpriv "$ifname" addmac "$mac"
                done
        }
	
        # add it to the bridge to activate it
	local net_cfg bridge
	net_cfg="$(find_net_config "$vif")"
	[ -z "$net_cfg" ] || {
            bridge="$(bridge_interface "$net_cfg")"
            config_set "$vif" bridge "$bridge"
            start_net "$ifname" "$net_cfg"
	}
	set_wifi_up "$vif" "$ifname"

	# Hidden SSID
	iwpriv "$ifname" hide_ssid $hidden
        # bgn or n only: (don't let user pick tkip or rate auto drops to bg)
        #   open
        #   wpa     aes
        #   wpa2    aes
        #   wpawpa2 aes
        #
        # bg:
        #   open
        #   wep-open, wep-shared     40-bit, 104-bit (wep_key_mode=ascii, hex)
        #   wpa     aes, tkip, auto (auto means aes+tkip)
        #   wpa2    aes, tkip, auto (auto means aes+tkip)
        #   wpawpa2 aes, tkip, auto (auto means aes+tkip)

        config_get mode "$device" mode
        config_get auth "$device" auth
        config_get cipher "$device" encryption
        config_get wpapsk "$device" wpapsk
        config_get ifname "$vif" ifname

        local start_hostapd= vif_txpower= nosbeacon=
        config_get auth "$device" auth
        config_get ifname "$vif" ifname
        config_get enc "$device" wep_mode
        config_get eap_type "$device" eap_type
        config_get mode "$device" mode
        echo encryption=$encryption
        if [ "$auth" = "open" ]; then
                echo auth=open
        else
                local wep_key1=""
                local act_key=""
        case "$ifname" in
                "wlan0")
                case "$auth" in
                    "wep")
                                echo auth="============ WEP dev = $ifname, wep_mode = $enc ============="
				iwpriv "$ifname" set EncrypType=WEP
                                case "$enc" in
                                        1) iwpriv "$ifname" set AuthMode=OPEN;;
                                        2) iwpriv "$ifname" set AuthMode=SHARED;;
                                esac
				config_get key "wlan0" wep_key
				key="${key:-1}"
    				echo "wlan0 Primary key =$key"
    				case "$key" in
    					[1234]) iwpriv "$ifname" set DefaultKeyID=$key;;
				             *) iwpriv "$ifname" set DefaultKeyID=$key;;
    				esac

                                for idx in 1 2 3 4; do
                                        config_get key "wlan0" "key${idx}"
					iwpriv "$ifname" set Key$idx="${key:-off}"
                                        echo "============iwpriv "$ifname" set Key$idx="${key:-off}" ============="
                                done
                        ;;
                    "wpa")
                                echo auth="============ WPA-PSK ============="
                                iwpriv "$ifname" set AuthMode=WPAPSK
                                case "$cipher" in
                                        "CCMP") iwpriv "$ifname" set EncrypType=AES;;
                                        "TKIP") iwpriv "$ifname" set EncrypType=TKIP;;
                                        "CCMP TKIP") iwpriv "$ifname" set EncrypType=TKIPAES;;
                                esac
				iwpriv "$ifname" set IEEE8021X=0
                                        config_get key "$ifname" wpapsk
                                        config_get rekey "$ifname" rekey
                                        iwpriv "$ifname" set WPAPSK="${key:-off}"
					iwpriv "$ifname" set RekeyMethod=TIME
                                        iwpriv "$ifname" set RekeyInterval=$rekey
                                        echo "============iwpriv wlan0 set WPAPSK="${key:-off}"============="
                                        echo "============iwpriv wlan0 set RekeyInterval=$rekey============="
                        ;;
                    "wpa2")
                                echo auth="============ WPA2-PSK ============="
                                iwpriv "$ifname" set AuthMode=WPA2PSK
                                case "$cipher" in
                                        "CCMP") iwpriv "$ifname" set EncrypType=AES;;
                                        "TKIP") iwpriv "$ifname" set EncrypType=TKIP;;
                                        "CCMP TKIP") iwpriv "$ifname" set EncrypType=TKIPAES;;
                                esac
                                iwpriv "$ifname" set IEEE8021X=0
                                        config_get key "$ifname" wpapsk
                                        config_get rekey "$ifname" rekey
                                        iwpriv "$ifname" set WPAPSK="${key:-off}"
                                        iwpriv "$ifname" set RekeyMethod=TIME
                                        iwpriv "$ifname" set RekeyInterval=$rekey
                        ;;
                    "wpawpa2")
                                echo auth="============ WPA/WPA2-PSK ============="
                                iwpriv "$ifname" set AuthMode=WPAPSKWPA2PSK
                                case "$cipher" in
                                        "CCMP") iwpriv "$ifname" set EncrypType=AES;;
                                        "TKIP") iwpriv "$ifname" set EncrypType=TKIP;;
                                        "CCMP TKIP") iwpriv "$ifname" set EncrypType=TKIPAES;;
                                esac
                                iwpriv "$ifname" set IEEE8021X=0
                                        config_get key "$ifname" wpapsk
                                        config_get rekey "$ifname" rekey
                                        iwpriv "$ifname" set WPAPSK="${key:-off}"
                                        iwpriv "$ifname" set RekeyMethod=TIME
                                        iwpriv "$ifname" set RekeyInterval=$rekey
                                        echo "============iwpriv $ifname set WPAPSK="${key:-off}"============="
                                        echo "============iwpriv $ifname set RekeyInterval=$rekey============="
                        ;;
                esac
	        esac
        fi
	else
	echo "============== ifname = wlan1 =============="

        config_get channel "$device" channel
        config_get ssid "$device" ssid
        config_get ch_hi "$device" ch_hi
        config_get ch_lo "$device" ch_lo
        config_get macaddr "$device" macaddr
        config_get repeater "$device" repeater
        config_get hwmode "$device" hwmode
        config_get htmode "$device" htmode
        config_get ext_channel "$device" ext_channel
        config_get wps_pin "$vif" wps_pin
        config_get beacon_int "$device" beacon_int
        config_get country "$vif" country
        config_get vifs "$device" vifs

        # Apply any global radio config
        [ "$first" = 1 ] && {
            config_get hwmode "$device" hwmode
            config_get txpower "$device" txpower
            config_get country "$device" country
            config_get channel "$device" channel

            iwpriv "$ifname" mode $(find_hwmode $hwmode)
            [ -z "$txpower" ] || {
		 iwconfig "$ifname" txpower $txpower
            }

        }

        # Apply the configuration
        config_get ssid "$device" ssid
        config_get hidden "$device" hidden
        config_get auth "$device" auth
        config_get wpapsk "$device" wpapsk
        config_get encryption "$device" encryption

        # * programming is apparently order sensitive!
        # Check N-Only mode
        if [ "$hwmode" = "11NGHT40PLUS" ]; then
                echo 2.4GHz 11N-Only
        iwpriv "$ifname" mode $hwmode
        iwpriv "$ifname" puren 1
        else
        iwpriv "$ifname" puren 0
        fi
        # Check G-Only mode
        if [ "$hwmode" = "pureg" ]; then
                echo 2.4GHz 11G-Only
        iwpriv "$ifname" mode $hwmode
        iwpriv "$ifname" pureg 1
        else
        iwpriv "$ifname" mode $hwmode
        iwpriv "$ifname" pureg 0
        fi
        # Check HT bandwith / extension channel
        if [ "$hwmode" = "11NGHT40MINUS" ] && [ $htmode = "HT20" ]; then
                echo 802.11B/G/N-Mixed HT20
        iwpriv "$ifname" mode 11NGHT20
        elif [ "$hwmode" = "11NGHT40MINUS" ] && [ $htmode = "HT40" ] && [ $ext_channel = "MINUS" ]; then
                echo 802.11B/G/N-Mixed HT40-
        iwpriv "$ifname" mode 11NGHT40MINUS
        elif [ "$hwmode" = "11NGHT40MINUS" ] && [ $htmode = "HT40" ] && [ $ext_channel = "PLUS" ]; then
                echo 802.11B/G/N-Mixed HT40+
        iwpriv "$ifname" mode 11NGHT40PLUS
        # 11N-Only
        elif [ "$hwmode" = "11NGHT40PLUS" ] && [ $htmode = "HT20" ]; then
                echo 802.11N-Only HT20
        iwpriv "$ifname" mode 11NGHT20
        elif [ "$hwmode" = "11NGHT40PLUS" ] && [ $htmode = "HT40" ] && [ $ext_channel = "MINUS" ]; then
                echo 802.11N-Only HT40-
        iwpriv "$ifname" mode 11NGHT40MINUS
        elif [ "$hwmode" = "11NGHT40PLUS" ] && [ $htmode = "HT40" ] && [ $ext_channel = "PLUS" ]; then
                echo 802.11N-Only HT40+
        iwpriv "$ifname" mode 11NGHT40PLUS
        fi
        #iwpriv "$ifname" mode $hwmode
        #iwpriv "$ifname" wds 1
        iwconfig "$ifname" essid $ssid
        #iwpriv "$ifname" set HtBw=$htmode
        #iwpriv "$ifname" set HtExtcha=$ext_channel
        iwconfig "$ifname" channel $channel
        iwpriv "$ifname" shortgi 1
        #iwpriv "$ifname" ldpc 1
        iwpriv "$ifname" hide_ssid $hidden
	iwpriv "$ifname" disablecoext 1
	iwpriv "$ifname" chwidth 2
        #iwpriv "$ifname" set AuthMode=$auth
        #iwpriv "$ifname" set EncrypType=$encryption
        #iwpriv "$ifname" set IEEE8021X=0
        #iwpriv "$ifname" set WPAPSK=$wpapsk
        #iwpriv "$ifname" set DefaultKeyID=2

        # AutoChannelSel
        if [ "$channel" = "auto" ]; then
        echo "AutoChannel"
        #iwpriv "$ifname" set AutoChannelSel=2
        fi

        # MAC Filter
        config_get macpolicy "$ifname" macpolicy
        case "$macpolicy" in
                   "0")
                        iwpriv "$ifname" maccmd 0
                        ;;
                   "1")
                        iwpriv "$ifname" maccmd 1
                        ;;
                   "2")
                        iwpriv "$ifname" maccmd 2
                        ;;
        esac
        config_get maclist "$ifname" maclist
        [ -n "$maclist" ] && {
                for mac in $maclist; do
                        echo "$mac"
                        iwpriv "$ifname" addmac "$mac"
                done
        }

        # add it to the bridge to activate it
        config_get start_mode "wlan0" start_mode
        if [ "$start_mode" = "1" ]; then
	#ifconfig wlan1 up
	brctl addif br-lan wlan1
	fi

        # bgn or n only: (don't let user pick tkip or rate auto drops to bg)
        #   open
        #   wpa     aes
        #   wpa2    aes
        #   wpawpa2 aes
        #
        # bg:
        #   open
        #   wep-open, wep-shared     40-bit, 104-bit (wep_key_mode=ascii, hex)
        #   wpa     aes, tkip, auto (auto means aes+tkip)
        #   wpa2    aes, tkip, auto (auto means aes+tkip)
        #   wpawpa2 aes, tkip, auto (auto means aes+tkip)

        config_get mode "$device" mode
        config_get auth "$device" auth
        config_get cipher "$device" encryption
        config_get wpapsk "$device" wpapsk
        config_get ifname "$vif" ifname

        local start_hostapd= vif_txpower= nosbeacon=
        config_get auth "$device" auth
        config_get ifname "$vif" ifname
        config_get enc "$device" wep_mode
        config_get eap_type "$device" eap_type
        config_get mode "$device" mode
        echo encryption=$encryption
        if [ "$auth" = "open" ]; then
                echo ")))))))))))) auth=open ((((((((((((("
        else
                local wep_key1=""
                local act_key=""
        case "$ifname" in
                "wlan1")
                case "$auth" in
                    "wep")
                                echo auth="============ WEP dev = $ifname, wep_mode = $enc ============="
                                iwpriv "$ifname" set EncrypType=WEP
                                case "$enc" in
                                        1) iwpriv "$ifname" set AuthMode=OPEN;;
                                        2) iwpriv "$ifname" set AuthMode=SHARED;;
                                esac
                                config_get key "$ifname" wep_key
                                key="${key:-1}"
                                echo "wlan0 Primary key =$key"
                                case "$key" in
                                        [1234]) iwpriv "$ifname" set DefaultKeyID=$key;;
                                             *) iwpriv "$ifname" set DefaultKeyID=$key;;
                                esac

                                for idx in 1 2 3 4; do
                                        config_get key "$ifname" "key${idx}"
                                        iwpriv "$ifname" set Key$idx="${key:-off}"
                                        echo "============iwpriv "$ifname" set Key$idx="${key:-off}" ============="
                                done
                        ;;
                    "wpa")
                                echo auth="============ WPA-PSK ============="
                                iwpriv "$ifname" set AuthMode=WPAPSK
                                case "$cipher" in
                                        "CCMP") iwpriv "$ifname" set EncrypType=AES;;
                                        "TKIP") iwpriv "$ifname" set EncrypType=TKIP;;
                                        "CCMP TKIP") iwpriv "$ifname" set EncrypType=TKIPAES;;
                                esac
                                iwpriv "$ifname" set IEEE8021X=0
                                        config_get key "$ifname" wpapsk
                                        config_get rekey "$ifname" rekey
                                        iwpriv "$ifname" set WPAPSK="${key:-off}"
                                        iwpriv "$ifname" set RekeyMethod=TIME
                                        iwpriv "$ifname" set RekeyInterval=$rekey
                                        echo "============iwpriv $ifname set WPAPSK="${key:-off}"============="
                                        echo "============iwpriv $ifname set RekeyInterval=$rekey============="
                        ;;
                    "wpa2")
                                echo auth="============ WPA2-PSK ============="
                                iwpriv "$ifname" set AuthMode=WPA2PSK
                                case "$cipher" in
                                        "CCMP") iwpriv "$ifname" set EncrypType=AES;;
                                        "TKIP") iwpriv "$ifname" set EncrypType=TKIP;;
                                        "CCMP TKIP") iwpriv "$ifname" set EncrypType=TKIPAES;;
                                esac
                                iwpriv "$ifname" set IEEE8021X=0
                                        config_get key "$ifname" wpapsk
                                        config_get rekey "$ifname" rekey
                                        iwpriv "$ifname" set WPAPSK="${key:-off}"
                                        iwpriv "$ifname" set RekeyMethod=TIME
                                        iwpriv "$ifname" set RekeyInterval=$rekey
                        ;;
                    "wpawpa2")
                                echo auth="============ WPA/WPA2-PSK ============="
                                iwpriv "$ifname" set AuthMode=WPAPSKWPA2PSK
                                case "$cipher" in
                                        "CCMP") iwpriv "$ifname" set EncrypType=AES;;
                                        "TKIP") iwpriv "$ifname" set EncrypType=TKIP;;
                                        "CCMP TKIP") iwpriv "$ifname" set EncrypType=TKIPAES;;
                                esac
                                iwpriv "$ifname" set IEEE8021X=0
                                        config_get key "$ifname" wpapsk
                                        config_get rekey "$ifname" rekey
                                        iwpriv "$ifname" set WPAPSK="${key:-off}"
                                        iwpriv "$ifname" set RekeyMethod=TIME
                                        iwpriv "$ifname" set RekeyInterval=$rekey
                                        echo "============iwpriv $ifname set WPAPSK="${key:-off}"============="
                                        echo "============iwpriv $ifname set RekeyInterval=$rekey============="
                        ;;
                esac
		esac
	   fi
	ifconfig wlan1 up
        first=0
    fi
    done
}

# The /etc/config/network lan interface 
# must contain:
#  option type bridge
#
detect_ar9880() {
    cd /sys/class/net
    for dev in $(ls -d ra* 2>&-); do
	cat <<EOF
config 'wifi-device' 'wlan0'
        option 'type' 'ar9880'
        option 'country' '1'
        option 'beacon_int' '100'
        option 'repeater' '0'
        option 'disabled' '0'
        option 'preamble' 'long'
        option 'protection' 'none'
        option 'hidden' '0'
        option 'txpower' '22'
        option 'auth' 'open'
        option 'wfo_ar9880' '0'
        option 'ssid' 'ika_test'
        option 'macpolicy' '0'
        option 'start_mode' '1'
        option 'hwmode' '11ACVHT80'
        option 'channel' '48'
        option 'htmode' 'HT80'
        option 'ext_channel' 'MINUS'

config 'wifi-iface'
        option 'device' 'wlan0'
        option 'network' 'lan'
        option 'mode' 'ap'
        option 'wds_enable' '0'
        option 'wps_enable' '0'
        option 'wps_pin' '00000000'

config 'wifi-device' 'wlan1'
        option 'type' 'ar9880'
        option 'country' '1'
        option 'beacon_int' '100'
        option 'repeater' '0'
        option 'disabled' '0'
        option 'preamble' 'long'
        option 'protection' 'none'
        option 'hidden' '0'
        option 'txpower' '22'
        option 'auth' 'open'
        option 'macpolicy' '0'
        option 'hwmode' '11NGHT40MINUS'
        option 'htmode' 'HT40'
        option 'ext_channel' 'PLUS'
        option 'channel' '9'
        option 'ssid' 'QCA_AR9380'

config 'wifi-iface'
        option 'device' 'wlan1'
        option 'network' 'lan'
        option 'mode' 'ap'
        option 'wds_enable' '0'
        option 'wps_enable' '0'
        option 'wps_pin' '00000000'
        option 'auth_server' '192.168.2.100'
        option 'auth_port' '1812'
        option 'auth_secret' 'testing123'

config 'wifi-wds'
        option 'device' 'wlan0-wds0'

EOF
    done
}

# Helper functions
#
find_hwmode() {
    local str="$1"
    local i=0
    # default to 11bgn
    local num=9
    for mode in 11bg 11b 11a x 11g x 11n 11gn 11an 11bgn 11agn 11n5g; do
	if [ "$mode" = "$str" ]; then
	    num=$i
	fi
	i=$((${i:-0} + 1))
    done
    echo $num
}
