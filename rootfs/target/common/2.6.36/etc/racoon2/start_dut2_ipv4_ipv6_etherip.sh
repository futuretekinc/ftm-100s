
#       IXIA port#1 <----> eth1        br0         ethip         eth0 <---> DUT#1
#      -------------------------------------------------------------------
# IPv4 |192.168.21.3              192.168.21.1   0.0.0.0     192.168.60.21
#      |                          192.168.22.1               192.168.60.22
#      |                          ...                        ...          
#      |                          192.168.36.1               192.168.60.36
#      ------------------------------------------------------------------
# IPv6 |fc00:21::3                fc00:21::1     fc00:21::2  fc00:60::21   
#      |                          fc00:22::1     fc00:22::2  fc00:60::22   
#      |                          ...            ...         ...          
#      |                          fc00:36::1     fc00:36::2  fc00:60::36 

# To enable ipv4, please set the parameter ipv4=y
# To enable ipv6, please set the parameter ipv6=y
ipv4=y
ipv6=y
num_tunnels=16

killall5

clientnet=21
servernet=1

#### Setup EtherIP tunnels
if [ "$ipv4" == "y" ]; then
	bar=$clientnet
	foo=$servernet
	for i in `seq $num_tunnels`
	do
		ethiptunnel -a -d 192.168.$foo.1 -n ethip$i -s 192.168.$bar.1
		ifconfig ethip$i up
		#ifconfig ethip$i 192.168.$bar.2
		foo=$(($foo+1))
		bar=$(($bar+1))
	done
fi
if [ "$ipv6" == "y" ]; then
	bar=$clientnet
	foo=$servernet
	for i in `seq $num_tunnels`
	do
		ethip6tunnel -a -d fc00:$foo::2 -n ip6ethip$i -s fc00:$bar::2
		ifconfig ip6ethip$i up
		ifconfig ip6ethip$i fc00:$bar::2/64
		foo=$(($foo+1))
		bar=$(($bar+1))
	done
fi

#### Set IP
if [ "$ipv4" == "y" ]; then
	ifconfig eth0 192.168.60.21
	foo=22
	for i in `seq 2 $num_tunnels`
	do
		ifconfig eth0:$i 192.168.60.$foo
		foo=$(($foo+1))
	done
fi
if [ "$ipv6" == "y" ]; then
	ifconfig eth0 fc00:60::21
	foo=22
	for i in `seq 2 $num_tunnels`
	do
		ifconfig eth0:$i fc00:60::$foo
		foo=$(($foo+1))
	done
fi

#### Add routing rule
if [ "$ipv4" == "y" ]; then
	foo=$servernet
	echo 1 > /proc/sys/net/ipv4/ip_forward
	for i in `seq $num_tunnels`
	do
		route add -net 192.168.$foo.0 netmask 255.255.255.0 gw 192.168.60.$foo
		foo=$(($foo+1))
	done
fi
if [ "$ipv6" == "y" ]; then
	foo=$servernet
	echo 1 > /proc/sys/net/ipv6/conf/all/forwarding
	for i in `seq $num_tunnels`
	do
		ip -6 route add fc00:$foo::/64 via fc00:60::$foo
		foo=$(($foo+1))
	done
fi

#### Set IP tables
echo "Stopping all of iptables for IPSec..."
if [ "$ipv4" == "y" ]; then
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
	bar=$clientnet
	foo=$servernet
	for i in `seq $num_tunnels`
	do
		iptables -t nat -A POSTROUTING -o eth0 -s 192.168.$bar.0/24 -d 192.168.$foo.0/24 -j RETURN
		iptables -t nat -A POSTROUTING -o eth0 -s 192.168.$bar.0/24 -j MASQUERADE
		foo=$(($foo+1))
		bar=$(($bar+1))
	done
fi

if [ "$ipv6" == "y" ]; then
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
fi

#### Etable rules
if [ "$ipv4" == "y" ]; then
	for i in `seq $num_tunnels`
	do
		for j in `seq $num_tunnels`
		do
			if [ "$i" != "$j" ]; then
				ebtables -A FORWARD -i ethip$i -o ethip$j -j DROP
			fi
		done
	done
fi
if [ "$ipv6" == "y" ]; then
	for i in `seq $num_tunnels`
	do
		for j in `seq $num_tunnels`
		do
			if [ "$i" != "$j" ]; then
				ebtables -A FORWARD -i ip6ethip$i -o ip6ethip$j -j DROP
			fi
		done
	done
fi
if [ "$ipv4" == "y" ] && [ "$ipv6" == "y" ]; then
	for i in `seq $num_tunnels`
	do
		for j in `seq $num_tunnels`
		do
			ebtables -A FORWARD -i ip6ethip$i -o ethip$j -j DROP
			ebtables -A FORWARD -i ethip$i -o ip6ethip$j -j DROP
		done
	done
fi

#### Start Racoon2
mkdir -p -m 700 /var/run/racoon2
chmod 600  /etc/racoon2/spmd.pwd
chmod 600  -R /etc/racoon2/psk
spmd -f /etc/racoon2/racoon2-dut2-ipv4-ipv6-psk-etherip.conf

sleep 3
iked -f /etc/racoon2/racoon2-dut2-ipv4-ipv6-psk-etherip.conf

sleep 3

#### Set up bridge
brctl addbr br0
if [ "$ipv4" == "y" ]; then
	ifconfig br0 192.168.21.1
	bar=22
	for i in `seq 2 $num_tunnels`
	do
		ifconfig br0:$i 192.168.$bar.1
		bar=$(($bar+1))
	done
fi
if [ "$ipv6" == "y" ]; then
	ifconfig br0 fc00:21::1/64
	bar=22
	for i in `seq 2 $num_tunnels`
	do
		ifconfig br0:$i fc00:$bar::1/64
		bar=$(($bar+1))
	done
fi

ifconfig br0 up

brctl addif br0 eth1
if [ "$ipv4" == "y" ]; then
	for i in `seq $num_tunnels`
	do
		brctl addif br0 ethip$i
	done
fi
if [ "$ipv6" == "y" ]; then
	for i in `seq $num_tunnels`
	do
		brctl addif br0 ip6ethip$i
	done
fi
