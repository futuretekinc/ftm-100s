#!/bin/sh

is_ppp_connected()
{
    retval=`/bin/cat /proc/net/dev |  awk 'BEGIN{ retval="false" }\
    	{\
        if ($1 ~ /^usb0/)\
            {\
                retval="true"\
            }\
        }END{ print retval }'`

    if [ "$retval" = "true" ]
    then
        return  0
    else
        return  1
    fi
}

sum()
{
	initRx=`cat /etc/initData | awk '{ print $1 }'`
	initTx=`cat /etc/initData | awk '{ print $2 }'`
	currentRx=`cat /var/curData | awk '{ print $1 }'`
	currentTx=`cat /var/curData | awk '{ print $2 }'`
	sumRx=`expr $initRx + $currentRx`
	sumTx=`expr $initTx + $currentTx`
	`echo $sumRx $sumTx > /etc/initData`
}

is_ppp_connected
if [ $? -eq 0 ]
then
	initRx=`cat /etc/initData | awk '{ print $1 }'`
	initTx=`cat /etc/initData | awk '{ print $2 }'`
	currentRx=`cat /var/curData | awk '{ print $1 }'`
	currentTx=`cat /var/curData | awk '{ print $2 }'`
	sumRx=`expr $initRx + $currentRx`
	sumTx=`expr $initTx + $currentTx`
	echo "$sumRx" "$sumTx"
else
	initData=`cat /etc/initData | awk '{ print $1, $2 }'`
	echo "$initData"
fi
