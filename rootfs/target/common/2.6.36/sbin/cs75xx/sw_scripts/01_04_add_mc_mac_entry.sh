#!/bin/sh
sw_cfg -c RTK_L2_MCADDR_ADD -s
sw_cfg -c RTK_L2_MCADDR_ADD -f mac -v 01:00:5E:04:05:06
sw_cfg -c RTK_L2_MCADDR_ADD -f ivl -v 0
sw_cfg -c RTK_L2_MCADDR_ADD -f cvid_fid -v 0
sw_cfg -c RTK_L2_MCADDR_ADD -f portmask -v 0x3F
sw_cfg -c RTK_L2_MCADDR_ADD -e

