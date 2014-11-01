#!/bin/sh
sw_cfg -c RTK_VLAN_TAGMODE_SET -s
sw_cfg -c RTK_VLAN_TAGMODE_SET -f port -v 3
sw_cfg -c RTK_VLAN_TAGMODE_SET -f tag_mode -v 2
sw_cfg -c RTK_VLAN_TAGMODE_SET -e

