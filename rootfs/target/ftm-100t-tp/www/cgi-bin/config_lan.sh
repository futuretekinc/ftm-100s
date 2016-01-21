#!/bin/sh
cat /etc/network/interfaces | awk -f config_lan.awk
