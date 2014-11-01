#!/bin/sh
sw_cfg -c RTK_VLAN_PORT_AFT_GET -s
sw_cfg -c RTK_VLAN_PORT_AFT_GET -f port -v 1
sw_cfg -c RTK_VLAN_PORT_AFT_GET -e

