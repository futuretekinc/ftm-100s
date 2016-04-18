#!/bin/sh

value=`/opt/thingplus.sh status`

if [ $value = "stopped" ]
then
	`echo stop > /var/thingplus_status`
	/opt/thingplus.sh start
else
	`echo running > /var/thingplus_status`
fi
