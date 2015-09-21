#!/bin/sh
wc -l /var/log/messages | awk '{print $1}'
