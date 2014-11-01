#!/bin/sh
sw_cfg -c RTK_QOS_PRI_SEL_SET -s
sw_cfg -c RTK_QOS_PRI_SEL_SET -f priDec.port_pri -v 5
sw_cfg -c RTK_QOS_PRI_SEL_SET -f priDec.dot1q_pri -v 7
sw_cfg -c RTK_QOS_PRI_SEL_SET -f priDec.acl_pri -v 4
sw_cfg -c RTK_QOS_PRI_SEL_SET -f priDec.dscp_pri -v 6
sw_cfg -c RTK_QOS_PRI_SEL_SET -f priDec.cvlan_pri -v 3
sw_cfg -c RTK_QOS_PRI_SEL_SET -f priDec.svlan_pri -v 2
sw_cfg -c RTK_QOS_PRI_SEL_SET -f priDec.dmac_pri -v 1
sw_cfg -c RTK_QOS_PRI_SEL_SET -f priDec.smac_pri -v 0
sw_cfg -c RTK_QOS_PRI_SEL_SET -e

