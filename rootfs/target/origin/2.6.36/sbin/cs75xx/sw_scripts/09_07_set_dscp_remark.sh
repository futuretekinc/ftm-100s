#!/bin/sh
sw_cfg -c RTK_QOS_DSCP_REMARK_SET -s
sw_cfg -c RTK_QOS_DSCP_REMARK_SET -f int_pri -v 7
sw_cfg -c RTK_QOS_DSCP_REMARK_SET -f dscp -v 63
sw_cfg -c RTK_QOS_DSCP_REMARK_SET -e

