#!/bin/sh
sw_cfg -c RTK_PORT_PHYREG_GET -s
sw_cfg -c RTK_PORT_PHYREG_GET -f port -v $1
sw_cfg -c RTK_PORT_PHYREG_GET -f reg -v $2
sw_cfg -c RTK_PORT_PHYREG_GET -e

