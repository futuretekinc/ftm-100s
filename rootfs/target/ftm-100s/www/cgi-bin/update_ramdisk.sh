#!/bin/sh
/bin/fwmng -i /tmp/new_fw -o /dev/mtdblock5 -v -V -U >& /tmp/fwmng.txt
result=`cat /tmp/fwmng.txt | awk 'END { print }' | awk '/success/'` 
if [ -n "$result" ]
then
	rm /tmp/fwmng.txt
	echo "done"
else
	rm /tmp/fwmng.txt
#	echo "fail"
	`echo fail > /tmp/fwmng_fail`
	/www/cgi-bin/update_ramdisk.sh
fi
