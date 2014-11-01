#!/bin/sh
sw_cfg -c RTK_L2_ADDR_ADD -s
sw_cfg -c RTK_L2_ADDR_ADD -f mac -v 00:02:03:04:05:06
sw_cfg -c RTK_L2_ADDR_ADD -f l2_data.ivl -v 0
sw_cfg -c RTK_L2_ADDR_ADD -f l2_data.cvid -v 0
sw_cfg -c RTK_L2_ADDR_ADD -f l2_data.fid -v 0
sw_cfg -c RTK_L2_ADDR_ADD -f l2_data.efid -v 0
sw_cfg -c RTK_L2_ADDR_ADD -f l2_data.port -v 3
sw_cfg -c RTK_L2_ADDR_ADD -f l2_data.sa_block -v 0
sw_cfg -c RTK_L2_ADDR_ADD -f l2_data.da_block -v 0
sw_cfg -c RTK_L2_ADDR_ADD -f l2_data.auth -v 0
sw_cfg -c RTK_L2_ADDR_ADD -f l2_data.is_static -v 1
sw_cfg -c RTK_L2_ADDR_ADD -e

