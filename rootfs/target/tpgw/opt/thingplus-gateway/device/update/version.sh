#!/bin/sh

CUR_DIR=`dirname "$0"`
UPDATE_DIR="$CUR_DIR"
. $CUR_DIR/models.sh

if [ "$MODEL_VERSION_FILE" != "" ]; then
  $MODEL_VERSION_FILE
else
  echo "[version.sh]No method to version check" 1>&2
  exit 1
fi
