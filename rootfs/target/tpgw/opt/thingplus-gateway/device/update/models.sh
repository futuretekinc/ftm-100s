#!/bin/sh

if [ -z "$UPDATE_DIR" ]; then
UPDATE_DIR=`dirname "$0"`
fi

#### CUSTOMZIE model list
MODELS=`cd "$UPDATE_DIR"; ls -d */ | sed -e "s/\///g"`
#########

#find model from uname
UNAME=`uname -sr | tr "[:upper:]" "[:lower:]"`
for model in $MODELS; do
  if [ "${UNAME#*$model}" != "$UNAME" ]; then
    MODEL=$model 
  fi
done

#override: MODEL, VERSION, VENDOR, CAPE, CAPE_VERSION etc
if [ -f /etc/default/vendor ]; then
  . /etc/default/vendor
fi

if [ -z $MODEL ]; then
  echo "model not found"
  exit 1;
#else
#  echo "Found model: [$MODEL]"
fi

[ -f "$UPDATE_DIR/$MODEL/patches.sh" ] && MODEL_PATCHES_FILE=`readlink -f $UPDATE_DIR/$MODEL/patches.sh`
[ -f "$UPDATE_DIR/$MODEL/sync.sh" ] && MODEL_SYNC_FILE=`readlink -f $UPDATE_DIR/$MODEL/sync.sh`
[ -f "$UPDATE_DIR/$MODEL/version.sh" ] && MODEL_VERSION_FILE=`readlink -f $UPDATE_DIR/$MODEL/version.sh`
[ -f "$UPDATE_DIR/$MODEL/restart.sh" ] && MODEL_RESTART_FILE=`readlink -f $UPDATE_DIR/$MODEL/restart.sh`
