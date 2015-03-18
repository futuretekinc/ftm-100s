#!/bin/sh

CUR_DIR=`dirname "$0"`

MODEL=${MODEL:="bone"}
RSYNC_SERVER="rsync.thingbine.com"
SRC_URL="rsync://$MODEL@$RSYNC_SERVER:8873/$MODEL"
RSYNC_PASSWORD="bone8910"

$CUR_DIR/../rsync.sh -p $RSYNC_PASSWORD $SRC_URL $*
