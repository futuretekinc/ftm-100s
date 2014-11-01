#!/bin/sh
sw_cfg -c RTK_PORT_MACSTATUS_GET -s
sw_cfg -c RTK_PORT_MACSTATUS_GET -f port -v $1
sw_cfg -c RTK_PORT_MACSTATUS_GET -e

