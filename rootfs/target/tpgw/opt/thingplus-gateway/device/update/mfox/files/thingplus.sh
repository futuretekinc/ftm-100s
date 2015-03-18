#!/bin/sh

MODEL="mfox"
#BASE_DIR=$HOME/thingplus

if [ -z $BASE_DIR ]; then
  LINK_DIR=$(readlink -f $0)
  if [ -n $LINK_DIR ]; then
    BASE_DIR=`readlink -f $(dirname $LINK_DIR)/../../../../..`
  else
    CUR_DIR=`dirname "$0"`
    BASE_DIR=`readlink -f $CUR_DIR/../../../../..`
  fi
fi

TASK="node"

OPTIONS=
APP_DIR="$BASE_DIR/thingplus-gateway/device"
LOG_DIR="$BASE_DIR/log"
STORE_DIR="$BASE_DIR/store"
RSYNC_FILE="$APP_DIR/update/$MODEL/sync.sh"
BIN_PATH="$APP_DIR/update/$MODEL/bin"
export NODE_CONFIG_DIR="$BASE_DIR/config"

pathadd() {
    if [ -d "$1" ] && [[ ":$PATH:" != *":$1:"* ]]; then
        PATH="${PATH:+"$PATH:"}$1"
    fi
}

if [ -d $BIN_PATH ]; then
  pathadd $BIN_PATH
fi
if [ ! -h "$BASE_DIR/thingplus.sh" ]; then
  ln -s "$APP_DIR/update/$MODEL/files/thingplus.sh" "$BASE_DIR/thingplus.sh"
fi
if [ ! -h "$BASE_DIR/sw_update.sh" ]; then
  ln -s "$APP_DIR/update/$MODEL/sync.sh" "$BASE_DIR/sw_update.sh"
fi
if [ ! -d $LOG_DIR ] ; then
  mkdir -p $LOG_DIR
fi
if [ ! -h "$LOG_DIR/config" ] ; then
  ln -s "$APP_DIR/update/$MODEL/files/svlogd-config" "$LOG_DIR/config"
fi
if [ ! -d $STORE_DIR ] ; then
  mkdir -p $STORE_DIR
fi
if [ ! -d "$NODE_CONFIG_DIR" ] ; then
  mkdir -p $NODE_CONFIG_DIR
fi

if [ ! -f "$NODE_CONFIG_DIR/default.js" ] ; then
  ln -s $APP_DIR/config/default.js $NODE_CONFIG_DIR/default.js
fi

if [ -f "$APP_DIR/update/$MODEL/files/node-config_local.json" ] ; then
  if [ ! -h "$NODE_CONFIG_DIR/local.json" ] ; then
    ln -s "$APP_DIR/update/$MODEL/files/node-config_local.json" "$NODE_CONFIG_DIR/local.json"
  fi
fi
if [ -f "$APP_DIR/update/$MODEL/files/node-config_local.js" ] ; then
  if [ ! -h "$NODE_CONFIG_DIR/local.js" ] ; then
    ln -s "$APP_DIR/update/$MODEL/files/node-config_local.js" "$NODE_CONFIG_DIR/local.js"
  fi
fi

if [ -f $APP_DIR/app.js ] ;  then
  CMD="$TASK $OPTIONS app.js"
else
  CMD="$TASK $OPTIONS app.min.js"
fi

SVLOGD=`which svlogd`
if [ -z "$SVLOGD" ]; then
  SVLOGD="$APP_DIR/update/$MODEL/files/busybox.$(uname -m) svlogd"
fi

PID_FILE="$BASE_DIR/thingplus.pid"
if [ -f $PID_FILE ] ; then
  PID=`cat $PID_FILE`
  if ps -p $PID > /dev/null 2>&1
  then
    IS_RUNNING=1;
  else
    IS_RUNNING=0;
  fi
else
  IS_RUNNING=0;
fi

case "$1" in
  status)
    if [ $IS_RUNNING -eq 1 ] ; then
      echo "running"
    else
      echo "stopped"
    fi
    ;;

  start)
    #recover rsync if needed
    $RSYNC_FILE -r

    if [ $IS_RUNNING -eq 0 ] ; then
      cd $APP_DIR
      ($CMD 2>&1 & echo $! >&3 ) 3>$PID_FILE | $SVLOGD $LOG_DIR &
    else
      echo "already running"
    fi
    ;;

  stop)
    sync
    if [ $IS_RUNNING -eq 1 ] ; then
      kill "$PID" 2> /dev/null;
      sync; sleep 1;
      kill -9 "$PID" 2> /dev/null;
      rm -f $PID_FILE;
    else
      echo "not running"
    fi
    ;;

  restart)
    "$0"  stop
    sleep 5;
    "$0"  start
    ;;

  setup)
    #setup only
    ;;
  *)
    echo "Usage: $0 {start|stop|restart}"
    exit 1
esac
