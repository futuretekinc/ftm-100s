#!/bin/sh
/www/cgi-bin/sensor_script/get_humidity_info.sh $1 | awk -f /www/cgi-bin/sensor_script/get_humidity_info.awk
