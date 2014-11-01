#!/bin/sh
####################################################################################
# ip config 
#                                 Tunnel Mode Architecture
#
#      PC1 <-------------> VPNROUTER1 <========> VPNROUTER2 <-------------> PC2
#                      eth0       eth1         eth1       eth0
# 192.168.1.2    192.168.1.1 192.168.60.1  192.168.60.2  192.168.2.1   192.168.2.2
#####################################################################################
echo 1 > /proc/sys/net/ipv6/conf/all/forwarding
##NAT setup
#iptables -F -t nat
#iptables -X -t nat
#iptables -Z -t nat
#iptables -t nat -P PREROUTING  ACCEPT
#iptables -t nat -P POSTROUTING ACCEPT
#iptables -t nat -P OUTPUT      ACCEPT
###iptables -t nat -A POSTROUTING -o eth1  -s 192.168.1.0/24 -j MASQUERADE

mkdir -p -m 700 /var/run/racoon2
chmod 600  /etc/racoon2/spmd.pwd
chmod 400 -R /etc/racoon2/cert
spmd -f /etc/racoon2/racoon2-dut1-ipv6-x509.conf     
sleep 3
iked -f /etc/racoon2/racoon2-dut1-ipv6-x509.conf -ddd -F
