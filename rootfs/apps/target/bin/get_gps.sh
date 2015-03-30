#!/bin/sh

a=`ls /dev/ttyACM0`
if [ -n "$a" ]
then
	echo 'at@gps=pos' > /dev/ttyACM0; sleep 0.1
fi

file="/var/log/modem"
if [ -f $file ]
then
	raw=`cat /var/log/modem | sed /^$/d | awk '/at@gps=pos/{ print NR }' | awk 'END { print }'`
	if [ -n "$raw" ]
	then
		next_raw=`expr $raw + 1`
		result=`cat /var/log/modem | sed /^$/d | sed -n "$next_raw"p | awk '{ split($0,arr,":"); printf("%s", arr[1]); }'`
		text=`cat /var/log/modem | sed /^$/d | sed -n "$next_raw"p | awk '{ split($0,arr,":"); printf("%s", arr[2]); }'`
		#echo $result
		#echo $text
		if [ "$result" = "@GPS" ]
		then
			#cmd=`cat /var/log/modem | sed /^$/d | sed -n "$next_raw"p'`
			gps=`echo $text | awk '{ split($0,arr,","); printf("%s, %s\n", arr[1], arr[2]); }'`
			date=`date '+%F %r'`
			echo {$date} {$gps}
		fi
	fi
else
	echo done
fi

