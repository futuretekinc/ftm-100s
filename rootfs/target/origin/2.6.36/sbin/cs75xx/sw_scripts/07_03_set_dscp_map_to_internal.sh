#!/bin/sh
sw_cfg -c RTK_QOS_DSCP_PRI_REMAP_SET -s
sw_cfg -c RTK_QOS_DSCP_PRI_REMAP_SET -f dscp -v 3
sw_cfg -c RTK_QOS_DSCP_PRI_REMAP_SET -f int_pri -v 1
sw_cfg -c RTK_QOS_DSCP_PRI_REMAP_SET -e

