#!/bin/sh
initRx=`cat /etc/initData | awk '{ print $1 }'`
initTx=`cat /etc/initData | awk '{ print $2 }'`
currentRx=`cat /var/curData | awk '{ print $1 }'`
currentTx=`cat /var/curData | awk '{ print $2 }'`
sumRx=`expr $initRx + $currentRx`
sumTx=`expr $initTx + $currentTx`
`echo $sumRx $sumTx > /etc/initData`

echo 'at$$cfun=3' > /dev/ttyACM0; sleep 0.1
sleep 1
echo 'at$$cfun=1'> /dev/ttyACM0; sleep 0.1



file="/var/log/modem"
a=`ls /dev/ttyACM0`

while [ 0 ]
do
	if [ -n "$a" ]                                     
	then                                               
	        echo 'at*regsts?' > /dev/ttyACM0; sleep 0.1
	fi

	if [ -f $file ]
	then
   	     	raw=`cat /var/log/modem | sed /^$/d | awk '/at\*regsts\?/{ print NR }' | awk 'END { print }'`
       	     	if [ -n "$raw" ]
       	     	then
        		next_raw=`expr $raw + 1`
			result=`cat /var/log/modem | sed /^$/d | sed -n "$next_raw"p | awk '{ split($0,arr,":"); printf("%s", arr[2]); }'`
			echo "$result"
		   	if [ "$result" = "1" ]
                   	then
				sleep 10
                        	echo 'at*rndisdata=1' > /dev/ttyACM0; sleep 0.1
				break
                   	fi
             	fi
	fi
	
	sleep 1
done
