#!/bin/sh

initRx=`cat /etc/initData | awk '{ print $1 }'`
initTx=`cat /etc/initData | awk '{ print $2 }'`
currentRx=`cat /var/curData | awk '{ print $1 }'`
currentTx=`cat /var/curData | awk '{ print $2 }'`
sumRx=`expr $initRx + $currentRx`
sumTx=`expr $initTx + $currentTx`
`echo $sumRx $sumTx > /etc/initData`

`echo 'at$$cfun=3' > /dev/ttyACM0; sleep 0.1`
rm -rf /overlay/*
sleep 2
sync
reboot
