#!/bin/sh
sw_cfg -c RTK_VLAN_TAGMODE_GET -s
sw_cfg -c RTK_VLAN_TAGMODE_GET -f port -v 3
sw_cfg -c RTK_VLAN_TAGMODE_GET -e

