#!/bin/sh
# broadcast
#ping -c5 192.168.1.255 > /dev/null
#ping -c 5 -b 10.0.1.255 > /dev/null

# get IP
ip=`arp-scan -l | awk '/'$1'/ { print $1 }'`
#ip=`/www/cgi-bin/sensor_script/search_mac.sh $1`
#ip=`/www/cgi-bin/sensor_script/search_mac.sh $1`
#echo $1

# search humidity
/www/cgi-bin/sensor_script/get_humidity_info.sh $ip | awk -f /www/cgi-bin/sensor_script/get_humidity_info.awk
/www/cgi-bin/sensor_script/get_temperature_info.sh $ip | awk -f /www/cgi-bin/sensor_script/get_temperature_info.awk
/www/cgi-bin/sensor_script/get_di_info.sh $ip | awk -f /www/cgi-bin/sensor_script/get_di_info.awk
