#!/bin/sh

# Load switch driver and daemon
/sbin/cs75xx/sw_scripts/sw_drv.sh restart
sleep 10

# Go through all test items
/sbin/cs75xx/sw_scripts/13_01_reset_port_mib_counters.sh
# step 2
ping 192.168.61.55 -c 10
#end of step 2
/sbin/cs75xx/sw_scripts/13_03_get_port_mib_counter.sh
/sbin/cs75xx/sw_scripts/13_04_get_port_all_mib_counter.sh
/sbin/cs75xx/sw_scripts/01_01_add_mac_entry.sh
/sbin/cs75xx/sw_scripts/01_02_get_mac_entry.sh
/sbin/cs75xx/sw_scripts/01_03_del_mac_entry.sh
/sbin/cs75xx/sw_scripts/01_04_add_mc_mac_entry.sh
/sbin/cs75xx/sw_scripts/01_05_get_mc_mac_entry.sh
/sbin/cs75xx/sw_scripts/01_06_del_mc_mac_entry.sh
/sbin/cs75xx/sw_scripts/02_01_add_vlan_entry.sh
/sbin/cs75xx/sw_scripts/02_02_get_vlan_entry.sh
/sbin/cs75xx/sw_scripts/02_03_set_pvid.sh
/sbin/cs75xx/sw_scripts/02_04_get_pvid.sh
/sbin/cs75xx/sw_scripts/03_01_set_accpet_frame_type.sh
/sbin/cs75xx/sw_scripts/03_02_get_accpet_frame_type.sh
/sbin/cs75xx/sw_scripts/04_01_set_ingress_filtering_check.sh
/sbin/cs75xx/sw_scripts/04_02_get_ingress_filtering_check.sh
/sbin/cs75xx/sw_scripts/05_01_set_vlan_priority.sh
/sbin/cs75xx/sw_scripts/05_02_get_vlan_priority.sh
/sbin/cs75xx/sw_scripts/06_01_set_egress_tag_mode.sh
/sbin/cs75xx/sw_scripts/06_02_get_egress_tag_mode.sh
/sbin/cs75xx/sw_scripts/07_01_set_dot1p_map_to_internal.sh
/sbin/cs75xx/sw_scripts/07_02_get_dot1p_map_to_internal.sh
/sbin/cs75xx/sw_scripts/07_03_set_dscp_map_to_internal.sh
/sbin/cs75xx/sw_scripts/07_04_get_dscp_map_to_internal.sh
/sbin/cs75xx/sw_scripts/07_05_set_port_map_to_internal_priority.sh
/sbin/cs75xx/sw_scripts/07_06_get_port_map_to_internal_priority.sh
/sbin/cs75xx/sw_scripts/07_07_set_priority_decision.sh
/sbin/cs75xx/sw_scripts/07_08_get_priority_decision.sh
/sbin/cs75xx/sw_scripts/08_01_set_queue_number.sh
/sbin/cs75xx/sw_scripts/08_02_get_queue_number.sh
/sbin/cs75xx/sw_scripts/08_03_set_priority_map_to_queue.sh
/sbin/cs75xx/sw_scripts/08_04_get_priority_map_to_queue.sh
/sbin/cs75xx/sw_scripts/08_05_set_queue_weight.sh
/sbin/cs75xx/sw_scripts/08_06_get_queue_weight.sh
/sbin/cs75xx/sw_scripts/09_01_set_8021p_remark_enable.sh
/sbin/cs75xx/sw_scripts/09_02_get_8021p_remark_enable.sh
/sbin/cs75xx/sw_scripts/09_03_set_8021p_remark.sh
/sbin/cs75xx/sw_scripts/09_04_get_8021p_remark.sh
/sbin/cs75xx/sw_scripts/09_05_set_dscp_remark_enable.sh
/sbin/cs75xx/sw_scripts/09_06_get_dscp_remark_enable.sh
/sbin/cs75xx/sw_scripts/09_07_set_dscp_remark.sh
/sbin/cs75xx/sw_scripts/09_08_get_dscp_remark.sh
/sbin/cs75xx/sw_scripts/10_01_add_acl_config.sh
/sbin/cs75xx/sw_scripts/10_02_get_acl_config.sh
/sbin/cs75xx/sw_scripts/10_03_del_acl_config.sh
/sbin/cs75xx/sw_scripts/10_04_del_all_acl_config.sh
/sbin/cs75xx/sw_scripts/11_01_set_ingress_acl_state.sh
/sbin/cs75xx/sw_scripts/11_02_get_ingress_acl_state.sh
/sbin/cs75xx/sw_scripts/12_01_set_phy_an_ability.sh
/sbin/cs75xx/sw_scripts/12_02_get_phy_an_ability.sh
/sbin/cs75xx/sw_scripts/12_03_set_phy_force_ability.sh
/sbin/cs75xx/sw_scripts/12_04_get_phy_force_ability.sh
/sbin/cs75xx/sw_scripts/12_05_get_phy_status.sh
/sbin/cs75xx/sw_scripts/14_01_set_port_mirror.sh
/sbin/cs75xx/sw_scripts/14_02_get_port_mirror.sh
/sbin/cs75xx/sw_scripts/14_03_set_port_mirror_isolation.sh
/sbin/cs75xx/sw_scripts/14_04_get_port_mirror_isolation.sh

