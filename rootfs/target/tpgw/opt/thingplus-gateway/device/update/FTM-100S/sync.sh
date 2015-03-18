#!/bin/sh
CUR_DIR=`dirname $(readlink -f $0)`
if [ -z $CUR_DIR ]; then
  CUR_DIR=`dirname "$0"`
fi

RSYNC_USER="futuretek"
RSYNC_PASSWORD="future123"
RSYNC_SERVER=`ping -c 1  rsync.thingbine.com | head -n1 | sed "s/.*(\([0-9]*\.[0-9]*\.[0-9]*\.[0-9]*\)).*/\1/g"` #FIXME: ftm50s cannot resolve this host
SRC_URL="rsync://$RSYNC_USER@$RSYNC_SERVER:8873/$RSYNC_USER"
SIZE_ONLY="-s"

$CUR_DIR/../rsync.sh $SIZE_ONLY -p $RSYNC_PASSWORD $SRC_URL $*
