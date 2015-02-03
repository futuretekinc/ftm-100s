#!/bin/sh

is_status=`cat /etc/service/wifi`
echo status $is_status
cat /rboot/wfo_atheros_11AC/config.sh | awk '{ split($0,arr," "); printf("%s %s\n", arr[3], arr[4]); }'