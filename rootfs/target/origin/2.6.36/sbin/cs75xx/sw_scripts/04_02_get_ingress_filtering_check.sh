#!/bin/sh
sw_cfg -c RTK_VLAN_PORT_IGRFILTER_EN_GET -s
sw_cfg -c RTK_VLAN_PORT_IGRFILTER_EN_GET -f port -v 2
sw_cfg -c RTK_VLAN_PORT_IGRFILTER_EN_GET -e

