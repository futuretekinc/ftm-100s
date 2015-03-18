#!/bin/sh

INIT_D_FILE="./files/thingplus.sh"
if [ -x $INIT_D_FILE ]; then
  $INIT_D_FILE stop;
  sleep 5;
  $INIT_D_FILE start;
else
  echo "Error: failure to restart"
  #sync; sleep 5; sync; reboot;
fi
