#!/bin/sh
sqlite3 /opt/sensor.db<< EOF
select count(*) from sensor_data;
EOF
