#!/bin/sh
sw_cfg -c RTK_VLAN_SET -s
sw_cfg -c RTK_VLAN_SET -f vid -v 100
sw_cfg -c RTK_VLAN_SET -f mbrmsk -v 0x21
sw_cfg -c RTK_VLAN_SET -f untagmsk -v 0x21
sw_cfg -c RTK_VLAN_SET -f fid -v 0
sw_cfg -c RTK_VLAN_SET -e

