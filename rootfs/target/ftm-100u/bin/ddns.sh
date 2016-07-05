#!/bin/sh

rdate -s 203.248.240.140 && hwclock -w

echo "nameserver 183.99.73.67" > /etc/resolv.conf

IMSI=`/www/cgi-bin/scripts/imsi.sh`
WANIP=`/www/cgi-bin/scripts/modem_ip.sh`

echo "server 183.99.73.67" > /etc/ddns/nsupdate.script
echo "debug yes" >> /etc/ddns/nsupdate.script
echo "zone uplus.co.kr." >> /etc/ddns/nsupdate.script
echo "update delete $IMSI.uplus.co.kr" >> /etc/ddns/nsupdate.script
echo "update add $IMSI.uplus.co.kr 60 A $WANIP" >> /etc/ddns/nsupdate.script
echo "show" >> /etc/ddns/nsupdate.script
echo "send" >> /etc/ddns/nsupdate.script

sleep 5

nsupdate -k /etc/ddns/Kuplus.co.kr.+157+18044.key -v /etc/ddns/nsupdate.script

`echo 'at$lgtdmzset' > /dev/ttyACM0`
