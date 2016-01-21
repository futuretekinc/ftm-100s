#!/bin/ash
cat /etc/network/interfaces | awk -f interfaces.awk

