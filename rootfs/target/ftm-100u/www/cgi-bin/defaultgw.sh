#!/bin/ash
/sbin/route -n |  awk '{if($1 ~ /0.0.0.0/) print $2}'
