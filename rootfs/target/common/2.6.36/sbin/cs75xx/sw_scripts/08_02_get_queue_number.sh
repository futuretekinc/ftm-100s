#!/bin/sh
sw_cfg -c RTK_QOS_QUE_NUM_GET -s
sw_cfg -c RTK_QOS_QUE_NUM_GET -f port -v 0
sw_cfg -c RTK_QOS_QUE_NUM_GET -e

