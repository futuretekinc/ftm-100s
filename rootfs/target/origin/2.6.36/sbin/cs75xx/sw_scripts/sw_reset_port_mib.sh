#!/bin/sh
# reset port counters
# USAGE: sw_reset_port_mib.sh [port]
# port     --   0-3: LAN, 5: CPU port

sw_cfg -c RTK_STAT_PORT_RESET -s
sw_cfg -c RTK_STAT_PORT_RESET -f port -v $1
sw_cfg -c RTK_STAT_PORT_RESET -e

