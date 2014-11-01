IWPRIV_PATH=/usr/bin/rtl8192ce-script

if [ -f $IWPRIV_PATH/iwpriv ]; then
	echo "iwpriv path is" $IWPRIV_PATH/iwpriv
else
	echo "ERROR : Can't find iwpriv path. Path=" $IWPRIV_PATH/iwpriv
	exit 1
fi
export IWPRIV_PATH=$IWPRIV_PATH

$IWPRIV_PATH/setting_init.sh wlan0
$IWPRIV_PATH/default_setting.sh wlan0
$IWPRIV_PATH/wpa-tkip.sh wlan0 ap
brctl delif br-lan eth0
ifconfig eth1 0.0.0.0
ifconfig br-lan 192.168.1.1 
brctl addif br-lan eth1
brctl addif br-lan wlan0
ifconfig wlan0 up
