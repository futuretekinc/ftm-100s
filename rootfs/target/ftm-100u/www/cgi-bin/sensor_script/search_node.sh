#!/bin/sh
# get IP
#ip=`/www/cgi-bin/sensor_script/search_mac.sh $1`
ip=`/www/cgi-bin/sensor_script/search_mac.sh $1`
#echo $ip

if [ -z "$ip" ]
then
    echo "no ip"
else
    model=`snmpget -v 2c -c public $ip .1.3.6.1.4.1.42251.1.1.2.0 | awk '$1~/^iso.3.6.1.4.1.42251.1.1.2.0/ { print $4 }'`
    echo $model

    if [ $model = '"FTE-EH1"' ]
    then
        /www/cgi-bin/sensor_script/get_fte_eh1.sh $ip
    elif [ $model = '"FTE-ES7"' ]
    then
        /www/cgi-bin/sensor_script/get_fte_es7.sh $ip
    fi
fi
