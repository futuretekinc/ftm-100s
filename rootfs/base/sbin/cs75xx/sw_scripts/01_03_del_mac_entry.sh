#!/bin/sh
sw_cfg -c RTK_L2_ADDR_DEL -s
sw_cfg -c RTK_L2_ADDR_DEL -f mac -v 00:02:03:04:05:06
sw_cfg -c RTK_L2_ADDR_DEL -f l2_data.ivl -v 0
sw_cfg -c RTK_L2_ADDR_DEL -f l2_data.cvid -v 0
sw_cfg -c RTK_L2_ADDR_DEL -f l2_data.fid -v 0
sw_cfg -c RTK_L2_ADDR_DEL -f l2_data.efid -v 0
sw_cfg -c RTK_L2_ADDR_DEL -e

