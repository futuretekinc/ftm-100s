#!/bin/sh
sw_cfg -c RTK_VLAN_GET -s
sw_cfg -c RTK_VLAN_GET -f vid -v 100
sw_cfg -c RTK_VLAN_GET -e

