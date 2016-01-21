#!/bin/sh

apikey=`cat /opt/config/runtime.json | awk '/APIKEY/{ print $2 }'`

if [ "$apikey" = "" ]
then
	echo done
else
	echo $apikey
fi
