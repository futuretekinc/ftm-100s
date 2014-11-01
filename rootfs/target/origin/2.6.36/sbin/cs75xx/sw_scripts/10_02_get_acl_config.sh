#!/bin/sh
sw_cfg -c RTK_ACL_CFG_GET -s
sw_cfg -c RTK_ACL_CFG_GET -f filter_id -v 0
sw_cfg -c RTK_ACL_CFG_GET -e

