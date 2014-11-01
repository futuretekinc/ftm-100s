#!/bin/sh
sw_cfg -c RTK_STAT_PORT_GETALL -s
sw_cfg -c RTK_STAT_PORT_GETALL -f port -v 3
sw_cfg -c RTK_STAT_PORT_GETALL -e

