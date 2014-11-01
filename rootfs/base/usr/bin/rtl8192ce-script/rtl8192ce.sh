# This is the OpenWRT "driver" for the rtl8192ce.
#
append DRIVERS "rtl8192ce"

# The RealTek scripts have been installed here:
#
RTSCRIPTS=/usr/bin/rtl8192ce-script

# rtl8192ce comes with its own version of iwpriv.  If we do any
# direct programming, we'll use these macros.
#
CE_IWPRIV=$RTSCRIPTS/iwpriv
CE_SET=set_mib

# Make sure that when we call the scripts, iwpriv is taken from
# the right place, just incase multiple versions are installed.
#
export PATH=/sbin:$PATH

#####################################################################################
#
# The RealTek driver comes with a set of scripts that manage default configuration
# variables and program the driver.  The trick is to combine this with OpenWrt
# convensions so OpenWrt works as expected, while still taking advantage of the
# implied correctness of the scripts from RealTek.
#
# The way the RealTek scripts work is the following:  First there are two scripts
# that are run that set up all of the default config values.  They do this by
# writing a bunch of files into /var/rtl8192c/*, one setting per file.  The file
# name is the name of the setting, the content of the file is the setting value.
# However, the file name is generally NOT the real name of the actual "mib" that
# would be the argument to iwpriv!
#
# Once these files have been established, there are some scripts that can be
# called, that read these files and actually program the driver via calls
# to iwpriv.  The init.sh and bridge.sh scripts duplicate what OpenWrt already
# does, so we are not interested in them.  The one we care about is wlan_8192c.sh.
#
# So, the plan here is the following.  scan_rtl8192ce(), disable_rtl8192ce() and
# detect_rtl8192ce() are pretty standard and do the ifconfig and bridging stuff.
# The interesting function is enable_rtl8192ce().  This function will
#
# 1.  Call the rtl8192 scripts that create the driver defaults in /var
# 2.  Parse /etc/config/wirless and augment the variables in /var
# 3.  Call the wlan_8192c.sh and let it program the driver based on the
#     files in /var/
#
# For encryption, RealTek provides some additional scripts (wpa-aes.sh for
# example).  These scripts augment /var, then call RealTek's init.sh script.
# We don't want to call init.sh (it does too much).  I'm going to replicate
# the encryption scripts as functions in this script, and call those functions
# based on values in /etc/config/wireless.
#
# That's the basic flow, but the challenge now is; what should /etc/config/wireless
# look like?  The real RealTek variables are too many and too low level to
# present to users in /etc/config/wireless.  Most RealTek variables have numberic
# codes, which mean something only to wlan_8192c.sh and/or the driver.  The
# document Realtek_RTL8192C_Driver_Guide_V10.pdf contains the map from numberic
# codes to actual functions.
#
#####################################################################################

scan_rtl8192ce() {
    local device="$1"

    config_get vifs "$device" vifs
    for vif in $vifs; do
        config_get ifname "$vif" ifname
        config_set "$vif" ifname "${ifname:-$device}"
    done
}

# Disable the device and remove from
# the bridge.
disable_rtl8192ce() {
    local device="$1"
    killall webs 2>/dev/null
    $RTSCRIPTS/wlanapp_8192c.sh kill $device br-lan
    include /lib/network
    ifconfig "$device" down 2>/dev/null >/dev/null && {
        unbridge "$device"
    }
    for i in 0 1 2 3 4 5 6 7; do
        local wds="$device-wds$i"
        ifconfig "$wds" down 2>/dev/null >/dev/null && {
            unbridge "$wds"
        }
    done
    true
}

set_wlan_ipaddr() {

    local ipaddr
    local netmask
    
    include /lib/network
    scan_interfaces
    config_get ipaddr lan ipaddr
    config_get netmask lan netmask
    
    echo $ipaddr > /var/rtl8192c/ip_addr
    echo $netmask > /var/rtl8192c/net_mask
    echo "ipaddr=$ipaddr"
    echo "netmask=$netmask"
}

# Enable the device (ifconfig $dev up), then
# configure the device, then set up the
# network (including adding the device to the bridge).
enable_rtl8192ce() {
    local device="$1"

    config_get vifs "$device" vifs

    for vif in $vifs; do
	config_get ifname "$vif" ifname

	ifname=${ifname/_/-}

	# Write the default config variables using the RealTek scripts
	#
	$RTSCRIPTS/default_setting.sh $ifname	
	echo "0" > /var/rtl8192c/band2g5g_select

	# set nic0_addr and net_mask
	set_wlan_ipaddr
	
	# Get the main user configuration from /etc/config/wireless
	# and translate that into RealTek parameters
	#
	config_get txpower "$device" txpower "100"
	config_get channel "$device" channel "9"
	config_get ch_hi "$device" ch_hi "11"
	config_get ch_lo "$device" ch_lo "0"
	config_get macaddr "$device" macaddr "00:00:00:00:00:00"
	config_get repeater "$device" repeater "0"
	config_get hwmode "$vif" hwmode "11bg"
	config_get ssid "$vif" ssid "RTL8192C"
	config_get hidden "$vif" hidden "0"
	config_get wps_pin "$vif" wps_pin "00000000"

	echo "$repeater" > /var/rtl8192c/repeater_enabled

	local band=3
	case "$hwmode" in
	  "11n") band=8 ;;
	  "11bg") band=3 ;;
	  "11bgn") band=11 ;;
	esac
	echo "$band" > /var/rtl8192c/$ifname/band
	#
	# What to do about txpower?  Seems to be a common thing
	# users want to change, but there is not one number for
	# RealTek, where are a bunch of numbers.  Need to
	# create some formula for this?  Now, its ignored.
	#
	if [ "$channel" = "auto" ]; then channel="0"; fi
	echo "$channel" > /var/rtl8192c/$ifname/channel
	echo "$ch_hi" > /var/rtl8192c/$ifname/ch_hi
	echo "$ch_lo" > /var/rtl8192c/$ifname/ch_lo
	echo "$ssid" > /var/rtl8192c/$ifname/ssid
	echo "$hidden" > /var/rtl8192c/$ifname/hidden_ssid
	echo "$wps_pin" > /var/rtl8192c/$ifname/wsc_pin

	# This assigns the macaddr to the wlan interface.  If 
	# macaddr = 00:00:00:00:00:00, then we won't set it, and
	# the wifi module's manufacturers macaddr should be used.
	#
	if [ ! $macaddr = "00:00:00:00:00:00" ]; then
	    echo ${macaddr//:/} > /var/rtl8192c/$ifname/${ifname}_addr
	    ifconfig $ifname hw ether $macaddr
	fi

	# set the WPS pin
	rtl_generate_wps_pin "$ifname"

	# NOT EXACTLY sure when to call this.  Seems after mib setup but before just
	# about anything else...
	#
	$RTSCRIPTS/webs -x

	# mode: ap, client, wds, ap_wds
	#
	# Based on discussions with Ansel, here are the legal
	# combinations:
	#
	# bgn or n only: (don't let user pick tkip or rate auto drops to bg)
	#   open
	#   wpa     aes
	#   wpa2    aes
	#   wpawpa2 aes
	#
	# bg:
	#   open
        #   wep     64-bit, 182-bit (wep_key_mode=ascii, hex)
	#   wpa     aes, tkip, auto (auto means aes+tkip)
	#   wpa2    aes, tkip, auto (auto means aes+tkip)
	#   wpawpa2 aes, tkip, auto (auto means aes+tkip)
        #
	# These are handled by the RealTek config functions...
	#
	config_get mode "$vif" mode
	config_get auth "$vif" auth
	config_get encryption "$vif" encryption
	config_get wpapsk "$vif" wpapsk

	if [ "$auth" = "open" ]; then
	    echo "0" > /var/rtl8192c/$ifname/auth_type
	    echo "0" > /var/rtl8192c/$ifname/encrypt
	else
	    if [ $hwmode = "11bg" ]; then
		case "$auth" in
		    "wep")   
			echo "1" > /var/rtl8192c/$ifname/encrypt ;
			# 2=auto (open+shared)
			echo "2" > /var/rtl8192c/$ifname/auth_type ;;
		    "wpa")     echo "2" > /var/rtl8192c/$ifname/encrypt ;;
		    "wpa2")    echo "4" > /var/rtl8192c/$ifname/encrypt ;;
		    "wpawpa2") echo "6" > /var/rtl8192c/$ifname/encrypt ;;
		esac
		if [ ${auth:0:3} = "wep" ]; then
		    # default key number
		    config_get wep_key "$vif" wep_key "1"
		    wep_key=$(( wep_key - 1 ))
		    echo "$wep_key" > /var/rtl8192c/$ifname/wep_default_key
		    
		    # 64/128
		    config_get wep_key_mode "$vif" wep_key_mode "ascii"
		    if [ $encryption = "64-bit" ]; then
			echo "1" > /var/rtl8192c/$ifname/wep
			config_get key1 "$vif" wep_key1 "0000000000"
			config_get key2 "$vif" wep_key2 "0000000000"
			config_get key3 "$vif" wep_key3 "0000000000"
			config_get key4 "$vif" wep_key4 "0000000000"
			if [ $wep_key_mode = "ascii" ]; then
			    echo "$key1" > /var/rtl8192c/$ifname/wepkey1_64_asc
			    echo "$key2" > /var/rtl8192c/$ifname/wepkey2_64_asc
			    echo "$key3" > /var/rtl8192c/$ifname/wepkey3_64_asc
			    echo "$key4" > /var/rtl8192c/$ifname/wepkey4_64_asc
			else
			    echo "$key1" > /var/rtl8192c/$ifname/wepkey1_64_hex
			    echo "$key2" > /var/rtl8192c/$ifname/wepkey2_64_hex
			    echo "$key3" > /var/rtl8192c/$ifname/wepkey3_64_hex
			    echo "$key4" > /var/rtl8192c/$ifname/wepkey4_64_hex
			fi
		    else
			echo "2" > /var/rtl8192c/$ifname/wep
			config_get key1 "$vif" wep_key1 "00000000000000000000000000"
			config_get key2 "$vif" wep_key2 "00000000000000000000000000"
			config_get key3 "$vif" wep_key3 "00000000000000000000000000"
			config_get key4 "$vif" wep_key4 "00000000000000000000000000"
			if [ $wep_key_mode = "ascii" ]; then
			    echo "$key1" > /var/rtl8192c/$ifname/wepkey1_128_asc
			    echo "$key2" > /var/rtl8192c/$ifname/wepkey2_128_asc
			    echo "$key3" > /var/rtl8192c/$ifname/wepkey3_128_asc
			    echo "$key4" > /var/rtl8192c/$ifname/wepkey4_128_asc
			else
			    echo "$key1" > /var/rtl8192c/$ifname/wepkey1_128_hex
			    echo "$key2" > /var/rtl8192c/$ifname/wepkey2_128_hex
			    echo "$key3" > /var/rtl8192c/$ifname/wepkey3_128_hex
			    echo "$key4" > /var/rtl8192c/$ifname/wepkey4_128_hex
			fi
		    fi
		elif [ ${auth:0:3} = "wpa" ]; then
		    case "$encryption" in
			"aes") 
			    echo "2" > /var/rtl8192c/$ifname/wpa_cipher ;
			    echo "2" > /var/rtl8192c/$ifname/wpa2_cipher ;;
			"tkip")
			    echo "1" > /var/rtl8192c/$ifname/wpa_cipher ;
			    echo "1" > /var/rtl8192c/$ifname/wpa2_cipher ;;
			"auto")
			    echo "3" > /var/rtl8192c/$ifname/wpa_cipher ;
			    echo "3" > /var/rtl8192c/$ifname/wpa2_cipher ;;
		    esac
		    # no enterprise
		    echo "0" > /var/rtl8192c/$ifname/enable_1x
		    # use psk
		    echo "2" > /var/rtl8192c/$ifname/wpa_auth
		    # password
		    echo "$wpapsk" > /var/rtl8192c/$ifname/wpa_psk
		fi
	    else
		# 11bgn or 11n
		case "$auth" in
		    "wpa")     echo "2" > /var/rtl8192c/$ifname/encrypt ;;
		    "wpa2")    echo "4" > /var/rtl8192c/$ifname/encrypt ;;
		    "wpawpa2") echo "6" > /var/rtl8192c/$ifname/encrypt ;;
		esac
		# no enterprise
		echo "0" > /var/rtl8192c/$ifname/enable_1x
		# use psk
		echo "2" > /var/rtl8192c/$ifname/wpa_auth
		# use AES only (set both just to simplify programming)
                 case "$encryption" in
                     "aes")
                         echo "2" > /var/rtl8192c/$ifname/wpa_cipher
                         echo "2" > /var/rtl8192c/$ifname/wpa2_cipher ;;
                     "auto")
                         echo "3" > /var/rtl8192c/$ifname/wpa_cipher
                         echo "3" > /var/rtl8192c/$ifname/wpa2_cipher ;;
                 esac
		# password
		echo "$wpapsk" > /var/rtl8192c/$ifname/wpa_psk
	    fi
	fi

	# do wps
	#
	config_get wps_enable "$vif" wps_enable "0"
	if [ $wps_enable = "0" ]; then
	    disable_wps $ifname
	else
            # According to RealTek, only open and wpa/wpa2/wpawpa2 with aes is supported.
	    #
	    case "$auth" in
		"open"|"wpa"|"wpa2"|"wpawpa2") 
		    if [ $auth = "open" ] || [ $encryption = "aes" ]; then
			enable_wps $ifname $auth $wpapsk
		    else
			disable_wps $ifname
		    fi ;;
		*)
		    disable_wps $ifname ;;
	    esac
	fi

        # do wds.  code from test_wds.sh
	#
	config_get wds_enable "$vif" wds_enable "0"
	$CE_IWPRIV "$ifname" set_mib wds_enable=$wds_enable

	if [ "$wds_enable" = "1" ]; then
	    #
	    # A number of params are associated with the wlan0 device
	    #
	    config_get wds_pure "$ifname" wds_pure "0"
	    config_get wds_priority "$ifname" wds_priority "1"
            # wds_encrypt: 0:open 1:wep64 2:tkip 4:aes 5:wep128
	    config_get wds_encrypt_str "$ifname" wds_encrypt "open"  
	    case "$wds_encrypt_str" in
		"open")   wds_encrypt="0" ;;
		"wep64")  wds_encrypt="1" ;;
		"tkip")   wds_encrypt="2" ;;
		"aes")    wds_encrypt="4" ;;
		"wep128") wds_encrypt="5" ;;
	    esac
	    config_get wds_wepkey "$ifname" wds_wepkey "1234567890"
	    config_get wds_passphrase "$ifname" wds_passphrase "1234567890"

	    $CE_IWPRIV "$ifname" set_mib wds_pure=$wds_pure
	    $CE_IWPRIV "$ifname" set_mib wds_priority=$wds_priority
	    $CE_IWPRIV "$ifname" set_mib wds_num="0"
	    $CE_IWPRIV "$ifname" set_mib wds_encrypt=$wds_encrypt
	    $CE_IWPRIV "$ifname" set_mib wds_wepkey=$wds_wepkey
	    $CE_IWPRIV "$ifname" set_mib wds_passphrase=$wds_passphrase
 
	    # And a couple of params are associated with each repeater
	    #
            # The guk below is an inline config_foreach func wifi-wds
	    local type='wifi-wds'
	    local section cfgtype
	    local idx=0
	    [ -z "$CONFIG_SECTIONS" ] && return 0
	    for section in ${CONFIG_SECTIONS}; do
		config_get cfgtype "$section" TYPE
		[ -n "$type" -a "x$cfgtype" != "x$type" ] && continue

		# MIBS
		config_get wds_device "$section" device
		config_get wds_macaddr "$section" macaddr "00:00:00:00:00:00"
		config_get wds_rate "$section" rate "0"
		config_get wds_msc "$section" msc "0"
		config_get wds_disable_ipv6 "$section" disable_ipv6 "1"
		wds_macaddr=${wds_macaddr//:/}
		echo "$wds_disable_ipv6" > /proc/sys/net/ipv6/conf/$wds_device/disable_ipv6

		local i_rate=1
		local rate
		case "$wds_rate" in
		    "0") i_rate=0 ;;
		    "1") i_rate=1 ;;
		    "2") i_rate=2 ;;
		    "5.5") i_rate=4 ;;
		    "11") i_rate=8 ;;
		    "6") i_rate=16 ;;
		    "9") i_rate=32 ;;
		    "12") i_rate=64 ;;
		    "18") i_rate=128 ;;
		    "24") i_rate=256 ;;
		    "36") i_rate=512 ;;
		    "48") i_rate=1024 ;;
		    "54") i_rate=2048 ;;
		esac

		# msc is bits 12-27
		# rate is bits 0-11
		# these are combined into a 32-bit number
		rate=$(( 4096*$wds_msc ))
		rate=$(( $rate+$i_rate ))
		$CE_IWPRIV "$ifname" set_mib wds_num=$idx
		$CE_IWPRIV "$ifname" set_mib wds_add=$wds_macaddr,$rate
		idx=$(( idx + 1 ))
	    done
	fi

	# Ok we are done with the basic stuff.  But there are a large number of
	# parameters we have not touched.  Hopefully, they don't need to be touched by
	# normal users.  But, we provide a mechanism here for system programmers to
	# set any parameter defined in /var/rtl8192c/$ifname.  The way we do this is
	# to look for /etc/config/rtl8192ce.  If it exists, we'll do an uci_load on it.
	# We've defined an "option callback" which will be invoked foreach option defined
	# in that file.  The option must be a file name present in /var/rtl8192c/$ifname,
	# and if that is true, the value is written into that file.  This is all accomplished
	# with another script, called $RTSCRIPTS/set-advanced-options.sh.
	#
	if [ -f "/etc/config/rtl8192c" ]; then
	    $RTSCRIPTS/set-advanced-options.sh $ifname
	fi

	# LED blinks
	echo "11" > /var/rtl8192c/$ifname/led_type

	# All of our configuration setup is complete.  Now
	# call the RealTek master control script which will
	# do the programming
	#
	$RTSCRIPTS/wlan_8192c.sh $ifname
    done
    
    # bring it up
    ifconfig "$device" up

    for vif in $vifs; do
	config_get ifname "$vif" ifname
	ifname=${ifname/_/-}

        # add it to the bridge to activate it
	local net_cfg bridge
	net_cfg="$(find_net_config "$vif")"
	[ -z "$net_cfg" ] || {
            bridge="$(bridge_interface "$net_cfg")"
            config_set "$vif" bridge "$bridge"
            start_net "$ifname" "$net_cfg"

	    # do wds.  code from test_wds.sh
	    #
	    config_get wds_enable "$vif" wds_enable
	    if [ "$wds_enable" = "1" ]; then
                # The guk below is an inline config_foreach func wifi-wds
		local type='wifi-wds'
		local section cfgtype
		[ -z "$CONFIG_SECTIONS" ] && return 0
		for section in ${CONFIG_SECTIONS}; do
		    config_get cfgtype "$section" TYPE
		    [ -n "$type" -a "x$cfgtype" != "x$type" ] && continue
		    config_get wds_device "$section" device
		    ifconfig "$wds_device" up 2>/dev/null >/dev/null && {
			brctl addif br-lan $wds_device
		    }
		done
	    fi
	}
	set_wifi_up "$vif" "$ifname"
	#
	# Run the rtl8192ce daemons
	#
	if [ "$repeater" = "1" ]; then
		$RTSCRIPTS/wlanapp_8192c.sh start "$ifname" "$ifname-vxd" br-lan
	else
		$RTSCRIPTS/wlanapp_8192c.sh start "$ifname" br-lan
	fi
    done
}

# The /etc/config/network lan interface 
# must contain:
#  option type bridge
#
detect_rtl8192ce() {
    local wifiaddr="00:00:00:00:00:00"
    if [ -x /usr/sbin/fw_printenv ]; then
	local waddr=`fw_printenv wifiaddr0|awk -F= '{print $2}'`
	if [ ! -z "$waddr" ]; then
	    wifiaddr=$waddr
	fi
    fi
    cd /sys/class/net
    for dev in $(ls -d wlan[0-9] 2>&-); do
	dev=${dev/-/_}
	cat <<EOF
#
# channel can be a number, or auto
# hwmode: one of 11b, 11bg, 11bgn
# mode: ap, client, wds or ap_wds
# auth: wep64, wep128, encryption: asc, hex, open
# auth: wpa, encryption: aes, open
# auth: wpa2, encryption: aes, open
# auth: wpawpa2, encription: aes, auto, tkip, open
#
config wifi-device $dev
  option type     rtl8192ce
  option channel  9
  option txpower  100
  option beacon_int 100
  option repeater 0
  option macaddr  $wifiaddr
  # COMMENT THIS LINE TO ENABLE WIFI:
  option disabled 1

config wifi-iface
  option device   $dev
  option network  lan
  option mode     ap
  option hwmode	  11bg
  option ssid     G2-rtl8192ce
  option hidden   0
  option wds_enable 0
  option wps_enable 0
  option wps_pin  00000000
  option auth     wpawpa2
  option encryption aes
  option wpapsk   5107701110
#
# These are required if wds_enable=1 and go into wifi-iface section
#
# wds_pure=0
# wds_priority=1
# wds_encrypt=open (open, aes)
# wds_passphrase=1234567890
#
config wifi-wds
  option device   $dev-wds0

EOF
    done
}

rtl_generate_wps_pin() {
    local ifname="$1"
    local pin=`cat /var/rtl8192c/$ifname/wsc_pin`
    if [ "$pin" = "00000000" ]; then
	$RTSCRIPTS/flash gen-pin $ifname
	$RTSCRIPTS/flash gen-pin $ifname-vxd
    fi
}

# auth flags:
#  open    1
#  wpapsk  2
#  shared  4
#  wpa     8
#  wpa2    0x10
#  wpa2psk 0x20
#
# enc flags:
#  none    1
#  wep     2
#  tkip    4
#  aes     8
#
# According to RealTek, only open and wpa/wpa2/wpawpa2 with aes is
# supported.
#
enable_wps() {
    local ifname="$1"
    local auth="$2"
    local wpapsk="$wpapsk"
    
    echo "0" > /var/rtl8192c/$ifname/wsc_disabled
    echo "1" > /var/rtl8192c/$ifname/wsc_configured
    case "$auth" in
	"open")    echo "1"  > /var/rtl8192c/$ifname/wsc_auth ;;
	"wpa")     echo "2"  > /var/rtl8192c/$ifname/wsc_auth ;;
	"wpa2")    echo "32" > /var/rtl8192c/$ifname/wsc_auth ;;
	"wpawpa2") echo "34" > /var/rtl8192c/$ifname/wsc_auth ;;
    esac
    if [ $auth = "open" ]; then
	echo "1" > /var/rtl8192c/$ifname/wsc_enc
    else
	echo "8" > /var/rtl8192c/$ifname/wsc_enc
    fi
    echo "0" > /var/rtl8192c/$ifname/wsc_configbyextreg
    echo $wpapsk > /var/rtl8192c/$ifname/wsc_psk
    
}

disable_wps() {
    local ifname="$1"
    echo "1" > /var/rtl8192c/$ifname/wsc_disabled
}
