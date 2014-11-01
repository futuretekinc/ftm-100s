#!/bin/sh
sw_cfg -c RTK_VLAN_PVID_SET -s
sw_cfg -c RTK_VLAN_PVID_SET -f port -v 0
sw_cfg -c RTK_VLAN_PVID_SET -f pvid -v 100
sw_cfg -c RTK_VLAN_PVID_SET -f priority -v 0
sw_cfg -c RTK_VLAN_PVID_SET -e

