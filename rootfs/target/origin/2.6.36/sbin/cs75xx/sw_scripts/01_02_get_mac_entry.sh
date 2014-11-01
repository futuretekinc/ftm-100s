#!/bin/sh
sw_cfg -c RTK_L2_ADDR_GET -s
sw_cfg -c RTK_L2_ADDR_GET -f mac -v 00:02:03:04:05:06
sw_cfg -c RTK_L2_ADDR_GET -e

