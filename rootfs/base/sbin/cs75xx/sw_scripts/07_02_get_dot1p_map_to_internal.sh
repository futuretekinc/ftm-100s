#!/bin/sh
sw_cfg -c RTK_QOS_DOT1P_PRI_REMAP_GET -s
sw_cfg -c RTK_QOS_DOT1P_PRI_REMAP_GET -f dot1p_pri -v 7
sw_cfg -c RTK_QOS_DOT1P_PRI_REMAP_GET -e

