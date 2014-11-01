#!/bin/sh
#
# This is a simple script that will write advanced parameters for the
# RealTek rtl8192c driver from /etc/config/rtl8192c
#
. $IPKG_INSTROOT/etc/functions.sh

ifname=$1

if [ -z "$ifname" ]; then
    print "Usage: set-advanced-options.sh <ifname>"
    exit 1
fi

if [ ! -f "/etc/config/rtl8192c" ]; then
    exit 0
fi

# This is a callback function, called once for every option/value pair in
# the uci config file.  
#
option_cb() {
  local opt="$1"
  local val="$2"
  
  if [ -f "/var/rtl8192c/$ifname/$opt" ]; then
      echo "$val" > /var/rtl8192c/$ifname/$opt
  fi
}

# Trigger the callback process
#
config_load rtl8192c

exit 0
