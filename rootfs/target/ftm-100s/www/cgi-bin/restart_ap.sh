#!/bin/sh
ifconfig wifi0 down
sleep 2
/etc/init.d/wifi start
echo done