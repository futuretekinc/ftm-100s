#!/bin/sh
sw_cfg -c RTK_ACL_STATE_GET -s
sw_cfg -c RTK_ACL_STATE_GET -f port -v 3
sw_cfg -c RTK_ACL_STATE_GET -e

