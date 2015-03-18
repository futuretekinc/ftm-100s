#***************************************************
#! /bin/sh
### BEGIN INIT INFO
# Provides:          wvdial.sh
# Required-Start:    $remote_fs $syslog
# Required-Stop:     $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: wvdial.sh
# Description:       daliworks wvdial.sh
### END INIT INFO

#enable serial port
if [ ! -e /dev/ttyO1 ]; then
  echo "enable ttyO1"
  SLOT=`echo /sys/devices/bone_capemgr*/slots`
  if [ -e /lib/firmware/ttyO1_armhf.com-00A0.dtbo ]; then
    echo ttyO1_armhf.com > ${SLOT}
  else
    echo "fail to locate /lib/firmware/ttyO1_armhf.com-00A0.dtbo"
  fi
fi

check_enable() {
  ENABLED=$(sed -n 's/.*Enable *= *\([^ ]*.*\)/\1/p' < /etc/wvdial.conf)
  if [ "$ENABLED" = "true" ]; then
    echo "Modem is ENABLED."
  else
    echo "Modem is DISABLED, check /etc/wvdial.conf"
    exit 0
  fi
}

check_modem() {
  /usr/bin/wvdialconf /dev/null
  EXIT_CODE=$?
  if [ $EXIT_CODE -eq 0 ]; then
    echo Modem FOUND
  else
    echo Modem NOT FOUND
    exit 0
  fi
}

start() {
  echo "Starting wvdial"

  check_enable

  #exit if already running
  /sbin/start-stop-daemon --status --exec /usr/bin/wvdial 
  EXIT_CODE=$?
  if [ $EXIT_CODE -eq 0 ]; then
    echo wvdial is already RUNNING
    exit 1;
  fi

  check_modem

  # run application you want to start
  /sbin/start-stop-daemon --start --background -v  --exec /usr/bin/wvdial 
}

stop() {
  echo "Stopping wvdial"
  /sbin/start-stop-daemon --status --exec /usr/bin/wvdial 
  EXIT_CODE=$?
  if [ $EXIT_CODE -eq 0 ]; then
    # kill application you want to stop
    /sbin/start-stop-daemon --stop --exec /usr/bin/wvdial 
    sleep 5
  fi
}

status() {
  # kill application you want to stop
  /sbin/start-stop-daemon --status --exec /usr/bin/wvdial 
  EXIT_CODE=$?
  if [ $EXIT_CODE -eq 0 ]; then
    echo wvdial is RUNNING
  else
    echo wvdial is NOT RUNNING
  fi
  exit $EXIT_CODE
}

case "$1" in
  start)
    start
    ;;
  stop)
    stop
    ;;
  status)
    status
    ;;
  restart)
    stop
    start
    ;;
  *)
    echo "Usage: /etc/init.d/wvdial {start|status|restart|status}"
    exit 1
    ;;
esac

exit 0
#*********************************************************
