#!/bin/sh

a=`ls /dev/ttyACM0`
if [ -n "$a" ]
then
	echo 'at+cimi' > /dev/ttyACM0; sleep 0.1
fi

file="/var/log/modem"
if [ -f $file ]
then
	raw=`cat /var/log/modem | sed /^$/d | awk '/at\+cimi/{ print NR }' | awk 'END { print }'`
	if [ -n "$raw" ]
	then
		next_raw=`expr $raw + 1`
		result=`cat /var/log/modem | sed /^$/d | sed -n "$next_raw"p`
		#echo "$result"
		if [ "$result" = "" ]
                then
                        echo done
                else
                        echo $result
                fi
	else
		echo done
	fi
else
	echo done
fi