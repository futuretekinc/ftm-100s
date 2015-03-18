#!/bin/sh

if [ -z "$UPDATE_DIR" ]; then
UPDATE_DIR=`dirname "$0"`
fi

#override: MODEL, VERSION, VENDOR, CAPE, CAPE_VERSION etc
if [ -e "$UPDATE_DIR/thingplus.cfg" ]; then #also check existence of symlink
  . "$UPDATE_DIR/thingplus.cfg"
fi

#detect model
if [ -z "$MODEL" ]; then
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
[ -f "$UPDATE_DIR/$MODEL/reboot.sh" ] && MODEL_REBOOT_FILE=`readlink -f $UPDATE_DIR/$MODEL/reboot.sh`
[ -f "$UPDATE_DIR/$MODEL/poweroff.sh" ] && MODEL_POWEROFF_FILE=`readlink -f $UPDATE_DIR/$MODEL/poweroff.sh`
