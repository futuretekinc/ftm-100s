#!/bin/sh
sw_cfg -c RTK_QOS_DSCP_PRI_REMAP_GET -s
sw_cfg -c RTK_QOS_DSCP_PRI_REMAP_GET -f dscp -v 3
sw_cfg -c RTK_QOS_DSCP_PRI_REMAP_GET -e

