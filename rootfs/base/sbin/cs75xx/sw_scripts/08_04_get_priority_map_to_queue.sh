#!/bin/sh
sw_cfg -c RTK_QOS_PRI_MAP_GET -s
sw_cfg -c RTK_QOS_PRI_MAP_GET -f queue_num -v 4
sw_cfg -c RTK_QOS_PRI_MAP_GET -e

