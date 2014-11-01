#!/bin/sh
sw_cfg -c RTK_VLAN_PORT_IGRFILTER_EN_SET -s
sw_cfg -c RTK_VLAN_PORT_IGRFILTER_EN_SET -f port -v 2
sw_cfg -c RTK_VLAN_PORT_IGRFILTER_EN_SET -f igr_filter -v 1
sw_cfg -c RTK_VLAN_PORT_IGRFILTER_EN_SET -e

