#!/bin/sh

is_ppp_connected()
{
    retval=`/bin/cat /proc/net/dev |  awk 'BEGIN{ retval="false" }\
    	{\
        if ($1 ~ /^ppp0/)\
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
	initRx=`cat /etc/ppp/data/initData | awk '{ print $1 }'`
	initTx=`cat /etc/ppp/data/initData | awk '{ print $2 }'`
	currentRx=`cat /etc/ppp/data/curData | awk '{ print $1 }'`
	currentTx=`cat /etc/ppp/data/curData | awk '{ print $2 }'`
	sumRx=`expr $initRx + $currentRx`
	sumTx=`expr $initTx + $currentTx`
	`echo $sumRx $sumTx > /etc/ppp/data/initData`
}

is_ppp_connected
if [ $? -eq 0 ]
then
	initRx=`cat /etc/ppp/data/initData | awk '{ print $1 }'`
	initTx=`cat /etc/ppp/data/initData | awk '{ print $2 }'`
	currentRx=`cat /etc/ppp/data/curData | awk '{ print $1 }'`
	currentTx=`cat /etc/ppp/data/curData | awk '{ print $2 }'`
	sumRx=`expr $initRx + $currentRx`
	sumTx=`expr $initTx + $currentTx`
	echo "$sumRx" "$sumTx"
else
	initData=`cat /etc/ppp/data/initData | awk '{ print $1, $2 }'`
	echo "$initData"
fi
