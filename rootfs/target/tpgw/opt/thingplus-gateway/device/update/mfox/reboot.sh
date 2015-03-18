#!/bin/sh
CUR_DIR=`dirname "$0"`

INIT_D_FILE="$CUR_DIR/files/thingplus.sh"
if [ -x $INIT_D_FILE ]; then
  $INIT_D_FILE stop;
  sleep 5;
  $INIT_D_FILE start;
else
  echo "Error: failure to reboot"
  #sync; sleep 5; sync; reboot;
fi
