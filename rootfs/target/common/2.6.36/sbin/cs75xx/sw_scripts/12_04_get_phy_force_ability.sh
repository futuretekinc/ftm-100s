#!/bin/sh
sw_cfg -c RTK_PORT_PHY_FORCE_ABILITY_GET -s
sw_cfg -c RTK_PORT_PHY_FORCE_ABILITY_GET -f port -v 2
sw_cfg -c RTK_PORT_PHY_FORCE_ABILITY_GET -e

