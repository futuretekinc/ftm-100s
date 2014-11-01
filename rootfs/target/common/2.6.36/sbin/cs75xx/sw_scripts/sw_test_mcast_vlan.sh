#!/bin/sh

# remove original bridge interface
ifconfig br-lan 0.0.0.0 down
brctl delbr br-lan
# start switch-config daemon
/sbin/cs75xx/sw_scripts/sw_drv.sh start

# create VLAN-devices and new bridge interfaces
vconfig add eth1_0 0
vconfig add eth1_1 0
vconfig add eth1_2 0
vconfig add eth1_3 0
brctl addbr br-lan
brctl addif br-lan eth1_0.0
brctl addif br-lan eth1_1.0
brctl addif br-lan eth1_2.0
brctl addif br-lan eth1_3.0
ifconfig eth1_0.0 up
ifconfig eth1_1.0 up
ifconfig eth1_2.0 up
ifconfig eth1_3.0 up
ifconfig br-lan 192.168.1.1
vconfig add eth0 200
vconfig add eth1_1 200
brctl addbr br200
brctl addif br200 eth0.200
brctl addif br200 eth1_1.200
ifconfig eth0.200 up
ifconfig eth1_1.200 up
ifconfig br200 up

# configure switch chip
sw_cfg -c RTK_VLAN_SET -s
sw_cfg -c RTK_VLAN_SET -f vid -v 0
sw_cfg -c RTK_VLAN_SET -f mbrmsk -v 0xFF
sw_cfg -c RTK_VLAN_SET -f untagmsk -v 0x0F
sw_cfg -c RTK_VLAN_SET -e

sw_cfg -c RTK_VLAN_SET -s
sw_cfg -c RTK_VLAN_SET -f vid -v 200
sw_cfg -c RTK_VLAN_SET -f mbrmsk -v 0x22
sw_cfg -c RTK_VLAN_SET -f untagmsk -v 0x02
sw_cfg -c RTK_VLAN_SET -e

sw_cfg -c RTK_VLAN_PVID_SET -s
sw_cfg -c RTK_VLAN_PVID_SET -f port -v 0
sw_cfg -c RTK_VLAN_PVID_SET -f pvid -v 0
sw_cfg -c RTK_VLAN_PVID_SET -e

sw_cfg -c RTK_VLAN_PVID_SET -s
sw_cfg -c RTK_VLAN_PVID_SET -f port -v 1
sw_cfg -c RTK_VLAN_PVID_SET -f pvid -v 0
sw_cfg -c RTK_VLAN_PVID_SET -e

sw_cfg -c RTK_VLAN_PVID_SET -s
sw_cfg -c RTK_VLAN_PVID_SET -f port -v 2
sw_cfg -c RTK_VLAN_PVID_SET -f pvid -v 0
sw_cfg -c RTK_VLAN_PVID_SET -e

sw_cfg -c RTK_VLAN_PVID_SET -s
sw_cfg -c RTK_VLAN_PVID_SET -f port -v 3
sw_cfg -c RTK_VLAN_PVID_SET -f pvid -v 0
sw_cfg -c RTK_VLAN_PVID_SET -e

