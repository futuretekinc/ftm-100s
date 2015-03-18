#!/bin/sh

CUR_DIR=`dirname $(readlink -f $0)`
if [ -z $CUR_DIR ]; then
  CUR_DIR=`dirname "$0"`
fi

MODEL=${MODEL:="darwin"}
RSYNC_SERVER="rsync.thingbine.com"
SRC_URL="rsync://$MODEL@$RSYNC_SERVER:8873/$MODEL"
RSYNC_PASSWORD="darwin8910"

$CUR_DIR/../rsync.sh -p $RSYNC_PASSWORD $SRC_URL $*
