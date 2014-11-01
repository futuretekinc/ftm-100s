LINUX_VERSION=`awk '{print $3;}' /proc/version`
echo LINUX_VERSION=$LINUX_VERSION

echo 0x605 > /proc/driver/cs752x/acp/acp_enable
echo 1 > /proc/driver/cs752x/ne/ni/ni_fastbridge

cd /lib/modules/$LINUX_VERSION/
insmod adf.ko
insmod asf.ko
insmod ath_hal.ko msi_enable=1
insmod ath_rate_atheros.ko
[ -f ath_spectral.ko ] && insmod ath_spectral.ko
insmod ath_dfs.ko
insmod ath_dev.ko
insmod umac.ko
sleep 2
wlanconfig wlan0 create wlandev wifi0 wlanmode sta
sleep 1
iwpriv wlan0 mode 11ACVHT80
iwpriv wlan0 wds 1
iwconfig wlan0 essid ika_test
iwconfig wlan0 channel 48
iwpriv wlan0 shortgi 1
iwpriv wlan0 ldpc 1
brctl addif br-lan wlan0
ifconfig wlan0 up
sleep 1
ifconfig br-lan 192.168.2.20
echo 1 > /proc/irq/65/smp_affinity
echo 2 > /proc/irq/70/smp_affinity
