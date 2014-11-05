#!/bin/sh

CUR_DIR=`dirname "$0"`
cd $CUR_DIR
CUR_DIR="$PWD"

#####################
## 1. Log rotate config
#####################
SENSORJS_LOGROTATE_CONFIG=$CUR_DIR/files/sensorjs
SENSORJS_LOGROTATE_CONFIG_PATH=/etc/logrotate.d/sensorjs
CRON_HOURLY_PATH=/etc/cron.hourly/logrotate
CRON_DAILY_PATH=/etc/cron.daily/logrotate
#copy logrotate config and change in cron daily -> hourly
if [ -f ${SENSORJS_LOGROTATE_CONFIG_PATH} ] && [ ! -L ${SENSORJS_LOGROTATE_CONFIG_PATH} ]; then
  echo "1. remove logrotate configuration file for sensorjs if it is not a symbolic link. - 1/3"
  rm -f ${SENSORJS_LOGROTATE_CONFIG_PATH}
fi
if [ ! -f ${SENSORJS_LOGROTATE_CONFIG_PATH} ]; then
  echo "1. link logrotate configuration file for sensorjs. - 2/3"
  ln -sf ${SENSORJS_LOGROTATE_CONFIG} ${SENSORJS_LOGROTATE_CONFIG_PATH}
fi
if [ ! -f ${CRON_HOURLY_PATH} ]; then
    echo "1. move logrotate from cron.daily to cron.hourly. - 3/3"
    mv -f ${CRON_DAILY_PATH} ${CRON_HOURLY_PATH}
fi
#remove old log files
rm -f /var/log/sensorjs/sensorjs.log
rm -f /var/log/sensorjs/sensorjs.log.*
rm -f /var/log/sensorjs/forever.log

##########################
## 2. reboot on kernel panic 
##########################
SYSCTL_CONFIG=$CUR_DIR/files/sysctl.conf
SYSCTL_CONFIG_PATH=/etc/sysctl.conf
#if [ -f ${SYSCTL_CONFIG_PATH} ] && [ ! -L ${SYSCTL_CONFIG_PATH} ]; then
#  rm -f ${SYSCTL_CONFIG_PATH}
#  ln -s ${SYSCTL_CONFIG} ${SYSCTL_CONFIG_PATH}
#fi
grep -e "^kernel.panic_on_oops" /etc/sysctl.conf > /dev/null
if [ $? = 1 ]; then #missing kernel.panic
  echo "2. sysctl.conf: kernel panic."
  cp -f ${SYSCTL_CONFIG} ${SYSCTL_CONFIG_PATH}
fi

##########################
## 3. install watchdog
##########################
DEB_WATCHDOG_PATH="$CUR_DIR/files/watchdog_5.12-1_armhf.deb"
WATCHDOG_CONFIG=$CUR_DIR/files/watchdog.conf
WATCHDOG_CONFIG_PATH=/etc/watchdog.conf
if [ ! -f /usr/sbin/watchdog ]; then
  echo "3. install watchdog 1/2"
  dpkg -i ${DEB_WATCHDOG_PATH} 
  if [ $? -gt 0 ]; then
    #FIXME: possible network error when invoked by init.d script
    apt-get -f --force-yes --yes install 
    dpkg -i ${DEB_WATCHDOG_PATH}
  fi
fi
#if [ -f ${WATCHDOG_CONFIG_PATH} ] && [ ! -L ${WATCHDOG_CONFIG_PATH} ]; then
#  rm -f ${WATCHDOG_CONFIG_PATH}
#  ln -s ${WATCHDOG_CONFIG} ${WATCHDOG_CONFIG_PATH}
#fi
grep -e "^watchdog-device" ${WATCHDOG_CONFIG_PATH} > /dev/null
if [ $? = 1 ]; then #uncomment watchdog device
  echo "3. install watchdog config 2/2"
  cp -f ${WATCHDOG_CONFIG} ${WATCHDOG_CONFIG_PATH}
fi

##########################
## 4. eth0 as allow-hotplug
##########################
NETWORK_CONFIG=$CUR_DIR/files/interfaces
NETWORK_CONFIG_PATH=/etc/network/interfaces
#if [ -f ${NETWORK_CONFIG_PATH} ] && [ ! -L ${NETWORK_CONFIG_PATH} ]; then
#  rm -f ${NETWORK_CONFIG_PATH}
#  ln -s ${NETWORK_CONFIG} ${NETWORK_CONFIG_PATH}
#fi
grep -e "^allow-hotplug eth0" ${NETWORK_CONFIG_PATH} > /dev/null
if [ $? = 1 ]; then #missing allow-hotplug
  echo "4. eth0 as allow-hotplug"
  cp -f ${NETWORK_CONFIG} ${NETWORK_CONFIG_PATH}
fi

##########################
## 5. tty
##########################
#TODO: The patch routine is required for the case when the dtbo files are upgraded.
if [ ! -f /lib/firmware/ttyO1_armhf.com-00A0.dtbo ]; then
  echo "5. uart config"
  cp $CUR_DIR/files/ttyO*.dtbo /lib/firmware
fi

##########################
## 6. update u-boot
##########################
/usr/bin/md5sum --status -c $CUR_DIR/files/uboot.v2013.07.md5 > /dev/null
if [ $? = 1 ]; then 
  echo "6. update u-boot"
  tar xvfpz $CUR_DIR/files/uboot.v2013.07.tgz -C /boot/uboot > /dev/null
fi

##########################


##########################
## 7. ppp to be default router
##########################
WVDIAL_PPP_CONFIG=$CUR_DIR/files/wvdial
WVDIAL_PPP_CONFIG_PATH=/etc/ppp/peers/wvdial
#if [ -f ${WVDIAL_PPP_CONFIG_PATH} ] && [ ! -L ${WVDIAL_PPP_CONFIG_PATH} ]; then
#  rm -f ${WVDIAL_PPP_CONFIG_PATH}
#  ln -s ${WVDIAL_PPP_CONFIG} ${WVDIAL_PPP_CONFIG_PATH}
#fi
grep -e "^defaultroute" ${WVDIAL_PPP_CONFIG_PATH} > /dev/null
if [ $? = 1 ]; then #missing defaultroute
  echo "7. ppp as default route"
  cp -f ${WVDIAL_PPP_CONFIG} ${WVDIAL_PPP_CONFIG_PATH}
fi


##########################
## 8. add healthcheck into cron to check the health of system such as valid time.
##########################
HEALTHCHECK_CRON_SCRIPT=../../scripts/cron/healthcheck
HEALTHCHECK_CRON_SCRIPT_LINK_PATH=/etc/cron.hourly/healthcheck
OLD_HEALTHCHECK_CRON_SCRIPT=/etc/cron.hourly/wvdial_start*
test -x ${OLD_HEALTHCHECK_CRON_SCRIPT} && rm ${OLD_HEALTHCHECK_CRON_SCRIPT}
if [ -x ${HEALTHCHECK_CRON_SCRIPT} ] && [ ! -L ${HEALTHCHECK_CRON_SCRIPT_LINK_PATH} ]; then
  echo "8. link healthcheck into cron"
  ln -sf ${HEALTHCHECK_CRON_SCRIPT} ${HEALTHCHECK_CRON_SCRIPT_LINK_PATH}
fi

##########################
## 9. update capemgr
##########################
CAPE=
if [ -f /etc/default/vendor ]; then
  . /etc/default/vendor 
fi

if [ -z "$CAPE" ]; then
  CAPEMGR_FILE="$CUR_DIR/files/capemgr"
else
  CAPEMGR_FILE="$CUR_DIR/files/capemgr_${CAPE}"
fi

if [ -f ${CAPEMGR_FILE}.md5 -a -f ${CAPEMGR_FILE}.tgz ]; then
  /usr/bin/md5sum --status -c ${CAPEMGR_FILE}.md5 > /dev/null
  if [ $? = 1 ]; then 
    echo "9. update capemgr"
    tar xvfpz ${CAPEMGR_FILE}.tgz -C / > /dev/null
    chkconfig capemgr.sh on #enabled deamon
  fi
fi

##########################
## 10. update dtbo and other board specifics
##########################
CAPE=
LED_ACTIVE_LOW=0
if [ -f /etc/default/vendor ]; then
  . /etc/default/vendor 
fi
if [ -f /etc/default/capemgr ]; then
  . /etc/default/capemgr 
fi

if [ -z "$CAPE" ]; then
  DTBO_FILE="$CUR_DIR/files/dtbo"
else
  DTBO_FILE="$CUR_DIR/files/dtbo_${CAPE}"
fi

if [ -f ${DTBO_FILE}.md5 -a -f ${DTBO_FILE}.tgz ]; then
  /usr/bin/md5sum --status -c ${DTBO_FILE}.md5 > /dev/null
  if [ $? = 1 ]; then 
    echo "10. update dtbo"
    tar xvfpz ${DTBO_FILE}.tgz -C /lib/firmware > /dev/null
  fi
fi

for pin in 66 68 69 ; do
  if [ ! -e "/sys/class/gpio/gpio$pin" ]; then
    log "enable gpio$pin"
    gpio-admin export "$pin"
    echo out > "/sys/class/gpio/gpio$pin/direction"
    echo "$LED_ACTIVE_LOW" > "/sys/class/gpio/gpio$pin/active_low"
  fi
done

echo "[patches.sh] done"
