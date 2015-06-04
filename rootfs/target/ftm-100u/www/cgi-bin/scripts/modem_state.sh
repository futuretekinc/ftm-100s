#!/bin/sh

a=`ls /dev/ttyACM0`
if [ -n "$a" ]
then
	echo 'at*antlvl?' > /dev/ttyACM0; sleep 0.1
fi

file="/var/log/modem"
if [ -f $file ]
then
	raw=`cat /var/log/modem | sed /^$/d | awk '/at\*antlvl\?/{ print NR }' | awk 'END { print }'`
	if [ -n "$raw" ]
	then
		next_raw=`expr $raw + 1`
		result=`cat /var/log/modem | sed /^$/d | sed -n "$next_raw"p | awk '{ split($0,arr,":"); printf("%s", arr[2]); }'`
		echo $result | awk '{ split($0,arr,","); printf("%s\n", arr[2]);}'
	else
		echo done
	fi
else
	echo done
fi
