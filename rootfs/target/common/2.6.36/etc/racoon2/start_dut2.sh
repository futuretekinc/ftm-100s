
killall5

ifconfig eth1 192.168.2.1
ifconfig eth0 192.168.60.2
echo 1 > /proc/sys/net/ipv4/ip_forward
route add -net 192.168.1.0 netmask 255.255.255.0 gw 192.168.60.1
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
iptables -t nat -A POSTROUTING -o eth0 -s 192.168.2.0/24 -d 192.168.1.0/24 -j RETURN
iptables -t nat -A POSTROUTING -o eth0 -s 192.168.2.0/24 -j MASQUERADE

ifconfig eth1:0 192.168.3.1
ifconfig eth0:0 192.168.60.3
iptables -t nat -A POSTROUTING -o eth0 -s 192.168.3.0/24 -d 192.168.1.0/24 -j RETURN
iptables -t nat -A POSTROUTING -o eth0 -s 192.168.3.0/24 -j MASQUERADE

ifconfig eth1:1 192.168.4.1
ifconfig eth0:1 192.168.60.4
iptables -t nat -A POSTROUTING -o eth0 -s 192.168.4.0/24 -d 192.168.1.0/24 -j RETURN
iptables -t nat -A POSTROUTING -o eth0 -s 192.168.4.0/24 -j MASQUERADE

ifconfig eth1:2 192.168.5.1
ifconfig eth0:2 192.168.60.5
iptables -t nat -A POSTROUTING -o eth0 -s 192.168.5.0/24 -d 192.168.1.0/24 -j RETURN
iptables -t nat -A POSTROUTING -o eth0 -s 192.168.5.0/24 -j MASQUERADE

ifconfig eth1:3 192.168.6.1
ifconfig eth0:3 192.168.60.6
iptables -t nat -A POSTROUTING -o eth0 -s 192.168.6.0/24 -d 192.168.1.0/24 -j RETURN
iptables -t nat -A POSTROUTING -o eth0 -s 192.168.6.0/24 -j MASQUERADE

ifconfig eth1:4 192.168.7.1
ifconfig eth0:4 192.168.60.7
iptables -t nat -A POSTROUTING -o eth0 -s 192.168.7.0/24 -d 192.168.1.0/24 -j RETURN
iptables -t nat -A POSTROUTING -o eth0 -s 192.168.7.0/24 -j MASQUERADE

ifconfig eth1:5 192.168.8.1
ifconfig eth0:5 192.168.60.8
iptables -t nat -A POSTROUTING -o eth0 -s 192.168.8.0/24 -d 192.168.1.0/24 -j RETURN
iptables -t nat -A POSTROUTING -o eth0 -s 192.168.8.0/24 -j MASQUERADE

ifconfig eth1:6 192.168.9.1
ifconfig eth0:6 192.168.60.9
iptables -t nat -A POSTROUTING -o eth0 -s 192.168.9.0/24 -d 192.168.1.0/24 -j RETURN
iptables -t nat -A POSTROUTING -o eth0 -s 192.168.9.0/24 -j MASQUERADE

ifconfig eth1:7 192.168.10.1
ifconfig eth0:7 192.168.60.10
iptables -t nat -A POSTROUTING -o eth0 -s 192.168.10.0/24 -d 192.168.1.0/24 -j RETURN
iptables -t nat -A POSTROUTING -o eth0 -s 192.168.10.0/24 -j MASQUERADE

ifconfig eth1:8 192.168.11.1
ifconfig eth0:8 192.168.60.11
iptables -t nat -A POSTROUTING -o eth0 -s 192.168.11.0/24 -d 192.168.1.0/24 -j RETURN
iptables -t nat -A POSTROUTING -o eth0 -s 192.168.11.0/24 -j MASQUERADE

ifconfig eth1:9 192.168.12.1
ifconfig eth0:9 192.168.60.12
iptables -t nat -A POSTROUTING -o eth0 -s 192.168.12.0/24 -d 192.168.1.0/24 -j RETURN
iptables -t nat -A POSTROUTING -o eth0 -s 192.168.12.0/24 -j MASQUERADE

ifconfig eth1:10 192.168.13.1
ifconfig eth0:10 192.168.60.13
iptables -t nat -A POSTROUTING -o eth0 -s 192.168.13.0/24 -d 192.168.1.0/24 -j RETURN
iptables -t nat -A POSTROUTING -o eth0 -s 192.168.13.0/24 -j MASQUERADE

ifconfig eth1:11 192.168.14.1
ifconfig eth0:11 192.168.60.14
iptables -t nat -A POSTROUTING -o eth0 -s 192.168.14.0/24 -d 192.168.1.0/24 -j RETURN
iptables -t nat -A POSTROUTING -o eth0 -s 192.168.14.0/24 -j MASQUERADE

ifconfig eth1:12 192.168.15.1
ifconfig eth0:12 192.168.60.15
iptables -t nat -A POSTROUTING -o eth0 -s 192.168.15.0/24 -d 192.168.1.0/24 -j RETURN
iptables -t nat -A POSTROUTING -o eth0 -s 192.168.15.0/24 -j MASQUERADE

ifconfig eth1:13 192.168.16.1
ifconfig eth0:13 192.168.60.16
iptables -t nat -A POSTROUTING -o eth0 -s 192.168.16.0/24 -d 192.168.1.0/24 -j RETURN
iptables -t nat -A POSTROUTING -o eth0 -s 192.168.16.0/24 -j MASQUERADE

ifconfig eth1:14 192.168.17.1
ifconfig eth0:14 192.168.60.17
iptables -t nat -A POSTROUTING -o eth0 -s 192.168.17.0/24 -d 192.168.1.0/24 -j RETURN
iptables -t nat -A POSTROUTING -o eth0 -s 192.168.17.0/24 -j MASQUERADE

mkdir -p -m 700 /var/run/racoon2
chmod 600  /etc/racoon2/spmd.pwd
chmod 600  -R /etc/racoon2/psk
spmd -f /etc/racoon2/racoon2-dut2-ipv4-psk.conf


sleep 3
iked -f /etc/racoon2/racoon2-dut2-ipv4-psk.conf

