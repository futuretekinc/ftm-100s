#!/bin/sh
sw_cfg -c RTK_PORT_RGMIIDELAYEXT_SET -s
sw_cfg -c RTK_PORT_RGMIIDELAYEXT_SET -f port -v $1
sw_cfg -c RTK_PORT_RGMIIDELAYEXT_SET -f txDelay -v $2
sw_cfg -c RTK_PORT_RGMIIDELAYEXT_SET -f rxDelay -v $3
sw_cfg -c RTK_PORT_RGMIIDELAYEXT_SET -e

