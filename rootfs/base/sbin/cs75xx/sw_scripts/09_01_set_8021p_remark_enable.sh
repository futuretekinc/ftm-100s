#!/bin/sh
sw_cfg -c RTK_QOS_DOT1P_REMARK_EN_SET -s
sw_cfg -c RTK_QOS_DOT1P_REMARK_EN_SET -f port -v 1
sw_cfg -c RTK_QOS_DOT1P_REMARK_EN_SET -f enable -v 1
sw_cfg -c RTK_QOS_DOT1P_REMARK_EN_SET -e

