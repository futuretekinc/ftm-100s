#!/bin/sh
sw_cfg -c RTK_VLAN_PORT_AFT_SET -s
sw_cfg -c RTK_VLAN_PORT_AFT_SET -f port -v 1
sw_cfg -c RTK_VLAN_PORT_AFT_SET -f accept_frame_type -v 2
sw_cfg -c RTK_VLAN_PORT_AFT_SET -e

