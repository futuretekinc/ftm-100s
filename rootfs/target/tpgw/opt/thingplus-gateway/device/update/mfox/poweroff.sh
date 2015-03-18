#!/bin/sh
CUR_DIR=`dirname "$0"`

INIT_D_FILE="$CUR_DIR/files/thingplus.sh"
if [ -x $INIT_D_FILE ]; then
  sync;
  $INIT_D_FILE stop;
  sleep 1;
else
  echo "Error: failure to poweroff"
  #sync; sleep 5; sync; reboot;
fi
