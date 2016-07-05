#!/bin/sh
sqlite3 /opt/sensor.db<< EOF
INSERT INTO sensor (node_id, sensor_id, type, sn, state, value, last_value, last_time, interval) VALUES ('$1', '$2', '$3', '$4', '$5', '$6', '$7', '$8', '$9');
EOF
