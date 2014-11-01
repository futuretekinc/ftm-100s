clinkd -Dvvtf /etc -s 2 --firmware /etc/ccpu.elf --mac-addr 00:13:25:A0:34:08 -i /dev/jaws2 &
clinkd -Dvvtf /etc -s 3 --firmware /etc/ccpu.elf --mac-addr 00:13:25:C0:34:08 -i /dev/jaws3 &

ifconfig eth0 0.0.0.0
ifconfig eth1 0.0.0.0
ifconfig eth2 0.0.0.0
brctl addbr br0
brctl addif br0 eth0
brctl addif br0 eth1
brctl addif br0 eth2
ifconfig br0 192.168.1.1
#echo 1 > /proc/irq/65/smp_affinity
#echo 1 > /proc/irq/66/smp_affinity
#echo 1 > /proc/irq/96/smp_affinity
#echo 1 > /proc/irq/97/smp_affinity
#echo 2 > /proc/irq/70/smp_affinity
/etc/init.d/samba stop
echo 1 > /proc/irq/64/smp_affinity
#echo 1 > /proc/irq/75/smp_affinity
#echo 1 > /proc/irq/76/smp_affinity
/etc/init.d/samba start
ID=$(cat /var/log/samba/smbd.pid)
taskset -p 2 $ID
ID=$(cat /var/log/samba/nmbd.pid)
taskset -p 2 $ID
