#!/bin/sh
mmd_pid=`pidof mmd`
if [ -z "$mmd_pid" ]
then
	$1
else
	echo "error"
fi
