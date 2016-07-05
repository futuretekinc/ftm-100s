#!/bin/sh
sqlite3 /opt/sensor.db<< EOF
select node_id, sensor_id, type, name, favorite from sensor_list;
EOF
