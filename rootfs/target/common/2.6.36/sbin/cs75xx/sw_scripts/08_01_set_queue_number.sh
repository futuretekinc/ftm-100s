#!/bin/sh
sw_cfg -c RTK_QOS_QUE_NUM_SET -s
sw_cfg -c RTK_QOS_QUE_NUM_SET -f port -v 0
sw_cfg -c RTK_QOS_QUE_NUM_SET -f queue_num -v 4
sw_cfg -c RTK_QOS_QUE_NUM_SET -e

