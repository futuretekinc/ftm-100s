#!/bin/sh

if [ -e /var/log/messages ]
then
	total=`wc -l /var/log/messages | awk '{print $1}'`
	
	if [ $(($1+$2)) -le $total ]
	then
		start_index=$(($total - $1 - $2));
		count=$2;
	else
		if [ $1 -le $total ]
		then
			count=$(($total - $1));
			start_index=0;
		else
			count=0;
			start_index=0;
		fi
	fi	

	tail -n "+$start_index" /var/log/messages | head -n "$count" | sed -e 's/</\&gt;/g' -e 's/>/\&lt;/g' -e 's/\&/\&amp;/g' -e "s/'/\&apos;/g" -e 's/\"/\&quot;/g'
fi
