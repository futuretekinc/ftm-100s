#!/bin/sh

start() {
	[ ! -e "/dev/switch" ] && \
		insmod /lib/modules/`uname -r`/rtl83xx.ko
	/sbin/swSendCmd
}

stop() {
	killall -q swSendCmd
}

case "$1" in
  start)
	start
	;;
  stop)
	stop
	;;
  restart)
	stop
	start
	;;
  *)
	echo $"Usage: sw_drv.sh {start|stop|restart}"
	exit 1
esac

exit $?

