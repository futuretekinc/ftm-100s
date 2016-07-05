#!/bin/sh

#current_time=`date +%s`
#pre_time=`expr $current_time - 60`
#echo $pre_time, $current_time

sqlite3 /opt/sensor.db<< EOF
select * from sensor_data where node_id='$1' and sensor_id='$2' order by id desc limit 10;
EOF
