#!/bin/sh
sw_cfg -c RTK_ACL_CFG_ADD -s
sw_cfg -c RTK_ACL_CFG_ADD -f filter_id -v 0
sw_cfg -c RTK_ACL_CFG_ADD -f filter_cfg.careTag.tagType.5.value -v 1
sw_cfg -c RTK_ACL_CFG_ADD -f filter_cfg.careTag.tagType.5.mask -v 1
sw_cfg -c RTK_ACL_CFG_ADD -f filter_cfg.activeport.dataType -v 0
sw_cfg -c RTK_ACL_CFG_ADD -f filter_cfg.activeport.value -v 0xFF
sw_cfg -c RTK_ACL_CFG_ADD -f filter_cfg.activeport.mask -v 0xFF
sw_cfg -c RTK_ACL_CFG_ADD -f filter_cfg.invert -v 0
sw_cfg -c RTK_ACL_CFG_ADD -f action.actEnable.13 -v 1
sw_cfg -c RTK_ACL_CFG_ADD -f field_num -v 3
sw_cfg -c RTK_ACL_CFG_ADD -f filter_field.0.fieldType -v 5
sw_cfg -c RTK_ACL_CFG_ADD -f filter_field.0.filter_pattern_union.sip.dataType -v 0
sw_cfg -c RTK_ACL_CFG_ADD -f filter_field.0.filter_pattern_union.sip.value -v 0xC0A80064
sw_cfg -c RTK_ACL_CFG_ADD -f filter_field.0.filter_pattern_union.sip.mask -v 0xFFFFFFFF
sw_cfg -c RTK_ACL_CFG_ADD -f filter_field.1.fieldType -v 6
sw_cfg -c RTK_ACL_CFG_ADD -f filter_field.1.filter_pattern_union.dip.dataType -v 0
sw_cfg -c RTK_ACL_CFG_ADD -f filter_field.1.filter_pattern_union.dip.value -v 0x0A000064
sw_cfg -c RTK_ACL_CFG_ADD -f filter_field.1.filter_pattern_union.dip.mask -v 0xFFFFFFFF
sw_cfg -c RTK_ACL_CFG_ADD -f filter_field.2.fieldType -v 15
sw_cfg -c RTK_ACL_CFG_ADD -f filter_field.2.filter_pattern_union.tcpSrcPort.dataType -v 0
sw_cfg -c RTK_ACL_CFG_ADD -f filter_field.2.filter_pattern_union.tcpSrcPort.value -v 0x8080
sw_cfg -c RTK_ACL_CFG_ADD -f filter_field.2.filter_pattern_union.tcpSrcPort.mask -v 0xFFFF
sw_cfg -c RTK_ACL_CFG_ADD -e

