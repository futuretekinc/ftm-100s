#!/bin/sh

CUR_DIR=`dirname "$0"`

#RSYNC_SERVER="rsync.thingbine.com"
RSYNC_SERVER=`ping -c 1  rsync.thingbine.com | head -n1 | sed "s/.*(\([0-9]*\.[0-9]*\.[0-9]*\.[0-9]*\)).*/\1/g"` #FIXME: ftm50s cannot resolve this host

SRC_URL="rsync://futuretek@$RSYNC_SERVER:8873/ftm50s"
BASE_DIR="/mnt/mtd"
if [ ! -d $BASE_DIR ]; then
  BASE_DIR="$HOME"
fi
DST_DIR="$BASE_DIR/thingplus-gateway"

$CUR_DIR/../rsync.sh -p future123 $SRC_URL $DST_DIR $*
