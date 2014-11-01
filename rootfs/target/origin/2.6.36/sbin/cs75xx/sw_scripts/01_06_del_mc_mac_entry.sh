#!/bin/sh
sw_cfg -c RTK_L2_MCADDR_DEL -s
sw_cfg -c RTK_L2_MCADDR_DEL -f mac -v 01:00:5E:04:05:06
sw_cfg -c RTK_L2_MCADDR_DEL -f ivl -v 0
sw_cfg -c RTK_L2_MCADDR_DEL -f cvid_fid -v 0
sw_cfg -c RTK_L2_MCADDR_DEL -e

