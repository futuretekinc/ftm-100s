#!/bin/sh
sw_cfg -c RTK_QOS_PORT_PRI_GET -s
sw_cfg -c RTK_QOS_PORT_PRI_GET -f port -v 2
sw_cfg -c RTK_QOS_PORT_PRI_GET -e

