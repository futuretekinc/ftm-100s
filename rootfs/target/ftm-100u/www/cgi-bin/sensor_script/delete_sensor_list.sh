#!/bin/sh
sqlite3 /opt/sensor.db<< EOF
delete from sensor_list where node_id='$1' and sensor_id='$2';
EOF
