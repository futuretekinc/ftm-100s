#!/bin/sh

TASK="node"

OPTIONS=
BASE_DIR="/mnt/user/thingplus"
DIR="$BASE_DIR/thingplus-gateway/device"
LOG_DIR="/var/log/thingplus"
STORE_LINK_DIR="$BASE_DIR/lib"
STORE_DIR="/var/lib/thingplus"
UPDATE_DIR="$DIR/update"
RSYNC_FILE="$UPDATE_DIR/voyage/sync.sh"
NODE_BIN_PATH="$BASE_DIR/node/bin"
UTILS_BIN_PATH="$BASE_DIR/utils/bin"
ETC_LINK_DIR="$BASE_DIR/etc"
ETC_DIR="/etc/thingplus" 
export NODE_CONFIG_DIR="$ETC_LINK_DIR/config"

pathadd() {
    if [ -d "$1" ] && [[ ":$PATH:" != *":$1:"* ]]; then
        PATH="${PATH:+"$PATH:"}$1"
    fi
}
pathadd $NODE_BIN_PATH
pathadd $UTILS_BIN_PATH

if [ ! -d $LOG_DIR ] ; then
  mkdir -p $LOG_DIR
fi
if [ ! -h "$LOG_DIR/config" ] ; then
  ln -s "$UPDATE_DIR/voyage/files/svlogd-config" "$LOG_DIR/config"
fi
if [ ! -d $STORE_LINK_DIR ] ; then
  mkdir -p $STORE_LINK_DIR
  if [ ! -h $STORE_DIR ] ; then
    ln -s $STORE_LINK_DIR $STORE_DIR
  fi
fi
if [ ! -d "$ETC_LINK_DIR" ] ; then
  mkdir -p $ETC_LINK_DIR
  if [ ! -h $ETC_DIR ] ; then
    ln -s $ETC_LINK_DIR $ETC_DIR
  fi
fi
if [ ! -d "$NODE_CONFIG_DIR" ] ; then
  mkdir -p $NODE_CONFIG_DIR
fi

if [ ! -f "$NODE_CONFIG_DIR/default.js" ] ; then
  ln -s $DIR/config/default.js $NODE_CONFIG_DIR/default.js
fi
if [ -f "$UPDATE_DIR/voyage/files/node-config_local.json" ] ; then
  if [ ! -h "$NODE_CONFIG_DIR/local.json" ] ; then
    ln -s "$UPDATE_DIR/voyage/files/node-config_local.json" "$NODE_CONFIG_DIR/local.json"
  fi
fi

if [ -f $DIR/app.js ] ;  then
  CMD="$TASK $OPTIONS app.js"
else
  CMD="$TASK $OPTIONS app.min.js"
fi

SVLOGD=`which svlogd`
if [ -z "$SVLOGD" ]; then
  SVLOGD="$APP_DIR/update/$MODEL/files/busybox.$(uname -m) svlogd"
fi

case "$1" in
  status)
    if pidof $TASK | sed "s/$$\$//" | grep -q [0-9] ; then
      echo "running"
    else
      echo "stopped"
    fi
    ;;

  start)
    #recover rsync if needed
    $RSYNC_FILE -r

    if ! pidof $TASK | sed "s/$$\$//" | grep -q [0-9] ; then
      cd $DIR
      $CMD 2>&1 | $SVLOGD $LOG_DIR &
    fi
    ;;

  stop)
    sync
    pkill $TASK 2> /dev/null &
    ;;

  restart)
    "$0"  stop
    sleep 5;
    "$0"  start
    ;;

  *)
    echo "Usage: $0 {start|stop|restart}"
    exit 1
esac
