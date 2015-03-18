#!/bin/sh

if [ -x /iot/tpgw.sh ]; then
  /iot/tpgw.sh stop;
  sleep 5;
  /iot/tpgw.sh start;
else
  sync; sleep 5; sync; reboot;
fi
