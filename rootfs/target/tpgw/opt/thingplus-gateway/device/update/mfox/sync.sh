#!/bin/sh
CUR_DIR=`dirname $(readlink -f $0)`
if [ -z $CUR_DIR ]; then
  CUR_DIR=`dirname "$0"`
fi

RSYNC_USER="mfox"
RSYNC_PASSWORD='rG=!f5qg2Th@F]V'
RSYNC_SERVER="rsync.thingbine.com"
SRC_URL="rsync://$RSYNC_USER@$RSYNC_SERVER:8873/$RSYNC_USER"

$CUR_DIR/../rsync.sh -p $RSYNC_PASSWORD $SRC_URL $*
