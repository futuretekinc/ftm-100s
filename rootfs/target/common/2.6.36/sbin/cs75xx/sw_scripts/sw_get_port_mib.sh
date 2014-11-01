#!/bin/sh
# get all counters of the specified port
# USAGE: sw_get_port_mib.sh [port]
# port     --   0-3: LAN, 5: CPU port

sw_cfg -c RTK_STAT_PORT_GETALL -s
sw_cfg -c RTK_STAT_PORT_GETALL -f port -v $1
sw_cfg -c RTK_STAT_PORT_GETALL -e

