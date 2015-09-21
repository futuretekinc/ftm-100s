#!/bin/ash
awk '{if($1 ~ /nameserver/) print $2}' /etc/resolv.conf 
