pci0=`./get_pci_dev.sh | awk '{print $1}'`
pci1=`./get_pci_dev.sh | awk '{print $2}'`
dev_ac='none'

LINUX_VERSION=`awk '{print $3;}' /proc/version`
echo LINUX_VERSION=$LINUX_VERSION

if [ $pci0 -eq 0 ]; then
  dev_ac='wifi0'
else if [ $pci1 -eq 0 ]; then
     if [ $pci0 -eq 1 ]; then
       dev_ac='wifi1'
     else
       dev_ac='wifi0'
     fi
else
       echo "ERROR!! cannot find 11ac device!!"
       exit 0
     fi
fi
echo "Atheros 11ac device is $dev_ac"

echo 0x605 > /proc/driver/cs752x/acp/acp_enable

if [ $1 ]; then
  if  [ $1 -eq 1 ]; then
    cd /lib/modules/$LINUX_VERSION/atheros_wfo/
  else
    if [ $1 -eq 2 ]; then
      cd /lib/modules/$LINUX_VERSION/atheros_wfo_11ac/
    else
      if  [ $1 -eq 3 ]; then
        cd /lib/modules/$LINUX_VERSION/atheros_wfo_11n/
      fi
    fi
  fi  
else
  cd /lib/modules/$LINUX_VERSION/
fi
insmod adf.ko
insmod asf.ko
insmod ath_hal.ko msi_enable=1
[ -f ath_spectral.ko ] && insmod ath_spectral.ko
insmod ath_rate_atheros.ko
insmod ath_dfs.ko
insmod ath_dev.ko
sleep 2
insmod umac.ko
sleep 2
wlanconfig wlan0 create wlandev $dev_ac wlanmode ap
sleep 2
iwpriv wlan0 mode 11ACVHT80
sleep 1
iwpriv wlan0 wds 1
iwconfig wlan0 essid ika_test
iwconfig wlan0 channel 48
iwpriv wlan0 shortgi 1
iwpriv wlan0 ldpc 1
brctl addif br-lan wlan0
ifconfig wlan0 up

echo 1 > /proc/irq/65/smp_affinity
echo 2 > /proc/irq/70/smp_affinity
