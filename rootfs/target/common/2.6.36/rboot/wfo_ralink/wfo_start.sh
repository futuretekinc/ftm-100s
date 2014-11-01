echo 4 > /proc/driver/cs752x/ne/accel_manager/hw_accel_enable
echo 0 > /proc/driver/cs752x/ne/accel_manager/hash_default_lifetime
echo 0 > /proc/driver/cs752x/ne/ni/ni_fastbridge
echo 0 > /proc/driver/cs752x/ne/core/default_lifetime
ifconfig eth0 up
ifconfig eth1 up
brctl addbr br0
brctl addif br0 eth0
cd /rboot/wfo_ralink
/rboot/rboot wfo_pe0.bin wfo_pe1.bin
cp RT2860AP-2.4G.dat /etc/Wireless/RT2860AP/RT2860AP.dat
ifconfig ra0 up
echo 2 > /proc/irq/38/smp_affinity
echo 1 > /proc/irq/69/smp_affinity
echo 1 > /proc/irq/70/smp_affinity
echo 1 > /proc/irq/72/smp_affinity
echo 1 > /proc/irq/73/smp_affinity
echo 1 > /proc/irq/74/smp_affinity
echo 1 > /proc/irq/75/smp_affinity
echo 1 > /proc/irq/76/smp_affinity
echo 1 > /proc/irq/80/smp_affinity
echo 1 > /proc/irq/65/smp_affinity
echo 1 > /proc/irq/66/smp_affinity
echo 1 > /proc/irq/96/smp_affinity
echo 1 > /proc/irq/97/smp_affinity
ifconfig br0 192.168.1.1
echo 300 > /proc/sys/net/netfilter/nf_conntrack_udp_timeout
echo 300 > /proc/sys/net/ipv4/neigh/br0/gc_stale_time
echo 300 > /proc/sys/net/ipv4/neigh/eth0/gc_stale_time
echo 300 > /proc/sys/net/ipv4/neigh/eth1/gc_stale_time
echo 300 > /proc/sys/net/ipv4/neigh/ra0/gc_stale_time
echo 300 > /proc/sys/net/ipv4/neigh/ra1/gc_stale_time
killall5
cp RT2860AP-5G.dat /etc/Wireless/RT2860AP/RT2860AP.dat
ifconfig ra1 up
brctl addif br0 ra0
brctl addif br0 ra1
