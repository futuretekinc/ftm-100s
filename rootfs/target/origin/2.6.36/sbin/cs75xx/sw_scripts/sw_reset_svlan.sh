#!/bin/sh
# reset SVLAN and remove existed SVLAN setting
# USAGE: sw_reset_svlan.sh

# re-init SVLAN
sw_cfg -c RTK_SVLAN_INIT -s
sw_cfg -c RTK_SVLAN_INIT -e

# remove default SVID from port 0
sw_cfg -c RTK_SVLAN_DEF_SVID_SET -s
sw_cfg -c RTK_SVLAN_DEF_SVID_SET -f port -v 0
sw_cfg -c RTK_SVLAN_DEF_SVID_SET -f svid -v 0
sw_cfg -c RTK_SVLAN_DEF_SVID_SET -e

# remove default SVID from port 1
sw_cfg -c RTK_SVLAN_DEF_SVID_SET -s
sw_cfg -c RTK_SVLAN_DEF_SVID_SET -f port -v 1
sw_cfg -c RTK_SVLAN_DEF_SVID_SET -f svid -v 0
sw_cfg -c RTK_SVLAN_DEF_SVID_SET -e

# remove default SVID from port 2
sw_cfg -c RTK_SVLAN_DEF_SVID_SET -s
sw_cfg -c RTK_SVLAN_DEF_SVID_SET -f port -v 2
sw_cfg -c RTK_SVLAN_DEF_SVID_SET -f svid -v 0
sw_cfg -c RTK_SVLAN_DEF_SVID_SET -e

# remove default SVID from port 3
sw_cfg -c RTK_SVLAN_DEF_SVID_SET -s
sw_cfg -c RTK_SVLAN_DEF_SVID_SET -f port -v 3
sw_cfg -c RTK_SVLAN_DEF_SVID_SET -f svid -v 0
sw_cfg -c RTK_SVLAN_DEF_SVID_SET -e


