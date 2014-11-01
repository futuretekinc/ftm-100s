#!/bin/sh
# get PVID of the specified port
# USAGE: sw_get_pvid.sh [port]
# port   --   0-3: LAN, 5: CPU port

sw_cfg -c RTK_VLAN_PVID_GET -s
sw_cfg -c RTK_VLAN_PVID_GET -f port -v $1
sw_cfg -c RTK_VLAN_PVID_GET -e

