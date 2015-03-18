#!/bin/sh

CUR_DIR=`dirname "$0"`
. $CUR_DIR/models.sh

$MODEL_SYNC_FILE
rc=$?
if [ $rc -ne 0  ] ; then
  echo "[update.sh] sync.sh failure"
  exit $rc
fi

$MODEL_PATCHES_FILE
rc=$?
if [ $rc -ne 0  ] ; then
  echo "[update.sh] patches.sh failure"
  exit $rc
fi

#restart
$CUR_DIR/restart.sh
