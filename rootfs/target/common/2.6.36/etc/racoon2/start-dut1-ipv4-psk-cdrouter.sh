#!/bin/sh
####################################################################################
# ip config 
#                                 Tunnel Mode Architecture
#
#      PC1 <-------------> DUT1 <=================> CDRouter   <-------------> PC2(emulated by cdrouter)
#                      eth0       eth1              eth1        eth0
# 192.168.1.10    192.168.1.1 220.168.1.1       220.168.1.254   5.0.0.1       5.0.0.2
#####################################################################################

echo 1 > /proc/sys/net/ipv4/ip_forward
echo "Stopping all of iptables for IPSec..."
iptables -F
iptables -X
iptables -F -t nat
iptables -X -t nat
iptables -F -t mangle
iptables -X -t mangle
iptables -F -t filter
iptables -X -t filter
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

####iptables -t nat -A POSTROUTING -o eth1  -s 192.168.1.0/24 -j MASQUERADE

mkdir -p -m 700 /var/run/racoon2
chmod 600  /etc/racoon2/spmd.pwd
chmod 600  -R /etc/racoon2/psk
spmd -f /etc/racoon2/racoon2-dut1-ipv4-psk-cdrouter.conf     
sleep 3
iked -f /etc/racoon2/racoon2-dut1-ipv4-psk-cdrouter.conf -F -ddd
