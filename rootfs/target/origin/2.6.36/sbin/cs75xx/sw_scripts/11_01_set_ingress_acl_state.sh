#!/bin/sh
sw_cfg -c RTK_ACL_STATE_SET -s
sw_cfg -c RTK_ACL_STATE_SET -f port -v 3
sw_cfg -c RTK_ACL_STATE_SET -f state -v 1
sw_cfg -c RTK_ACL_STATE_SET -e

