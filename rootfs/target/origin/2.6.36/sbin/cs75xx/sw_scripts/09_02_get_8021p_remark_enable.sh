#!/bin/sh
sw_cfg -c RTK_QOS_DOT1P_REMARK_EN_GET -s
sw_cfg -c RTK_QOS_DOT1P_REMARK_EN_GET -f port -v 1
sw_cfg -c RTK_QOS_DOT1P_REMARK_EN_GET -e

