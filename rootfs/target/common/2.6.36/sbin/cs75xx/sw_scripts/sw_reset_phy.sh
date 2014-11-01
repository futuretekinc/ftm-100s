#!/bin/sh
# reset all PHYs of switch LAN ports 0 ~ 3
# USAGE: sw_reset_phy.sh

# disable all PHYs
sw_cfg -c RTK_PORT_ENABLE_ALL_SET -s
sw_cfg -c RTK_PORT_ENABLE_ALL_SET -f enable -v 0
sw_cfg -c RTK_PORT_ENABLE_ALL_SET -e

sleep 5

# enable all PHYs
sw_cfg -c RTK_PORT_ENABLE_ALL_SET -s
sw_cfg -c RTK_PORT_ENABLE_ALL_SET -f enable -v 1
sw_cfg -c RTK_PORT_ENABLE_ALL_SET -e
