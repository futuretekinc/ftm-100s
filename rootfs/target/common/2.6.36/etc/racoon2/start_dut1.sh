
killall5
ifconfig eth1 hw ether 00:50:c2:01:22:33
ifconfig eth1 192.168.1.1
ifconfig eth0 hw ether 00:50:c2:01:88:99
ifconfig eth0 192.168.60.1


echo 1 > /proc/sys/net/ipv4/ip_forward
route add -net 192.168.2.0 netmask 255.255.255.0 gw 192.168.60.2
route add -net 192.168.3.0 netmask 255.255.255.0 gw 192.168.60.3
route add -net 192.168.4.0 netmask 255.255.255.0 gw 192.168.60.4
route add -net 192.168.5.0 netmask 255.255.255.0 gw 192.168.60.5
route add -net 192.168.6.0 netmask 255.255.255.0 gw 192.168.60.6
route add -net 192.168.7.0 netmask 255.255.255.0 gw 192.168.60.7
route add -net 192.168.8.0 netmask 255.255.255.0 gw 192.168.60.8
route add -net 192.168.9.0 netmask 255.255.255.0 gw 192.168.60.9
route add -net 192.168.10.0 netmask 255.255.255.0 gw 192.168.60.10
route add -net 192.168.11.0 netmask 255.255.255.0 gw 192.168.60.11
route add -net 192.168.12.0 netmask 255.255.255.0 gw 192.168.60.12
route add -net 192.168.13.0 netmask 255.255.255.0 gw 192.168.60.13
route add -net 192.168.14.0 netmask 255.255.255.0 gw 192.168.60.14
route add -net 192.168.15.0 netmask 255.255.255.0 gw 192.168.60.15
route add -net 192.168.16.0 netmask 255.255.255.0 gw 192.168.60.16
route add -net 192.168.17.0 netmask 255.255.255.0 gw 192.168.60.17
echo "Stopping all of iptables for IPSec..."
iptables -F
iptables -X
iptables -Z
iptables -F -t nat
iptables -X -t nat
iptables -Z -t nat
iptables -F -t mangle
iptables -X -t mangle
iptables -Z -t mangle
iptables -F -t filter
iptables -X -t filter
iptables -Z -t filter
iptables -F -t raw
iptables -X -t raw
iptables -Z -t raw
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
iptables -t nat -P PREROUTING ACCEPT
iptables -t nat -P POSTROUTING ACCEPT
iptables -t nat -P OUTPUT ACCEPT
iptables -t nat -A POSTROUTING -o eth0 -s 192.168.1.0/24 -d 192.168.2.0/24 -j RETURN
iptables -t nat -A POSTROUTING -o eth0 -s 192.168.1.0/24 -j MASQUERADE
iptables -t nat -A POSTROUTING -o eth0 -s 192.168.1.0/24 -d 192.168.3.0/24 -j RETURN
iptables -t nat -A POSTROUTING -o eth0 -s 192.168.1.0/24 -d 192.168.4.0/24 -j RETURN
iptables -t nat -A POSTROUTING -o eth0 -s 192.168.1.0/24 -d 192.168.5.0/24 -j RETURN
iptables -t nat -A POSTROUTING -o eth0 -s 192.168.1.0/24 -d 192.168.6.0/24 -j RETURN
iptables -t nat -A POSTROUTING -o eth0 -s 192.168.1.0/24 -d 192.168.7.0/24 -j RETURN
iptables -t nat -A POSTROUTING -o eth0 -s 192.168.1.0/24 -d 192.168.8.0/24 -j RETURN
iptables -t nat -A POSTROUTING -o eth0 -s 192.168.1.0/24 -d 192.168.9.0/24 -j RETURN
iptables -t nat -A POSTROUTING -o eth0 -s 192.168.1.0/24 -d 192.168.10.0/24 -j RETURN
iptables -t nat -A POSTROUTING -o eth0 -s 192.168.1.0/24 -d 192.168.11.0/24 -j RETURN
iptables -t nat -A POSTROUTING -o eth0 -s 192.168.1.0/24 -d 192.168.12.0/24 -j RETURN
iptables -t nat -A POSTROUTING -o eth0 -s 192.168.1.0/24 -d 192.168.13.0/24 -j RETURN
iptables -t nat -A POSTROUTING -o eth0 -s 192.168.1.0/24 -d 192.168.14.0/24 -j RETURN
iptables -t nat -A POSTROUTING -o eth0 -s 192.168.1.0/24 -d 192.168.15.0/24 -j RETURN
iptables -t nat -A POSTROUTING -o eth0 -s 192.168.1.0/24 -d 192.168.16.0/24 -j RETURN
iptables -t nat -A POSTROUTING -o eth0 -s 192.168.1.0/24 -d 192.168.17.0/24 -j RETURN
mkdir -p -m 700 /var/run/racoon2
chmod 600  /etc/racoon2/spmd.pwd
chmod 600  -R /etc/racoon2/psk
spmd -f /etc/racoon2/racoon2-dut1-ipv4-psk.conf


sleep 3
iked -f /etc/racoon2/racoon2-dut1-ipv4-psk.conf

