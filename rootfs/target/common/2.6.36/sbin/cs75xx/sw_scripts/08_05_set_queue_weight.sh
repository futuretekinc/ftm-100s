#!/bin/sh
sw_cfg -c RTK_QOS_SCHE_QUE_SET -s
sw_cfg -c RTK_QOS_SCHE_QUE_SET -f port -v 3
sw_cfg -c RTK_QOS_SCHE_QUE_SET -f qweights.weights.0 -v 1
sw_cfg -c RTK_QOS_SCHE_QUE_SET -f qweights.weights.1 -v 5
sw_cfg -c RTK_QOS_SCHE_QUE_SET -f qweights.weights.2 -v 10
sw_cfg -c RTK_QOS_SCHE_QUE_SET -f qweights.weights.3 -v 0
sw_cfg -c RTK_QOS_SCHE_QUE_SET -f qweights.weights.4 -v 0
sw_cfg -c RTK_QOS_SCHE_QUE_SET -f qweights.weights.5 -v 0
sw_cfg -c RTK_QOS_SCHE_QUE_SET -f qweights.weights.6 -v 0
sw_cfg -c RTK_QOS_SCHE_QUE_SET -f qweights.weights.7 -v 0
sw_cfg -c RTK_QOS_SCHE_QUE_SET -e

