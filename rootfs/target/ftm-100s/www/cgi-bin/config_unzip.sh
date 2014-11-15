#!/bin/sh

#password_str="futuretek_01"
#echo -n "$password_str" | openssl aes-256-cbc -d -in /tmp/config.dat -out /tmp/config.tar.gz -pass stdin
#rm /tmp/config.dat

tar xzvpf /tmp/config.tar.gz -C /tmp/
rm /etc/*
cp -fP /tmp/etc/* /etc/

#cp -fP /tmp/etc/httpd.conf /etc/httpd.conf
#cp -fP /tmp/etc/passwd /etc/passwd
#cp -fP /tmp/etc/resolv.conf /etc/resolv.conf
#cp -fP /tmp/etc/udhcpd.conf /etc/udhcpd.conf
#cp -fP /tmp/etc/network/interfaces /etc/network/interfaces
#cp -fP /tmp/etc/service/iptables /etc/service/iptables
#cp -fP /tmp/etc/service/pppd /etc/service/pppd
#cp -fP /tmp/etc/service/secuwayssl /etc/service/secuwayssl
#cp -fP /tmp/etc/service/ssld /etc/service/ssld
#cp -fP /tmp/etc/service/syslogd /etc/service/syslogd
#cp -fP /tmp/etc/service/udhcpd /etc/service/udhcpd
#cp -fP /tmp/etc/service/vsftpd /etc/service/vsftpd

rm -r /tmp/etc
rm /tmp/config.tar.gz
