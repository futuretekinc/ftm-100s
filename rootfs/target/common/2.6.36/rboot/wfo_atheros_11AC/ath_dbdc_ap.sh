pci0=`./get_pci_dev.sh | awk '{print $1}'`
pci1=`./get_pci_dev.sh | awk '{print $2}'`
dev_ac='none'
dev_n='none'

LINUX_VERSION=`awk '{print $3;}' /proc/version`
echo LINUX_VERSION=$LINUX_VERSION

if [ $pci0 -eq $pci1 ]; then
	echo "DBDC setup ERROR!! same device detected twice $pci0!"
    exit 0
fi

if [ $pci0 -eq 0 ]; then
  dev_ac='wifi0'
else if [ $pci0 -eq 1 ]; then 
       dev_n='wifi0'
     else   
       # for DBDC , should plug in two devices
       echo "DBDC setup ERROR!! devices detected neither 11N nor 11AC! $pci0, $pci1"
       exit 0
     fi
fi

if [ $pci1 -eq 0 ]; then
  dev_ac='wifi1'
else if [ $pci1 -eq 1 ]; then 
       dev_n='wifi1'
     else   
       # for DBDC , should plug in two devices
       echo "DBDC setup ERROR!! devices detected neither 11N nor 11AC! $pci0, $pci1"
       exit 0
     fi
fi

echo "Atheros 11ac device is $dev_ac"
echo "Atheros 11n device is $dev_n"

echo 0x605 > /proc/driver/cs752x/acp/acp_enable
echo 1 > /proc/driver/cs752x/ne/ni/ni_fastbridge
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
insmod ath_rate_atheros.ko
[ -f ath_spectral.ko ] && insmod ath_spectral.ko
insmod ath_spectral.ko
insmod ath_dfs.ko
insmod ath_dev.ko
sleep 2
insmod umac.ko

### 11ac
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


### 11N
#wlanconfig wlan1 create wlandev $dev_n wlanmode ap
#sleep 2
#iwpriv wlan1 mode 11NGHT40PLUS
#sleep 1
#iwconfig wlan1 essid ar9380
#iwconfig wlan1 channel 6
#iwpriv wlan1 shortgi 1
#brctl addif br-lan wlan1
#iwpriv wlan1 disablecoext 1
#iwpriv wlan1 chwidth 2
#ifconfig wlan1 up

echo 1 > /proc/irq/65/smp_affinity
echo 2 > /proc/irq/66/smp_affinity
echo 3 > /proc/irq/69/smp_affinity
echo 3 > /proc/irq/70/smp_affinity
