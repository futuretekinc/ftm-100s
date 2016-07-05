#!/bin/sh
file="/var/log/modem"
if [ -f $file ]
then
	raw=`cat /var/log/modem | sed /^$/d | awk '/at\+creg\?/{ print NR }' | awk 'END { print }'`
	if [ -n "$raw" ]
	then
		next_raw=`expr $raw + 1`
		result=`cat /var/log/modem | sed /^$/d | sed -n "$next_raw"p | awk '{ print $1 }'`
		#echo $result
		if [ "$result" = "+CREG:" ]
		then
			cmd=`cat /var/log/modem | sed /^$/d | sed -n "$next_raw"p'`
			echo $cmd
		elif [ "$result" = "+CME" ]
		then
			cmd=`cat /var/log/modem | sed /^$/d | sed -n "$next_raw"p'`
			echo $cmd
		else 
			echo "URC MESSAGE"
		fi
	fi
fi