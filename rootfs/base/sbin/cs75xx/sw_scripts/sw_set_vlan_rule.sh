#!/bin/sh
# set VLAN rule
# USAGE: sw_set_vlan_rule.sh [VID] [member-mask] [untag-mask]
# VID           --   1-4094
# member-mask   --   bitwise mask. bit0-3: LAN, 5: CPU port
# untag-mask    --   bitwise mask. bit0-3: LAN, 5: CPU port

sw_cfg -c RTK_VLAN_SET -s
sw_cfg -c RTK_VLAN_SET -f vid -v $1
sw_cfg -c RTK_VLAN_SET -f mbrmsk -v $2
sw_cfg -c RTK_VLAN_SET -f untagmsk -v $3
sw_cfg -c RTK_VLAN_SET -e

