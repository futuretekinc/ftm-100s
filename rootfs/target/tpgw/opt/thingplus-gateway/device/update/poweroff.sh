#!/bin/sh

CUR_DIR=`dirname "$0"`
UPDATE_DIR="$CUR_DIR"
. $CUR_DIR/models.sh

if [ "$MODEL_POWEROFF_FILE" != "" ]; then
  $MODEL_POWEROFF_FILE
else
  sync; sync; poweroff &
fi
