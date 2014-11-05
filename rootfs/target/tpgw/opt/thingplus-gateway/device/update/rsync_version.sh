#!/bin/sh

UPDATE_DIR=`dirname "$0"`
if [ -f "$UPDATE_DIR/models.sh" ]; then
  . $UPDATE_DIR/models.sh
else # one level up from model directory
  if [ -f "$UPDATE_DIR/../models.sh" ]; then
    UPDATE_DIR="$UPDATE_DIR/.."
    . $UPDATE_DIR/models.sh
  fi
fi

if [ ! -z "$MODEL_SYNC_FILE" ]; then
  VERSION_FILE=$UPDATE_DIR/../../VERSION
  REMOTE_VERSION_FILE=$UPDATE_DIR/../../REMOTE_VERSION

  #get remote version
  $MODEL_SYNC_FILE -v

  if [ -f $VERSION_FILE ]; then
    echo @@local
    cat $VERSION_FILE
  fi
  if [ -f $REMOTE_VERSION_FILE ]; then
    echo @@remote
    cat $REMOTE_VERSION_FILE
  fi
  exit $?
else
  echo "[version.sh]No method to version check" 1>&2
  exit 1
fi
