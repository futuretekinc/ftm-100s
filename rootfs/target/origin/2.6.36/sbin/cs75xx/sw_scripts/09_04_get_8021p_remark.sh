#!/bin/sh
sw_cfg -c RTK_QOS_DOT1P_REMARK_GET -s
sw_cfg -c RTK_QOS_DOT1P_REMARK_GET -f int_pri -v 7
sw_cfg -c RTK_QOS_DOT1P_REMARK_GET -e

