#!/bin/sh

is_status=`cat /etc/service/wifi`
echo status $is_status
cat /etc/wifi_config.sh | awk '{ split($0,arr," "); printf("%s %s\n", arr[3], arr[4]); }'
