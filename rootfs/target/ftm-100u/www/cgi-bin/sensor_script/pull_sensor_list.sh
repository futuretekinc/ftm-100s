#!/bin/sh
sqlite3 /opt/sensor.db<< EOF
INSERT INTO sensor_list (node_id, sensor_id, type, name, oid) VALUES ('$1', '$2', '$3', '$4', '$5');
EOF
