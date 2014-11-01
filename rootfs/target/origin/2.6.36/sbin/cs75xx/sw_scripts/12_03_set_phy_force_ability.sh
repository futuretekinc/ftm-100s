#!/bin/sh
sw_cfg -c RTK_PORT_PHY_FORCE_ABILITY_SET -s
sw_cfg -c RTK_PORT_PHY_FORCE_ABILITY_SET -f port -v 2
sw_cfg -c RTK_PORT_PHY_FORCE_ABILITY_SET -f ability.Half_10 -v 0
sw_cfg -c RTK_PORT_PHY_FORCE_ABILITY_SET -f ability.Full_10 -v 0
sw_cfg -c RTK_PORT_PHY_FORCE_ABILITY_SET -f ability.Half_100 -v 0
sw_cfg -c RTK_PORT_PHY_FORCE_ABILITY_SET -f ability.Full_100 -v 1
sw_cfg -c RTK_PORT_PHY_FORCE_ABILITY_SET -f ability.Full_1000 -v 0
sw_cfg -c RTK_PORT_PHY_FORCE_ABILITY_SET -f ability.FC -v 0
sw_cfg -c RTK_PORT_PHY_FORCE_ABILITY_SET -f ability.AsyFC -v 0
sw_cfg -c RTK_PORT_PHY_FORCE_ABILITY_SET -e

