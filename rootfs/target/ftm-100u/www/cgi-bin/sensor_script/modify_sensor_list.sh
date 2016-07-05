#!/bin/sh
# 값이 안넘어 오면 리턴시켜야함.

sqlite3 /opt/sensor.db<< EOF
update sensor_list set favorite='$3' where node_id='$1' and sensor_id='$2';
EOF
