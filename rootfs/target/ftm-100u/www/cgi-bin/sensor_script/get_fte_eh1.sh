#!/bin/sh
# get IP
ip=`/www/cgi-bin/sensor_script/search_mac.sh $1`
#ip=`/www/cgi-bin/sensor_script/search_mac.sh $1`
echo $1

# search humidity
/www/cgi-bin/sensor_script/get_di_info.sh $ip | awk -f /www/cgi-bin/sensor_script/get_di_info.awk
/www/cgi-bin/sensor_script/get_do_info.sh $ip | awk -f /www/cgi-bin/sensor_script/get_do_info.awk
