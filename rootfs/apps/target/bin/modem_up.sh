#!/bin/sh

count=0

while [ 0 ]
do
        is_usb0=`/bin/status_network.sh`
        echo "$is_usb0"
        if [ -n "$is_usb0" ]
        then
                #stty -F /dev/ttyACM0 -echo
                #cat /dev/ttyACM0 &> /var/log/modem &
                #`echo 'at*rndisdata=1' > /dev/ttyACM0`
                #break

                echo 'at*rndisdata?' > /dev/ttyACM0; sleep 0.1
                file="/var/log/modem"
                if [ -f $file ]
                then
                        raw=`cat /var/log/modem | sed /^$/d | awk '/\*rndisdata:0/{ print NR }' | awk 'END { print }'`
                        if [ -n "$raw" ]
                        then
				count=`expr $count + 1`
				echo 'at$$cfun=1' > /dev/ttyACM0; sleep 0.1
				echo 'at*rndisdata=1' > /dev/ttyACM0; sleep 0.1

				if [ "$count" -gt 5 ]
				then
					break
				fi
                                #next_raw=`expr $raw + 1`
                                #result=`cat /var/log/modem | sed /^$/d | sed -n "$next_raw"p | awk '{ print $1 }'`
                                #echo "$result"
                                #if [ "$result" = "OK" ]
                                #then
                                #        break
                                #fi
                        fi
                fi

        else
                echo "no up usb0" 
        fi

        sleep 2 
done
