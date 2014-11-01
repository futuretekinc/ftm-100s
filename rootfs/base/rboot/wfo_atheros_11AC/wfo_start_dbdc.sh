tmp=`fw_printenv QM_INT_BUFF |  awk '{FS="="} {print$2}'`
if [ $tmp -ne 0 ]; then
  echo "The QM Internal buffer need to be 0"
  fw_setenv QM_INT_BUFF 0

  echo "fw_setenv QM_INT_BUFF 0 completed. Please reboot!!"
  exit 0
fi

echo "loading PE0 (11AC WFO) and PE1 (11N WFO) image..."
/rboot/rboot ar988x_pe0.bin ar9580_pe1.bin
sleep 2
echo "starting WFO DBDC..."
echo 1 > /proc/driver/cs752x/wfo/wifi_offload_enable
echo 0 > /proc/driver/cs752x/wfo/wifi_offload_rate_adjust
sh ath_dbdc_ap.sh 1

