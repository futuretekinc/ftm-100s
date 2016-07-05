#!/bin/sh

# get IP
ip=`/www/cgi-bin/sensor_script/search_mac.sh $1`

/www/cgi-bin/sensor_script/get_humidity_info.sh $ip | awk -f /www/cgi-bin/sensor_script/get_humidity_info.awk
/www/cgi-bin/sensor_script/get_temperature_info.sh $ip | awk -f /www/cgi-bin/sensor_script/get_temperature_info.awk
/www/cgi-bin/sensor_script/get_di_info.sh $ip | awk -f /www/cgi-bin/sensor_script/get_di_info.awk
/www/cgi-bin/sensor_script/get_do_info.sh $ip | awk -f /www/cgi-bin/sensor_script/get_do_info.awk
