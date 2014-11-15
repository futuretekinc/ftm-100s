#!/bin/ash
ps | awk 'BEGIN{count=0}{if ($4 ~/udhcpd/) { count++ }}END{ if (count != 0) {print "enable"} else {print "disable"}}'
awk '{if($1 ~ /^start/) print $2;if($1 ~ /^end/) print $2;if (($1 ~ /^opt/) && ($2 ~ /lease/)) print $3}' /etc/udhcp/udhcpd.conf
