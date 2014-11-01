#!/bin/sh
sw_cfg -c RTK_QOS_DSCP_REMARK_EN_GET -s
sw_cfg -c RTK_QOS_DSCP_REMARK_EN_GET -f port -v 0xFF
sw_cfg -c RTK_QOS_DSCP_REMARK_EN_GET -e

