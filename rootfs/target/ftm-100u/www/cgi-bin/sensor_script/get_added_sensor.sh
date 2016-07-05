#!/bin/sh
sqlite3 /opt/sensor.db<< EOF
select id from sensor_list where sensor_id='$2' and node_id='$1';
EOF
