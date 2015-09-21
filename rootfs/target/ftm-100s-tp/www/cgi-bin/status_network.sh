#!/bin/sh
/sbin/ifconfig | awk -f status_network.awk
cat /etc/resolv.conf | awk 'BEGIN{ count=0; } { if (0 < NF) { print "dns", ++count, $1, $2} }'
