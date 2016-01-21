#!/bin/sh

modem_state=`/www/cgi-bin/scripts/modem_state.sh`

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
		if [ "$modem_state" == "LTE" ]
		then
			next_raw=`expr $raw + 30`
			end_raw=`expr $next_raw + 22`
		else
			next_raw=`expr $raw + 1`
			end_raw=`expr $next_raw + 28`
		fi
#		next_raw=`expr $raw + 1`
#		end_raw=`expr $next_raw + 51`
		#echo $next_raw $end_raw
		result=`cat /var/log/modem | sed /^$/d | sed 's/$/,/g' | sed -n "$next_raw","$end_raw"p`
#		echo $result

		test_raw=`expr $raw + 3`
		test_raw2=`expr $raw + 4`
		result2=`cat /var/log/modem | sed /^$/d | sed 's/$/,/g' | sed -n "$test_raw"p`
		echo $result $result2
	else
		echo done
	fi
else
	echo done
fi