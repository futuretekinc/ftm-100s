#!/bin/sh
killall hostapd
sleep 2
hostapd /etc/hostapd.conf &
