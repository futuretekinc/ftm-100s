#!/bin/sh
sw_cfg -c RTK_STAT_PORT_RESET -s
sw_cfg -c RTK_STAT_PORT_RESET -f port -v 3
sw_cfg -c RTK_STAT_PORT_RESET -e

