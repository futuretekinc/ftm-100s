#!/bin/sh
# get sensor node mac
snmpget -v 2c -c public $1 .1.3.6.1.4.1.42251.1.2.2.0 | awk '{ print $4 }'
