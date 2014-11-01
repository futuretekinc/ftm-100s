#!/bin/sh
# set CPU tag
# USAGE: sw_get_svlan.sh

# svlan_portmask     --   0-0x3F (bit-wise port map)
sw_cfg -c RTK_SVLAN_SVC_PORT_GET -s
sw_cfg -c RTK_SVLAN_SVC_PORT_GET -e

# port     --   0-3: LAN, 5: CPU port
# svid     --   1-4094

# All packets from port 0 will be add below SVID
sw_cfg -c RTK_SVLAN_DEF_SVID_GET -s
sw_cfg -c RTK_SVLAN_DEF_SVID_GET -f port -v 0
sw_cfg -c RTK_SVLAN_DEF_SVID_GET -e

# All packets from port 1 will be add below SVID
sw_cfg -c RTK_SVLAN_DEF_SVID_GET -s
sw_cfg -c RTK_SVLAN_DEF_SVID_GET -f port -v 1
sw_cfg -c RTK_SVLAN_DEF_SVID_GET -e

# All packets from port 2 will be add below SVID
sw_cfg -c RTK_SVLAN_DEF_SVID_GET -s
sw_cfg -c RTK_SVLAN_DEF_SVID_GET -f port -v 2
sw_cfg -c RTK_SVLAN_DEF_SVID_GET -e

# All packets from port 3 will be add below SVID
sw_cfg -c RTK_SVLAN_DEF_SVID_GET -s
sw_cfg -c RTK_SVLAN_DEF_SVID_GET -f port -v 3
sw_cfg -c RTK_SVLAN_DEF_SVID_GET -e

# action   --   0: drop, 1: trap, 2:assign new SVID
# svid     --   1-4094
sw_cfg -c RTK_SVLAN_UNMATCH_ACTION_GET -s
sw_cfg -c RTK_SVLAN_UNMATCH_ACTION_GET -e

