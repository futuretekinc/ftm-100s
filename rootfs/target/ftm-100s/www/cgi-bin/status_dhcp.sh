#!/bin/ash
ps | awk 'BEGIN{count=0}{if ($5 ~/udhcpd/) { count++ }}END{ print "STATUS:", (count != 0)?"running":"stopped";}'
awk -f status_dhcp.awk /etc/udhcpd.conf

