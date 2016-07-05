#!/bin/sh

#password_str="futuretek_01"
#echo -n "$password_str" | openssl aes-256-cbc -d -in /tmp/config.dat -out /tmp/config.tar.gz -pass stdin
#rm /tmp/config.dat

tar xzvpf /tmp/config.tar.gz -C /tmp/
cp -rf /tmp/overlay/etc/* /etc/
#rm /etc/*
#cp -fP /tmp/etc/* /etc/

rm -r /tmp/overlay
rm /tmp/config.tar.gz
