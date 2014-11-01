# This is the OpenWRT "driver" for the rt3593.
#
append DRIVERS "rt3593"

SCRIPT_DIR=/etc/cs75xx/hw_accel/demo

# I guess this routine scans for correct configuration,
# and can attach additional information to the cfg structs.
# See the following files for examples:
#  openwrt-2.4.2011-trunk/package/broadcom-wl/files/lib/wifi/broadcom.sh
#  openwrt-2.4.2011-trunk/package/madwifi/files/lib/wifi/madwifi.sh
#  openwrt-2.4.2011-trunk/package/acx/files/lib/wifi/acx.sh
#
scan_rt3593() {
    local device="$1"

    config_get vifs "$device" vifs
    for vif in $vifs; do
        config_get ifname "$vif" ifname
        config_set "$vif" ifname "${ifname:-$device}"
    done
}

# Disable the device and remove from
# the bridge.
disable_rt3593() {
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
enable_rt3593() {
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

        if [ "$device" = "ra0" ]; then
        echo "============== device=ra0 =============="

        # AP Start Mode settings
        config_get start_mode "ra0" start_mode
        config_get hidden_ra0 "ra0" hidden
        config_get hidden_ra1 "ra1" hidden
        config_get auth_ra0 "ra0" auth
        config_get auth_ra1 "ra1" auth
        config_get cipher_ra0 "ra0" encryption
        config_get cipher_ra1 "ra1" encryption
        config_get wfo_rt3593 "ra0" wfo_rt3593
        config_get mode_id "ra0" mode_id
	# WFO 
        if [ "$wfo_rt3593" = "1" ]; then
        echo "=========== WFO Applied ============"
        lsmod | grep rt3593ap_cs >& /dev/null
        if [ $? -eq 0 ]; then
        echo "rt3593ap_cs has been loaded, remove first!"
	# Shutdown all WiFi interface
	ifconfig ra0 down
	ifconfig ra1 down
	# Remove normal driver	
	/rboot/rboot wfo_pe0.bin wfo_pe1.bin
	rmmod rt3593ap_cs
	sleep 2
	insmod /lib/modules/2.6.36/rt3593ap_wfo.ko
	echo 1 > /proc/driver/cs752x/wfo/wifi_offload_enable
	fi	

	# Install WFO driver
        /rboot/rboot wfo_pe0.bin wfo_pe1.bin
        sleep 2
        insmod /lib/modules/2.6.36/rt3593ap_wfo.ko
        echo 1 > /proc/driver/cs752x/wfo/wifi_offload_enable

	# Restart WFO procedure
	echo 0 > /proc/driver/cs752x/wfo/wifi_offload_enable
	/rboot/rboot /rboot/wfo_ralink/wfo_pe0.bin /rboot/wfo_ralink/wfo_pe1.bin
	echo 1 > /proc/driver/cs752x/wfo/wifi_offload_enable
	cd /rboot/wfo_ralink/
	cp RT2860AP-2.4G.dat /etc/Wireless/RT2860AP/RT2860AP.dat

        # MODE_ID w/ WFO
        case "$mode_id" in
                "8")
			echo " MODE_ID has been changed to 8, please reboot system"
			echo $mode_id > $SCRIPT_DIR/mode_id
		        #echo "Disable PKT_BUF for QM"
		        #fw_setenv QM_INT_BUFF 0
		        sleep 1
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
                        echo " MODE_ID has been changed to 9, please reboot system"
			echo $mode_id > $SCRIPT_DIR/mode_id
                        #echo "Disable PKT_BUF for QM"
                        #fw_setenv QM_INT_BUFF 0
                        sleep 1
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
                        echo " MODE_ID has been changed to 10, please reboot system"
			echo $mode_id > $SCRIPT_DIR/mode_id
                        #echo "Disable PKT_BUF for QM"
                        #fw_setenv QM_INT_BUFF 0
                        sleep 1
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
		        $SCRIPT_DIR/set_openswan_application.sh
                ;;
                "12")
                        echo " MODE_ID has been changed to 12, please reboot system"
			echo $mode_id > $SCRIPT_DIR/mode_id
		        #echo "Disable PKT_BUF for QM"
		        #fw_setenv QM_INT_BUFF 0
		        sleep 1
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
		        $SCRIPT_DIR/set_ipsec_network.sh 0      # IPSEC HW Acceleration: 0
                ;;
        esac
	else
	echo "=========== WFO Disabled ============"
        ifconfig ra0 down
        ifconfig ra1 down
	# Remove WFO driver
	rmmod rt3593ap_wfo
	sleep 2

        # MODE_ID w/o WFO
        case "$mode_id" in
                "-1")
                        echo " MODE_ID has been changed to -1, please reboot system"
                        echo $mode_id > $SCRIPT_DIR/mode_id
                        #echo "Enable PKT_BUF for QM"
                        #fw_setenv QM_INT_BUFF 256
                        sleep 1
                        echo "  WFO(Bridge Mode):       N/A"
                        echo "  load rt3593ap_wfo.ko	   "
                        echo "  IPSEC(HW ENCP/DECP):    N/A"
                        echo "  L2TP:                   N/A"
                        echo "  NAT(HW):                Enabled"
                        echo "  hw_accel_enable:        0xf0ff"
                        sleep 1
                        echo 0xf0ff > /proc/driver/cs752x/ne/accel_manager/hw_accel_enable
                        sleep 1
                ;;
                "0")
                        echo " MODE_ID has been changed to 0, please reboot system"
                        echo $mode_id > $SCRIPT_DIR/mode_id
                        #echo "Enable PKT_BUF for QM"
                        #fw_setenv QM_INT_BUFF 256
                        sleep 1
                        echo "  WFO(Bridge Mode):       Disable"
                        echo "          load rt3593ap_cs.ko"
                        echo "  IPSEC(HW ENCP/DECP):    N/A"
                        echo "  L2TP:                   N/A"
                        echo "  NAT(HW):                Enable"
                        echo "  hw_accel_enable:        0x71FF"
                        sleep 1
                        echo 0 > /proc/driver/cs752x/ne/accel_manager/hw_accel_enable
                        sleep 1
                ;;
                "1")
                        echo " MODE_ID has been changed to 1, please reboot system"
                        echo $mode_id > $SCRIPT_DIR/mode_id
                        #echo "Enable PKT_BUF for QM"
                        #fw_setenv QM_INT_BUFF 256
                        sleep 1
		        echo "  WFO(Bridge Mode):       Disable"
		        echo "          load rt3593ap_cs.ko"
		        echo "  IPSEC(HW ENCP/DECP):    N/A"
		        echo "  L2TP:                   N/A"
		        echo "  NAT(HW):                Enable"
		        echo "  hw_accel_enable:        0x71FF"
		        sleep 1
		        echo 0xf0ff > /proc/driver/cs752x/ne/accel_manager/hw_accel_enable
		        sleep 1
		        #$SCRIPT_DIR/set_default_network.sh
		        #$SCRIPT_DIR/set_wifi_network.sh 0               # WiFi-Offload: 0
                ;;
	esac
	# Install Normal driver
	insmod /lib/modules/2.6.36/rt3593ap_cs.ko
	echo 0 > /proc/driver/cs752x/wfo/wifi_offload_enable
	fi
	# End of WFO

        if [ "$start_mode" = "0" ]; then
        echo "Single mode"
        # device must be up before config can be applied
	cd /rboot/wfo_ralink/
	cp RT2860AP-2.4G.dat /etc/Wireless/RT2860AP/RT2860AP.dat
	# Hiddden SSID
	if [ "$hidden_ra0" = "0" ]; then
	sed -i 's/HideSSID=1/HideSSID=0/g' /etc/Wireless/RT2860AP/RT2860AP.dat
	else
	sed -i 's/HideSSID=0/HideSSID=1/g' /etc/Wireless/RT2860AP/RT2860AP.dat
	fi
        # Encryption
        case "$auth_ra0" in
		"wep")
        		sed -i 's/EncrypType=NONE/EncrypType=WEP/g' /etc/Wireless/RT2860AP/RT2860AP.dat
		;;
		"wpa")
        		sed -i 's/AuthMode=OPEN/AuthMode=WPAPSK/g' /etc/Wireless/RT2860AP/RT2860AP.dat
                        case "$cipher_ra0" in
                                  "CCMP") sed -i 's/EncrypType=NONE/EncrypType=AES/g' /etc/Wireless/RT2860AP/RT2860AP.dat;;
                                  "TKIP") sed -i 's/EncrypType=NONE/EncrypType=TKIP/g' /etc/Wireless/RT2860AP/RT2860AP.dat;;
                                  "CCMP TKIP") sed -i 's/EncrypType=NONE/EncrypType=TKIPAES/g' /etc/Wireless/RT2860AP/RT2860AP.dat;;
                        esac
		;;	
		"wpa2")
        		sed -i 's/AuthMode=OPEN/AuthMode=WPA2PSK/g' /etc/Wireless/RT2860AP/RT2860AP.dat
                        case "$cipher_ra0" in
                                  "CCMP") sed -i 's/EncrypType=NONE/EncrypType=AES/g' /etc/Wireless/RT2860AP/RT2860AP.dat;;
                                  "TKIP") sed -i 's/EncrypType=NONE/EncrypType=TKIP/g' /etc/Wireless/RT2860AP/RT2860AP.dat;;
                                  "CCMP TKIP") sed -i 's/EncrypType=NONE/EncrypType=TKIPAES/g' /etc/Wireless/RT2860AP/RT2860AP.dat;;
                        esac
		;;
		"wpawpa2")
        		sed -i 's/AuthMode=OPEN/AuthMode=WPAPSKWPA2PSK/g' /etc/Wireless/RT2860AP/RT2860AP.dat
                        case "$cipher_ra0" in
                                  "CCMP") sed -i 's/EncrypType=NONE/EncrypType=AES/g' /etc/Wireless/RT2860AP/RT2860AP.dat;;
                                  "TKIP") sed -i 's/EncrypType=NONE/EncrypType=TKIP/g' /etc/Wireless/RT2860AP/RT2860AP.dat;;
                                  "CCMP TKIP") sed -i 's/EncrypType=NONE/EncrypType=TKIPAES/g' /etc/Wireless/RT2860AP/RT2860AP.dat;;
                        esac
		;;
	esac
        ifconfig ra0 up
        elif [ "$start_mode" = "1" ]; then
        echo "DBDC"
        # 2.4 GHz
        cd /rboot/wfo_ralink/
        cp RT2860AP-2.4G.dat /etc/Wireless/RT2860AP/RT2860AP.dat
        if [ "$hidden_ra0" = "0" ]; then
        sed -i 's/HideSSID=1/HideSSID=0/g' /etc/Wireless/RT2860AP/RT2860AP.dat
        else
        sed -i 's/HideSSID=0/HideSSID=1/g' /etc/Wireless/RT2860AP/RT2860AP.dat
        fi
        # Encryption
        case "$auth_ra0" in
		"wep")
        		sed -i 's/EncrypType=NONE/EncrypType=WEP/g' /etc/Wireless/RT2860AP/RT2860AP.dat
		;;
		"wpa")
        		sed -i 's/AuthMode=OPEN/AuthMode=WPAPSK/g' /etc/Wireless/RT2860AP/RT2860AP.dat
                        case "$cipher_ra0" in
                                  "CCMP") sed -i 's/EncrypType=NONE/EncrypType=AES/g' /etc/Wireless/RT2860AP/RT2860AP.dat;;
                                  "TKIP") sed -i 's/EncrypType=NONE/EncrypType=TKIP/g' /etc/Wireless/RT2860AP/RT2860AP.dat;;
                                  "CCMP TKIP") sed -i 's/EncrypType=NONE/EncrypType=TKIPAES/g' /etc/Wireless/RT2860AP/RT2860AP.dat;;
                        esac
		;;	
		"wpa2")
        		sed -i 's/AuthMode=OPEN/AuthMode=WPA2PSK/g' /etc/Wireless/RT2860AP/RT2860AP.dat
                        case "$cipher_ra0" in
                                  "CCMP") sed -i 's/EncrypType=NONE/EncrypType=AES/g' /etc/Wireless/RT2860AP/RT2860AP.dat;;
                                  "TKIP") sed -i 's/EncrypType=NONE/EncrypType=TKIP/g' /etc/Wireless/RT2860AP/RT2860AP.dat;;
                                  "CCMP TKIP") sed -i 's/EncrypType=NONE/EncrypType=TKIPAES/g' /etc/Wireless/RT2860AP/RT2860AP.dat;;
                        esac
		;;
		"wpawpa2")
        		sed -i 's/AuthMode=OPEN/AuthMode=WPAPSKWPA2PSK/g' /etc/Wireless/RT2860AP/RT2860AP.dat
                        case "$cipher_ra0" in
                                  "CCMP") sed -i 's/EncrypType=NONE/EncrypType=AES/g' /etc/Wireless/RT2860AP/RT2860AP.dat;;
                                  "TKIP") sed -i 's/EncrypType=NONE/EncrypType=TKIP/g' /etc/Wireless/RT2860AP/RT2860AP.dat;;
                                  "CCMP TKIP") sed -i 's/EncrypType=NONE/EncrypType=TKIPAES/g' /etc/Wireless/RT2860AP/RT2860AP.dat;;
                        esac
		;;
	esac
        ifconfig ra0 up
        echo "########## ifconfig ra0 up ##########"
        #5 GHz
        cp RT2860AP-5G.dat /etc/Wireless/RT2860AP/RT2860AP.dat
        if [ "$hidden_ra1" = "0" ]; then
        sed -i 's/HideSSID=1/HideSSID=0/g' /etc/Wireless/RT2860AP/RT2860AP.dat
        else
        sed -i 's/HideSSID=0/HideSSID=1/g' /etc/Wireless/RT2860AP/RT2860AP.dat
        fi
        # Encryption
        case "$auth_ra1" in
		"wep")
        		sed -i 's/EncrypType=NONE/EncrypType=WEP/g' /etc/Wireless/RT2860AP/RT2860AP.dat
		;;
		"wpa")
        		sed -i 's/AuthMode=OPEN/AuthMode=WPAPSK/g' /etc/Wireless/RT2860AP/RT2860AP.dat
                        case "$cipher_ra1" in
                                  "CCMP") sed -i 's/EncrypType=NONE/EncrypType=AES/g' /etc/Wireless/RT2860AP/RT2860AP.dat;;
                                  "TKIP") sed -i 's/EncrypType=NONE/EncrypType=TKIP/g' /etc/Wireless/RT2860AP/RT2860AP.dat;;
                                  "CCMP TKIP") sed -i 's/EncrypType=NONE/EncrypType=TKIPAES/g' /etc/Wireless/RT2860AP/RT2860AP.dat;;
                        esac
		;;	
		"wpa2")
        		sed -i 's/AuthMode=OPEN/AuthMode=WPA2PSK/g' /etc/Wireless/RT2860AP/RT2860AP.dat
                        case "$cipher_ra1" in
                                  "CCMP") sed -i 's/EncrypType=NONE/EncrypType=AES/g' /etc/Wireless/RT2860AP/RT2860AP.dat;;
                                  "TKIP") sed -i 's/EncrypType=NONE/EncrypType=TKIP/g' /etc/Wireless/RT2860AP/RT2860AP.dat;;
                                  "CCMP TKIP") sed -i 's/EncrypType=NONE/EncrypType=TKIPAES/g' /etc/Wireless/RT2860AP/RT2860AP.dat;;
                        esac
		;;
		"wpawpa2")
        		sed -i 's/AuthMode=OPEN/AuthMode=WPAPSKWPA2PSK/g' /etc/Wireless/RT2860AP/RT2860AP.dat
                        case "$cipher_ra1" in
                                  "CCMP") sed -i 's/EncrypType=NONE/EncrypType=AES/g' /etc/Wireless/RT2860AP/RT2860AP.dat;;
                                  "TKIP") sed -i 's/EncrypType=NONE/EncrypType=TKIP/g' /etc/Wireless/RT2860AP/RT2860AP.dat;;
                                  "CCMP TKIP") sed -i 's/EncrypType=NONE/EncrypType=TKIPAES/g' /etc/Wireless/RT2860AP/RT2860AP.dat;;
                        esac
		;;
	esac
        ifconfig ra1 up
        echo "########## ifconfig ra1 up ##########"
        fi

	# Apply any global radio config 
	[ "$first" = 1 ] && {
	    config_get hwmode "$device" hwmode
	    config_get txpower "$device" txpower
	    config_get country "$device" country
	    config_get channel "$device" channel

	    iwpriv "$ifname" set WirelessMode=$(find_hwmode $hwmode)
	    [ -z "$txpower" ] || {
		iwpriv "$ifname" set TxPower=$txpower
	    }

	}
	# Apply the configuration
	config_get ssid "$device" ssid
	config_get hidden "$device" hidden
	config_get auth "$device" auth
	config_get wpapsk "$device" wpapsk
	config_get encryption "$device" encryption

	# * programming is apparently order sensitive!
	iwpriv "$ifname" set WirelessMode=$hwmode
	iwpriv "$ifname" set SSID=$ssid
	iwpriv "$ifname" set HtBw=$htmode
	iwpriv "$ifname" set HtExtcha=$ext_channel
	iwpriv "$ifname" set Channel=$channel
	#iwpriv "$ifname" set HideSSID=$hidden
	iwpriv "$ifname" set AuthMode=$auth
	iwpriv "$ifname" set EncrypType=$encryption
	iwpriv "$ifname" set IEEE8021X=0
	iwpriv "$ifname" set WPAPSK=$wpapsk
	iwpriv "$ifname" set DefaultKeyID=2

	# AutoChannelSel
        if [ "$channel" = "auto" ]; then
        echo "AutoChannel"
        iwpriv "$ifname" set AutoChannelSel=2
        fi

	# MAC Filter
        config_get macpolicy "$ifname" macpolicy
        case "$macpolicy" in
                   "0")
			iwpriv "$ifname" set AccessPolicy=0
                        ;;
                   "1")
			iwpriv "$ifname" set AccessPolicy=1
                        ;;
                   "2")
			iwpriv "$ifname" set AccessPolicy=2
                        ;;
        esac
        config_get maclist "$ifname" maclist
        [ -n "$maclist" ] && {
                for mac in $maclist; do
                        #echo "$mac"
			iwpriv "$ifname" set ACLAddEntry="$mac"
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
                "ra0")
                case "$auth" in
                    "wep")
                                echo auth="============ WEP dev = $ifname, wep_mode = $enc ============="
				iwpriv "$ifname" set EncrypType=WEP
                                case "$enc" in
                                        1) iwpriv "$ifname" set AuthMode=OPEN;;
                                        2) iwpriv "$ifname" set AuthMode=SHARED;;
                                esac
				config_get key "ra0" wep_key
				key="${key:-1}"
    				echo "ra0 Primary key =$key"
    				case "$key" in
    					[1234]) iwpriv "$ifname" set DefaultKeyID=$key;;
				             *) iwpriv "$ifname" set DefaultKeyID=$key;;
    				esac

                                for idx in 1 2 3 4; do
                                        config_get key "ra0" "key${idx}"
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
                                        echo "============iwpriv ra0 set WPAPSK="${key:-off}"============="
                                        echo "============iwpriv ra0 set RekeyInterval=$rekey============="
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
	echo "============== ifname = ra1 =============="

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

            iwpriv "$ifname" set WirelessMode=$(find_hwmode $hwmode)
            [ -z "$txpower" ] || {
                iwpriv "$ifname" set TxPower=$txpower
		echo "========== iwpriv "$ifname" set TxPower=$txpower ==========="
            }

        }

        # Apply the configuration
        config_get ssid "$device" ssid
        config_get hidden "$device" hidden
        config_get auth "$device" auth
        config_get wpapsk "$device" wpapsk
        config_get encryption "$device" encryption

        # * programming is apparently order sensitive!
        iwpriv "$ifname" set WirelessMode=$hwmode
        iwpriv "$ifname" set SSID=$ssid
        iwpriv "$ifname" set HtBw=$htmode
        iwpriv "$ifname" set HtExtcha=$ext_channel
        iwpriv "$ifname" set Channel=$channel
        #iwpriv "$ifname" set HideSSID=$hidden
        iwpriv "$ifname" set AuthMode=$auth
        iwpriv "$ifname" set EncrypType=$encryption
        iwpriv "$ifname" set IEEE8021X=0
        iwpriv "$ifname" set WPAPSK=$wpapsk
        iwpriv "$ifname" set DefaultKeyID=2

        # AutoChannelSel
        if [ "$channel" = "auto" ]; then
        echo "AutoChannel"
        iwpriv "$ifname" set AutoChannelSel=2
        fi

        # MAC Filter
        config_get macpolicy "$ifname" macpolicy
        case "$macpolicy" in
                   "0")
                        iwpriv "$ifname" set AccessPolicy=0
                        ;;
                   "1")
                        iwpriv "$ifname" set AccessPolicy=1
                        ;;
                   "2")
                        iwpriv "$ifname" set AccessPolicy=2
                        ;;
        esac
        config_get maclist "$ifname" maclist
        [ -n "$maclist" ] && {
                for mac in $maclist; do
                        #echo "$mac"
                        iwpriv "$ifname" set ACLAddEntry="$mac"
			echo "============== iwpriv "$ifname" set ACLAddEntry="$mac" =============="
                done
        }

        # add it to the bridge to activate it
        config_get start_mode "ra0" start_mode
        if [ "$start_mode" = "1" ]; then
	brctl addif br-lan ra1
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
                "ra1")
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
                                echo "ra0 Primary key =$key"
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
        first=0
    fi
    done
}

# The /etc/config/network lan interface 
# must contain:
#  option type bridge
#
detect_rt3593() {
    cd /sys/class/net
    for dev in $(ls -d ra* 2>&-); do
	cat <<EOF
config 'wifi-device' 'ra0'
        option 'type' 'rt3593'
        option 'country' '1'
        option 'beacon_int' '100'
        option 'repeater' '0'
        option 'disabled' '0'
        option 'preamble' 'long'
        option 'protection' 'none'
        option 'hidden' '0'
        option 'hwmode' '9'
        option 'htmode' '1'
        option 'ext_channel' '0'
        option 'ssid' 'Ralink_2.4G'
        option 'txpower' '100'
        option 'start_mode' '1'
        option 'macpolicy' '0'
        option 'mode_id' '-1'
        option 'channel' '6'
        option 'auth' 'open'
        option 'rekey' '3600'

config 'wifi-iface'
        option 'device' 'ra0'
        option 'network' 'lan'
        option 'mode' 'ap'
        option 'wds_enable' '0'
        option 'wps_enable' '0'
        option 'wps_pin' '00000000'

config 'wifi-device' 'ra1'
        option 'type' 'rt3593'
        option 'country' '1'
        option 'beacon_int' '100'
        option 'repeater' '0'
        option 'disabled' '0'
        option 'preamble' 'long'
        option 'protection' 'none'
        option 'hidden' '0'
        option 'ssid' 'Ralink_5G'
        option 'txpower' '100'
        option 'auth' 'open'
        option 'htmode' '1'
        option 'ext_channel' '0'
        option 'hwmode' '8'
        option 'macpolicy' '0'
        option 'channel' '40'
        option 'rekey' '3600'

config 'wifi-iface'
        option 'device' 'ra1'
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
