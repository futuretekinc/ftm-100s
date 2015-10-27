#!/bin/sh

a=`ls /dev/ttyACM0`
if [ -n "$a" ]
then
	echo 'at$$state=1' > /dev/ttyACM0; sleep 0.1
fi

file="/var/log/modem"
if [ -f $file ]
then
	raw=`cat /var/log/modem | sed /^$/d | awk '/AT\#SGACT/{ print NR }' | awk 'END { print }'`
	if [ -n "$raw" ]
	then
		cnt=0
		while [ 0 ]
		do
			next_raw=`expr $raw + 2 + $cnt`
			result=`cat /var/log/modem | sed /^$/d | sed -n "$next_raw"p | awk '{ print $1 }'`
			if [ "$result" = "#NWCAUSE:" ]
			then
				#cmd=`cat /var/log/modem | sed /^$/d | sed -n "$next_raw"p'`
				echo "stop"
				break
			else
				cnt=`expr $cnt + 1`
				if [ $cnt -eq 5 ]
				then
					echo "yes"
					break
				fi
			fi
		done
	else
		echo done
	fi
else
	echo done
fi
