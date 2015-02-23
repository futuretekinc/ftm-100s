pci0=`./get_pci_dev.sh | awk '{print $1}'`
pci1=`./get_pci_dev.sh | awk '{print $2}'`
dev_n='none'

LINUX_VERSION=`awk '{print $3;}' /proc/version`
echo LINUX_VERSION=$LINUX_VERSION

if [ $pci0 -eq 1 ]; then
  dev_n='wifi0'
else if [ $pci1 -eq 1 ]; then
     if [ $pci0 -eq 0 ]; then
       dev_n='wifi1'
     else
       dev_n='wifi0'
     fi
else
       echo "ERROR!! cannot find 11n device!!"
       exit 0
     fi
fi
echo "Atheros 11n device is $dev_n"

echo 0x605 > /proc/driver/cs752x/acp/acp_enable

if [ $1 ]; then
  if  [ $1 -eq 1 ]; then
    cd /lib/modules/2.6.36/atheros_wfo/
  else
    if [ $1 -eq 2 ]; then
      cd /lib/modules/2.6.36/atheros_wfo_11ac/
    else
      if  [ $1 -eq 3 ]; then
        cd /lib/modules/2.6.36/atheros_wfo_11n/
      fi
    fi
  fi  
else
  cd /lib/modules/2.6.36/
fi
insmod adf.ko
insmod asf.ko
insmod ath_hal.ko msi_enable=1
insmod ath_rate_atheros.ko
insmod ath_dfs.ko
insmod ath_spectral.ko
insmod ath_dev.ko
sleep 2
insmod umac.ko
sleep 2
wlanconfig wlan1 create wlandev $dev_n wlanmode ap
sleep 2
iwpriv wlan1 mode 11NGHT40PLUS
sleep 1
#iwconfig wlan1 essid ftm-100s-ap
#iwconfig wlan1 key s:k1234

/etc/wifi_config.sh
/etc/wifi_br.sh

iwconfig wlan1 channel 6
iwpriv wlan1 shortgi 1
#brctl addif br-lan wlan1
iwpriv wlan1 disablecoext 1
iwpriv wlan1 chwidth 2
ifconfig wlan1 up

echo 1 > /proc/irq/65/smp_affinity
echo 2 > /proc/irq/70/smp_affinity
