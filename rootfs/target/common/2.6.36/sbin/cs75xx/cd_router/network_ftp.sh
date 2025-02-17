# Copyright (C) 2006 OpenWrt.org

config interface loopback
	option ifname	lo
	option proto	static
	option ipaddr	127.0.0.1
	option netmask	255.0.0.0

config interface lan
	option ifname	eth1
	option proto 	static
	option ipaddr	192.168.1.1
	option netmask	255.255.255.0
	option defaultroute 0
	option peerdns 0
	option ip6addr 2004::1/64
	
config interface wan
        option ifname eth2
        option proto static
        option ipaddr 12.12.12.2
        option netmask 255.255.255.0
        option gateway 12.12.12.1
        option mtu 1500
        option defaultroute 1
        option peerdns 1
        option ip6addr 3001::2/64
        option ip6gw 3001::1/64
        option dns 3001:51a:cafe::2
        
config route6
        option interface wan
        option target default
        option gateway 3001::1
        
