#!/bin/sh
####################################################################################
# ip config 
#                                 Tunnel Mode Architecture
#
#      PC1 <-------------> DUT1 <========> DUT2 <-------------> PC2
#                      eth0       eth1         eth1       eth0
# 192.168.1.2    192.168.1.1 192.168.60.1  192.168.60.2  192.168.2.1   192.168.2.2                                        
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

####iptables -t nat -A POSTROUTING -o eth1  -s 192.168.2.0/24 -j MASQUERADE

mkdir -p -m 700 /var/run/racoon2
chmod 600  /etc/racoon2/spmd.pwd
chmod 400 -R /etc/racoon2/cert
spmd -f /etc/racoon2/racoon2-dut2-ipv4-x509.conf     
sleep 3
iked -f /etc/racoon2/racoon2-dut2-ipv4-x509.conf -ddd -F
