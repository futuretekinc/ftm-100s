#!/bin/sh
sw_cfg -c RTK_QOS_PORT_PRI_SET -s
sw_cfg -c RTK_QOS_PORT_PRI_SET -f port -v 2
sw_cfg -c RTK_QOS_PORT_PRI_SET -f int_pri -v 2
sw_cfg -c RTK_QOS_PORT_PRI_SET -e

