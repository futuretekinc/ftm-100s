#!/bin/sh
sw_cfg -c RTK_VLAN_BASED_PRI_GET -s
sw_cfg -c RTK_VLAN_BASED_PRI_GET -f vid -v 100
sw_cfg -c RTK_VLAN_BASED_PRI_GET -e

