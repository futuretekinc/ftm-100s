#!/bin/sh

CUR_DIR=`dirname "$0"`
UPDATE_DIR="$CUR_DIR"
. $CUR_DIR/models.sh

if [ "$MODEL_RESTART_FILE" != "" ]; then
  $MODEL_RESTART_FILE
else
  FOREVER_AVAILE=0
  which forever > /dev/null || FOREVER_AVAILE=$?
  if [ $FOREVER_AVAILE -eq 0 ]; then
    forever restart device
  else
    echo "[restart.sh]No method to restart" 1>&2
    exit 1
  fi
fi
