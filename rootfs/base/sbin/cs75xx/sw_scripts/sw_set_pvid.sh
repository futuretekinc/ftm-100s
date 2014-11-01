#!/bin/sh
# set PVID of the specified port
# USAGE: sw_set_pvid.sh [port] [PVID]
# port   --   0-3: LAN, 5: CPU port
# PVID   --   1-4094

sw_cfg -c RTK_VLAN_PVID_SET -s
sw_cfg -c RTK_VLAN_PVID_SET -f port -v $1
sw_cfg -c RTK_VLAN_PVID_SET -f pvid -v $2
sw_cfg -c RTK_VLAN_PVID_SET -e

