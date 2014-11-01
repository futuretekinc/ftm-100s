#!/bin/sh
#
/etc/init.d/qos stop
/etc/init.d/qos disable
/etc/init.d/firewall stop
/etc/init.d/firewall disable
#LAN
uci set network.lan=interface
uci set network.lan.proto=static
uci set network.lan.ifname=eth0
uci set network.lan.ipaddr=192.168.1.1
uci set network.lan.netmask=255.255.255.0
uci set network.lan.defaultroute=0
uci set network.lan.peerdns=0
#WAN
uci set network.wan=interface
uci set network.wan.proto=static
uci set network.wan.ifname=eth1
uci set network.wan.ipaddr=220.168.1.1
uci set network.wan.netmask=255.255.255.0
uci set network.wan.gateway=220.168.1.254
uci set network.wan.mtu=1500
uci set network.wan.defaultroute=1
uci set network.wan.peerdns=1
uci set network.wan.dns=1.1.1.1

uci commit
/etc/init.d/network restart
