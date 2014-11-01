#!/bin/sh
sw_cfg -c RTK_ACL_CFG_DEL -s
sw_cfg -c RTK_ACL_CFG_DEL -f filter_id -v 0
sw_cfg -c RTK_ACL_CFG_DEL -e

