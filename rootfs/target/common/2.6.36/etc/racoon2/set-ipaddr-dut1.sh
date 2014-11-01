#!/bin/sh
#
/etc/init.d/qos stop
/etc/init.d/qos disable
/etc/init.d/firewall stop
/etc/init.d/firewall disable
#LAN
uci set network.lan.proto=static
uci set network.lan.ifname=eth0
uci set network.lan.ipaddr=192.168.1.1
uci set network.lan.netmask=255.255.255.0
uci set network.lan.ip6addr=2001:DB8:0:3::1/64
#WAN
uci set network.wan.proto=static
uci set network.wan.ifname=eth1
uci set network.wan.ipaddr=192.168.60.1
uci set network.wan.netmask=255.255.255.0
uci set network.wan.gateway=192.168.60.2
uci set network.wan.ip6addr=2001:DB8:0:1::3/64
uci set network.wan.ip6gw=2001:DB8:0:1::4

uci commit
/etc/init.d/network restart
