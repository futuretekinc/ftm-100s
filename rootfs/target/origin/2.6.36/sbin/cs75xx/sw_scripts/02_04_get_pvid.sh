#!/bin/sh
sw_cfg -c RTK_VLAN_PVID_GET -s
sw_cfg -c RTK_VLAN_PVID_GET -f port -v 0
sw_cfg -c RTK_VLAN_PVID_GET -e

