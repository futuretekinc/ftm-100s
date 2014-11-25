#!/bin/sh

a=`ls /dev/ttyACM0`
if [ -n "$a" ]
then
	`echo 'at$$dbs' > /dev/ttyACM0; sleep 0.1`
fi

file="/var/log/modem"
if [ -f $file ]
then
	raw=`cat /var/log/modem | sed /^$/d | awk '/\\$\\$DBS:/{ print NR }' | awk 'END { print }'`
	#echo $raw
	if [ -n "$raw" ]
	then
		next_raw=`expr $raw + 1`
		end_raw=`expr $next_raw + 51`
		#echo $next_raw $end_raw
		result=`cat /var/log/modem | sed /^$/d | sed 's/$/,/g' | sed -n "$next_raw","$end_raw"p`
		echo $result
	else
		echo done
	fi
else
	echo done
fi