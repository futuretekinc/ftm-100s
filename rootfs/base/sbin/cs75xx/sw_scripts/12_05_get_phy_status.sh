#!/bin/sh
sw_cfg -c RTK_PORT_PHY_STATUS_GET -s
sw_cfg -c RTK_PORT_PHY_STATUS_GET -f port -v 3
sw_cfg -c RTK_PORT_PHY_STATUS_GET -e

