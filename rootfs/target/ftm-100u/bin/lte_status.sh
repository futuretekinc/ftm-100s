#!/bin/sh

value=`ping 8.8.8.8 -w 3 | awk '/packet loss/ { print $7 }'`

if [ $value = "0%" ]
then
	echo Service..
else
	echo No Service..
	reboot
fi
