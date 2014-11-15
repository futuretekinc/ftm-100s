#!/bin/sh
/sbin/ifconfig | awk -f /bin/status_network.awk | awk '/usb0/'
