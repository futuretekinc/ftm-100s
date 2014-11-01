#!/bin/sh
sw_cfg -c RTK_QOS_PRI_MAP_SET -s
sw_cfg -c RTK_QOS_PRI_MAP_SET -f queue_num -v 4
sw_cfg -c RTK_QOS_PRI_MAP_SET -f pri2qid.pri2queue.0 -v 3
sw_cfg -c RTK_QOS_PRI_MAP_SET -f pri2qid.pri2queue.1 -v 3
sw_cfg -c RTK_QOS_PRI_MAP_SET -f pri2qid.pri2queue.2 -v 2
sw_cfg -c RTK_QOS_PRI_MAP_SET -f pri2qid.pri2queue.3 -v 2
sw_cfg -c RTK_QOS_PRI_MAP_SET -f pri2qid.pri2queue.4 -v 1
sw_cfg -c RTK_QOS_PRI_MAP_SET -f pri2qid.pri2queue.5 -v 1
sw_cfg -c RTK_QOS_PRI_MAP_SET -f pri2qid.pri2queue.6 -v 0
sw_cfg -c RTK_QOS_PRI_MAP_SET -f pri2qid.pri2queue.7 -v 0
sw_cfg -c RTK_QOS_PRI_MAP_SET -e

