#!/bin/sh

CUR_DIR=`dirname "$0"`

#RSYNC_SERVER="rsync.thingbine.com"
RSYNC_SERVER=`ping -c 1  rsync.thingbine.com | head -n1 | sed "s/.*(\([0-9]*\.[0-9]*\.[0-9]*\.[0-9]*\)).*/\1/g"` #FIXME: ftm50s cannot resolve this host
SRC_URL="rsync://alticast@$RSYNC_SERVER:8873/alticast"

$CUR_DIR/../rsync.sh -p HPCcS1z9zvjY $SRC_URL $DST_DIR $*
