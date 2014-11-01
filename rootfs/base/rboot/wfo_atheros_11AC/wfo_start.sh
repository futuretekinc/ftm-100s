tmp=`fw_printenv QM_INT_BUFF |  awk '{FS="="} {print$2}'`
if [ $tmp -ne 0 ]; then
  echo "The QM Internal buffer need to be 0"
  fw_setenv QM_INT_BUFF 0

  echo "fw_setenv QM_INT_BUFF 0 completed. Please reboot!!"
  exit 0
fi

echo "loading PE0 11AC WFO image..."
/rboot/rboot ar988x_pe0.bin 
sleep 2
echo "enabling 11AC WFO..."
echo 1 > /proc/driver/cs752x/wfo/wifi_offload_enable
sh ath_11ac_ap.sh 1

