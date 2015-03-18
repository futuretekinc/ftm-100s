#!/bin/sh
INIT_CMD="/mnt/user/thingplus/tpgw.sh"
if [ -x $INIT_CMD ]; then
  $INIT_CMD stop;
  sleep 5;
  $INIT_CMD start;
else
  sync; sleep 5; sync; restart-secure;
fi
