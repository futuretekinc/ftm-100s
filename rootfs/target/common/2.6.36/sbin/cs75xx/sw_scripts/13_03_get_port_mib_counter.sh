#!/bin/sh
sw_cfg -c RTK_STAT_PORT_GET -s
sw_cfg -c RTK_STAT_PORT_GET -f port -v 3
sw_cfg -c RTK_STAT_PORT_GET -f cntr_idx -v 7
sw_cfg -c RTK_STAT_PORT_GET -e

