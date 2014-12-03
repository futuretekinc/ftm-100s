#!/bin/sh
cat /etc/hostapd.conf | awk '{ split($0,arr,"="); printf("%s %s\n", arr[1], arr[2]); }'
