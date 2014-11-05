#!/bin/sh

if [ -x /etc/init.d/tpgw ]; then
  /etc/init.d/tpgw stop;
  sleep 5;
  /etc/init.d/tpgw start;
else
  sync; sleep 5; sync; reboot;
fi
