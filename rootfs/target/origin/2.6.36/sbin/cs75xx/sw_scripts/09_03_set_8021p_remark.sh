#!/bin/sh
sw_cfg -c RTK_QOS_DOT1P_REMARK_SET -s
sw_cfg -c RTK_QOS_DOT1P_REMARK_SET -f int_pri -v 7
sw_cfg -c RTK_QOS_DOT1P_REMARK_SET -f dot1p_pri -v 3
sw_cfg -c RTK_QOS_DOT1P_REMARK_SET -e

