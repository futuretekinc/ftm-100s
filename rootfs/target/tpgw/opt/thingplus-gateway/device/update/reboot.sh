#!/bin/sh

CUR_DIR=`dirname "$0"`
UPDATE_DIR="$CUR_DIR"
. $CUR_DIR/models.sh

if [ "$MODEL_REBOOT_FILE" != "" ]; then
  $MODEL_REBOOT_FILE
else
  sync; sleep 5; sync; reboot &
fi
