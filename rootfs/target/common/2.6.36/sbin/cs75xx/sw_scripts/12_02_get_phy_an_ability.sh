#!/bin/sh
sw_cfg -c RTK_PORT_PHY_AN_ABILITY_GET -s
sw_cfg -c RTK_PORT_PHY_AN_ABILITY_GET -f port -v 3
sw_cfg -c RTK_PORT_PHY_AN_ABILITY_GET -e

