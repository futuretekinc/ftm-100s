#!/bin/sh
sw_cfg -c RTK_PORT_MACFORCELINKEXT_SET -s
sw_cfg -c RTK_PORT_MACFORCELINKEXT_SET -f port -v $1
sw_cfg -c RTK_PORT_MACFORCELINKEXT_SET -f mode -v $2
sw_cfg -c RTK_PORT_MACFORCELINKEXT_SET -f ability.forcemode -v $3
sw_cfg -c RTK_PORT_MACFORCELINKEXT_SET -f ability.speed -v $4
sw_cfg -c RTK_PORT_MACFORCELINKEXT_SET -f ability.duplex -v 1
sw_cfg -c RTK_PORT_MACFORCELINKEXT_SET -f ability.link -v 1
sw_cfg -c RTK_PORT_MACFORCELINKEXT_SET -f ability.nway -v 0
sw_cfg -c RTK_PORT_MACFORCELINKEXT_SET -f ability.txpause -v 0
sw_cfg -c RTK_PORT_MACFORCELINKEXT_SET -f ability.rxpause -v 0
sw_cfg -c RTK_PORT_MACFORCELINKEXT_SET -e

