#!/bin/sh
# get VLAN rule
# USAGE: sw_get_vlan_rule.sh [VID]
# VID           --   1-4094

sw_cfg -c RTK_VLAN_GET -s
sw_cfg -c RTK_VLAN_GET -f vid -v $1
sw_cfg -c RTK_VLAN_GET -e

