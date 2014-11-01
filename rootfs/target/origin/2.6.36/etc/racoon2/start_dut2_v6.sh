
killall5
sysctl -w net.ipv6.conf.eth0.accept_dad=0
sysctl -w net.ipv6.conf.eth2.accept_dad=0
echo 1 > /proc/sys/net/ipv6/conf/all/forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward

ifconfig eth0 192.168.2.1
ifconfig eth2 192.168.60.2

ifconfig eth1 down 
ip -6 addr add 2001:0db8:0:4::1/64 dev eth0
ip -6 addr add 2001:0db8:0:1::4/64 dev eth2
route add -net 192.168.1.0 netmask 255.255.255.0 gw 192.168.60.1
route -A inet6 add 2001:db8:0:3::1/64 gw 2001:db8:0:1::3

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
iptables -t nat -A POSTROUTING -o eth2 -s 192.168.2.0/24 -d 192.168.1.0/24 -j RETURN
iptables -t nat -A POSTROUTING -o eth2 -s 192.168.2.0/24 -j MASQUERADE


ip6tables -F
ip6tables -X
ip6tables -Z
ip6tables -F -t mangle
ip6tables -X -t mangle
ip6tables -Z -t mangle
ip6tables -F -t filter
ip6tables -X -t filter
ip6tables -Z -t filter
ip6tables -F -t raw
ip6tables -X -t raw
ip6tables -Z -t raw
ip6tables -P INPUT ACCEPT
ip6tables -P FORWARD ACCEPT
ip6tables -P OUTPUT ACCEPT


ifconfig eth0:0 192.168.3.1
ifconfig eth2:0 192.168.60.3
route add -net 192.168.20.0 netmask 255.255.255.0 gw 192.168.60.20
iptables -t nat -A POSTROUTING -o eth2 -s 192.168.3.0/24 -d 192.168.20.0/24 -j RETURN
iptables -t nat -A POSTROUTING -o eth2 -s 192.168.3.0/24 -j MASQUERADE

ifconfig eth0:1 192.168.4.1
ifconfig eth2:1 192.168.60.4
route add -net 192.168.21.0 netmask 255.255.255.0 gw 192.168.60.21
iptables -t nat -A POSTROUTING -o eth2 -s 192.168.4.0/24 -d 192.168.21.0/24 -j RETURN
iptables -t nat -A POSTROUTING -o eth2 -s 192.168.4.0/24 -j MASQUERADE

ifconfig eth0:2 192.168.5.1
ifconfig eth2:2 192.168.60.5
route add -net 192.168.22.0 netmask 255.255.255.0 gw 192.168.60.22
iptables -t nat -A POSTROUTING -o eth2 -s 192.168.5.0/24 -d 192.168.22.0/24 -j RETURN
iptables -t nat -A POSTROUTING -o eth2 -s 192.168.5.0/24 -j MASQUERADE

ifconfig eth0:3 192.168.6.1
ifconfig eth2:3 192.168.60.6
route add -net 192.168.23.0 netmask 255.255.255.0 gw 192.168.60.23
iptables -t nat -A POSTROUTING -o eth2 -s 192.168.6.0/24 -d 192.168.23.0/24 -j RETURN
iptables -t nat -A POSTROUTING -o eth2 -s 192.168.6.0/24 -j MASQUERADE

ifconfig eth0:4 192.168.7.1
ifconfig eth2:4 192.168.60.7
route add -net 192.168.24.0 netmask 255.255.255.0 gw 192.168.60.24
iptables -t nat -A POSTROUTING -o eth2 -s 192.168.7.0/24 -d 192.168.24.0/24 -j RETURN
iptables -t nat -A POSTROUTING -o eth2 -s 192.168.7.0/24 -j MASQUERADE

ifconfig eth0:5 192.168.8.1
ifconfig eth2:5 192.168.60.8
route add -net 192.168.25.0 netmask 255.255.255.0 gw 192.168.60.25
iptables -t nat -A POSTROUTING -o eth2 -s 192.168.8.0/24 -d 192.168.25.0/24 -j RETURN
iptables -t nat -A POSTROUTING -o eth2 -s 192.168.8.0/24 -j MASQUERADE

ifconfig eth0:6 192.168.9.1
ifconfig eth2:6 192.168.60.9
route add -net 192.168.26.0 netmask 255.255.255.0 gw 192.168.60.26
iptables -t nat -A POSTROUTING -o eth2 -s 192.168.9.0/24 -d 192.168.26.0/24 -j RETURN
iptables -t nat -A POSTROUTING -o eth2 -s 192.168.9.0/24 -j MASQUERADE

ifconfig eth0:7 192.168.10.1
ifconfig eth2:7 192.168.60.10
route add -net 192.168.27.0 netmask 255.255.255.0 gw 192.168.60.27
iptables -t nat -A POSTROUTING -o eth2 -s 192.168.10.0/24 -d 192.168.27.0/24 -j RETURN
iptables -t nat -A POSTROUTING -o eth2 -s 192.168.10.0/24 -j MASQUERADE

ifconfig eth0:8 192.168.11.1
ifconfig eth2:8 192.168.60.11
route add -net 192.168.28.0 netmask 255.255.255.0 gw 192.168.60.28
iptables -t nat -A POSTROUTING -o eth2 -s 192.168.11.0/24 -d 192.168.28.0/24 -j RETURN
iptables -t nat -A POSTROUTING -o eth2 -s 192.168.11.0/24 -j MASQUERADE

ifconfig eth0:9 192.168.12.1
ifconfig eth2:9 192.168.60.12
route add -net 192.168.29.0 netmask 255.255.255.0 gw 192.168.60.29
iptables -t nat -A POSTROUTING -o eth2 -s 192.168.12.0/24 -d 192.168.29.0/24 -j RETURN
iptables -t nat -A POSTROUTING -o eth2 -s 192.168.12.0/24 -j MASQUERADE

ifconfig eth0:10 192.168.13.1
ifconfig eth2:10 192.168.60.13
route add -net 192.168.30.0 netmask 255.255.255.0 gw 192.168.60.30
iptables -t nat -A POSTROUTING -o eth2 -s 192.168.13.0/24 -d 192.168.30.0/24 -j RETURN
iptables -t nat -A POSTROUTING -o eth2 -s 192.168.13.0/24 -j MASQUERADE

ifconfig eth0:11 192.168.14.1
ifconfig eth2:11 192.168.60.14
route add -net 192.168.31.0 netmask 255.255.255.0 gw 192.168.60.31
iptables -t nat -A POSTROUTING -o eth2 -s 192.168.14.0/24 -d 192.168.31.0/24 -j RETURN
iptables -t nat -A POSTROUTING -o eth2 -s 192.168.14.0/24 -j MASQUERADE

ifconfig eth0:12 192.168.15.1
ifconfig eth2:12 192.168.60.15
route add -net 192.168.32.0 netmask 255.255.255.0 gw 192.168.60.32
iptables -t nat -A POSTROUTING -o eth2 -s 192.168.15.0/24 -d 192.168.32.0/24 -j RETURN
iptables -t nat -A POSTROUTING -o eth2 -s 192.168.15.0/24 -j MASQUERADE

ifconfig eth0:13 192.168.16.1
ifconfig eth2:13 192.168.60.16
route add -net 192.168.33.0 netmask 255.255.255.0 gw 192.168.60.33
iptables -t nat -A POSTROUTING -o eth2 -s 192.168.16.0/24 -d 192.168.33.0/24 -j RETURN
iptables -t nat -A POSTROUTING -o eth2 -s 192.168.16.0/24 -j MASQUERADE

ifconfig eth0:14 192.168.17.1
ifconfig eth2:14 192.168.60.17
route add -net 192.168.34.0 netmask 255.255.255.0 gw 192.168.60.34
iptables -t nat -A POSTROUTING -o eth2 -s 192.168.17.0/24 -d 192.168.34.0/24 -j RETURN
iptables -t nat -A POSTROUTING -o eth2 -s 192.168.17.0/24 -j MASQUERADE

ifconfig eth0:0 2001:0db8:0:5::1/64
ifconfig eth2:0 2001:0db8:0:1::5/64
route -A inet6 add 2001:db8:0:20::1/64 gw 2001:db8:0:1::20

ifconfig eth0:0 2001:0db8:0:6::1/64
ifconfig eth2:0 2001:0db8:0:1::6/64
route -A inet6 add 2001:db8:0:21::1/64 gw 2001:db8:0:1::21

ifconfig eth0:0 2001:0db8:0:7::1/64
ifconfig eth2:0 2001:0db8:0:1::7/64
route -A inet6 add 2001:db8:0:22::1/64 gw 2001:db8:0:1::22

ifconfig eth0:0 2001:0db8:0:8::1/64
ifconfig eth2:0 2001:0db8:0:1::8/64
route -A inet6 add 2001:db8:0:23::1/64 gw 2001:db8:0:1::23

ifconfig eth0:0 2001:0db8:0:9::1/64
ifconfig eth2:0 2001:0db8:0:1::9/64
route -A inet6 add 2001:db8:0:24::1/64 gw 2001:db8:0:1::24

ifconfig eth0:0 2001:0db8:0:10::1/64
ifconfig eth2:0 2001:0db8:0:1::10/64
route -A inet6 add 2001:db8:0:25::1/64 gw 2001:db8:0:1::25

ifconfig eth0:0 2001:0db8:0:11::1/64
ifconfig eth2:0 2001:0db8:0:1::11/64
route -A inet6 add 2001:db8:0:26::1/64 gw 2001:db8:0:1::26

ifconfig eth0:0 2001:0db8:0:12::1/64
ifconfig eth2:0 2001:0db8:0:1::12/64
route -A inet6 add 2001:db8:0:27::1/64 gw 2001:db8:0:1::27

ifconfig eth0:0 2001:0db8:0:13::1/64
ifconfig eth2:0 2001:0db8:0:1::13/64
route -A inet6 add 2001:db8:0:28::1/64 gw 2001:db8:0:1::28

ifconfig eth0:0 2001:0db8:0:14::1/64
ifconfig eth2:0 2001:0db8:0:1::14/64
route -A inet6 add 2001:db8:0:29::1/64 gw 2001:db8:0:1::29

ifconfig eth0:0 2001:0db8:0:15::1/64
ifconfig eth2:0 2001:0db8:0:1::15/64
route -A inet6 add 2001:db8:0:30::1/64 gw 2001:db8:0:1::30

ifconfig eth0:0 2001:0db8:0:16::1/64
ifconfig eth2:0 2001:0db8:0:1::16/64
route -A inet6 add 2001:db8:0:31::1/64 gw 2001:db8:0:1::31

ifconfig eth0:0 2001:0db8:0:17::1/64
ifconfig eth2:0 2001:0db8:0:1::17/64
route -A inet6 add 2001:db8:0:32::1/64 gw 2001:db8:0:1::32

ifconfig eth0:0 2001:0db8:0:18::1/64
ifconfig eth2:0 2001:0db8:0:1::18/64
route -A inet6 add 2001:db8:0:33::1/64 gw 2001:db8:0:1::33

ifconfig eth0:0 2001:0db8:0:19::1/64
ifconfig eth2:0 2001:0db8:0:1::19/64
route -A inet6 add 2001:db8:0:34::1/64 gw 2001:db8:0:1::34

mkdir -p -m 700 /var/run/racoon2
chmod 600  /etc/racoon2/spmd.pwd
chmod 600  -R /etc/racoon2/psk
spmd -f /etc/racoon2/racoon2-dut2-ipv4-ipv6-psk.conf 


sleep 3
iked -f /etc/racoon2/racoon2-dut2-ipv4-ipv6-psk.conf  

