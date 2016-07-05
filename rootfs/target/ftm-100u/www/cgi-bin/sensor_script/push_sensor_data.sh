#!/bin/sh
# 값이 안넘어 오면 리턴시켜야함.

sqlite3 /opt/sensor.db<< EOF
INSERT INTO sensor_data (node_id, sensor_id, type, name, sn, state, value, last_value, last_time, interval) VALUES ('$1', '$2', '$3', '$4', '$5', '$6', '$7', '$8', '$9', '$10');
EOF
