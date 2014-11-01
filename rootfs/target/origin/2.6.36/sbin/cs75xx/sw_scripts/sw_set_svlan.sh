#!/bin/sh
# set and enable SVLAN
# USAGE: sw_set_svlan.sh [port] [port0 SVID] [port1 SVID] [port2 SVID] [port3 SVID]
# port     --   0-3: LAN, 5: CPU port
# SVID     --   1-4094

# port     --   0-3: LAN, 5: CPU port
sw_cfg -c RTK_SVLAN_SVC_PORT_ADD -s
sw_cfg -c RTK_SVLAN_SVC_PORT_ADD -f port -v $1
sw_cfg -c RTK_SVLAN_SVC_PORT_ADD -e

# svid_idx     		--   1-4094
# svlan_cfg.svid     	--   1-4094 (same as svid_idx)
# svlan_cfg.memberport  -- 0-0x3F (bit-wise port map)
# svlan_cfg.untagport  	-- 0-0x3F (bit-wise port map)
# svlan_cfg.fid  	-- 0-0xF (filtering database)
# svlan_cfg.priority  	-- 0-7

# SVLAN for ingress port 0
sw_cfg -c RTK_SVLAN_MBRPORT_ENTRY_SET -s
sw_cfg -c RTK_SVLAN_MBRPORT_ENTRY_SET -f svid_idx -v $2
sw_cfg -c RTK_SVLAN_MBRPORT_ENTRY_SET -f svlan_cfg.svid -v $2
sw_cfg -c RTK_SVLAN_MBRPORT_ENTRY_SET -f svlan_cfg.memberport -v 0x3F
sw_cfg -c RTK_SVLAN_MBRPORT_ENTRY_SET -f svlan_cfg.untagport -v 0xF
sw_cfg -c RTK_SVLAN_MBRPORT_ENTRY_SET -e

# SVLAN for ingress port 1
sw_cfg -c RTK_SVLAN_MBRPORT_ENTRY_SET -s
sw_cfg -c RTK_SVLAN_MBRPORT_ENTRY_SET -f svid_idx -v $3
sw_cfg -c RTK_SVLAN_MBRPORT_ENTRY_SET -f svlan_cfg.svid -v $3
sw_cfg -c RTK_SVLAN_MBRPORT_ENTRY_SET -f svlan_cfg.memberport -v 0x3F
sw_cfg -c RTK_SVLAN_MBRPORT_ENTRY_SET -f svlan_cfg.untagport -v 0xF
sw_cfg -c RTK_SVLAN_MBRPORT_ENTRY_SET -e

# SVLAN for ingress port 2
sw_cfg -c RTK_SVLAN_MBRPORT_ENTRY_SET -s
sw_cfg -c RTK_SVLAN_MBRPORT_ENTRY_SET -f svid_idx -v $4
sw_cfg -c RTK_SVLAN_MBRPORT_ENTRY_SET -f svlan_cfg.svid -v $4
sw_cfg -c RTK_SVLAN_MBRPORT_ENTRY_SET -f svlan_cfg.memberport -v 0x3F
sw_cfg -c RTK_SVLAN_MBRPORT_ENTRY_SET -f svlan_cfg.untagport -v 0xF
sw_cfg -c RTK_SVLAN_MBRPORT_ENTRY_SET -e

# SVLAN for ingress port 3
sw_cfg -c RTK_SVLAN_MBRPORT_ENTRY_SET -s
sw_cfg -c RTK_SVLAN_MBRPORT_ENTRY_SET -f svid_idx -v $5
sw_cfg -c RTK_SVLAN_MBRPORT_ENTRY_SET -f svlan_cfg.svid -v $5
sw_cfg -c RTK_SVLAN_MBRPORT_ENTRY_SET -f svlan_cfg.memberport -v 0x3F
sw_cfg -c RTK_SVLAN_MBRPORT_ENTRY_SET -f svlan_cfg.untagport -v 0xF
sw_cfg -c RTK_SVLAN_MBRPORT_ENTRY_SET -e

# port     --   0-3: LAN, 5: CPU port
# svid     --   1-4094

# All packets from port 0 will be add below SVID
sw_cfg -c RTK_SVLAN_DEF_SVID_SET -s
sw_cfg -c RTK_SVLAN_DEF_SVID_SET -f port -v 0
sw_cfg -c RTK_SVLAN_DEF_SVID_SET -f svid -v $2
sw_cfg -c RTK_SVLAN_DEF_SVID_SET -e

# All packets from port 1 will be add below SVID
sw_cfg -c RTK_SVLAN_DEF_SVID_SET -s
sw_cfg -c RTK_SVLAN_DEF_SVID_SET -f port -v 1
sw_cfg -c RTK_SVLAN_DEF_SVID_SET -f svid -v $3
sw_cfg -c RTK_SVLAN_DEF_SVID_SET -e

# All packets from port 2 will be add below SVID
sw_cfg -c RTK_SVLAN_DEF_SVID_SET -s
sw_cfg -c RTK_SVLAN_DEF_SVID_SET -f port -v 2
sw_cfg -c RTK_SVLAN_DEF_SVID_SET -f svid -v $4
sw_cfg -c RTK_SVLAN_DEF_SVID_SET -e

# All packets from port 3 will be add below SVID
sw_cfg -c RTK_SVLAN_DEF_SVID_SET -s
sw_cfg -c RTK_SVLAN_DEF_SVID_SET -f port -v 3
sw_cfg -c RTK_SVLAN_DEF_SVID_SET -f svid -v $5
sw_cfg -c RTK_SVLAN_DEF_SVID_SET -e

# action   --   0: drop, 1: trap, 2:assign new SVID
# svid     --   1-4094
sw_cfg -c RTK_SVLAN_UNMATCH_ACTION_SET -s
sw_cfg -c RTK_SVLAN_UNMATCH_ACTION_SET -f action -v 0
sw_cfg -c RTK_SVLAN_UNMATCH_ACTION_SET -f svid -v 0
sw_cfg -c RTK_SVLAN_UNMATCH_ACTION_SET -e

