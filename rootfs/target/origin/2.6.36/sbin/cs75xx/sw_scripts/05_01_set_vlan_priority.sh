#!/bin/sh
sw_cfg -c RTK_VLAN_BASED_PRI_SET -s
sw_cfg -c RTK_VLAN_BASED_PRI_SET -f vid -v 100
sw_cfg -c RTK_VLAN_BASED_PRI_SET -f priority -v 3
sw_cfg -c RTK_VLAN_BASED_PRI_SET -e

