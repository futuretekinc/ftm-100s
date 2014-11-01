#!/bin/sh
sw_cfg -c RTK_PORT_RGMIIDELAYEXT_GET -s
sw_cfg -c RTK_PORT_RGMIIDELAYEXT_GET -f port -v $1
sw_cfg -c RTK_PORT_RGMIIDELAYEXT_GET -e

