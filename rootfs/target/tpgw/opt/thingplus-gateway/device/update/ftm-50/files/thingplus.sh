#!/bin/sh

MODEL="ftm-50"
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

TASK="node"
#OPTIONS="--stack_size=1024 --max_old_space_size=20 --max_new_space_size=4096 --max_executable_size=10 --gc_global --gc_interval=100 --trace-gc --track_gc_object_stats --trace_gc_verbose"
OPTIONS="--stack_size=1024 --max_old_space_size=20 --max_new_space_size=4096 --max_executable_size=10"

if [ -f $APP_DIR/app.js ] ;  then
  CMD="$TASK $OPTIONS app.js"
else
  CMD="$TASK $OPTIONS app.min.js"
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
			cd $APP_DIR
			$CMD 2>&1 | svlogd $LOG_DIR &
		fi	
		;;

	stop) 
		pkill $TASK 2> /dev/null &
		;;

	restart)
		"$0"	stop
    sleep 5;
		"$0"	start
		;;

	setup)
    # do nothing; already done;
    ;;

	*)
		echo $"Usage: $0 {start|stop|restart}"
		exit 1
esac
