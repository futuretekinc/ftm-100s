#!/bin/sh
sw_cfg -c RTK_QOS_SCHE_QUE_GET -s
sw_cfg -c RTK_QOS_SCHE_QUE_GET -f port -v 3
sw_cfg -c RTK_QOS_SCHE_QUE_GET -e

