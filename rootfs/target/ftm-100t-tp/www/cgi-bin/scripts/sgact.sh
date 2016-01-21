#!/bin/sh
`echo AT#SGACT=2,1 > /dev/ttyS1; sleep 0.1`
time=0
while [ 0 ]
do
	time=`expr $time + 1`
	if [ $time -eq 100 ]
	then
		break
	fi
done
/www/cgi-bin/scripts/nwcause.sh
