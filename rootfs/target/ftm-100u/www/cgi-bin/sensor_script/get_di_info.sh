#!/bin/sh
# get humidity sensors info
# get sensor count
snmpget -v 2c -c public $1 .1.3.6.1.4.1.42251.1.3.1280.1.0 | awk '{ print "count", $4 }'
# get sensor mac-address
snmpget -v 2c -c public $1 .1.3.6.1.4.1.42251.1.2.2.0 | awk '{ print "mac", $4 }'
snmpwalk -v 2c -c public $1 .1.3.6.1.4.1.42251.1.3.1280.2.1
