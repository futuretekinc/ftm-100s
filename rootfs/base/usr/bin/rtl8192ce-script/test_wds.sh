IWPRIV_PATH=/usr/bin/rtl8192ce-script

if [ -f $IWPRIV_PATH/iwpriv ]; then
	echo "iwpriv path is" $IWPRIV_PATH/iwpriv
else
	echo "ERROR : Can't find iwpriv path. Path=" $IWPRIV_PATH/iwpriv
	exit 1
fi
export IWPRIV_PATH=$IWPRIV_PATH

$IWPRIV_PATH/default_setting.sh $1
### WDS related mib start
iwpriv $1 set_mib wds_enable=1
iwpriv $1 set_mib wds_pure=0
iwpriv $1 set_mib wds_priority=1
iwpriv $1 set_mib wds_num=0
iwpriv $1 set_mib wds_encrypt=0  ## 0:none 1:wep40 2:tkip 4:aes 5:wep104
iwpriv $1 set_mib wds_wepkey=12345
iwpriv $1 set_mib wds_passphrase=12345678
iwpriv $1 set_mib wds_add=00017301FE10,0  ## peer mac address, rate
$IWPRIV_PATH/init.sh  ## use enctyption shell in /root/script, like wpa2-aes.sh, ...
### WDS related mib end


brctl delif br-lan eth0
brctl addif br-lan eth1
ifconfig eth1 0.0.0.0
ifconfig br-lan 192.168.1.1
brctl addif br-lan eth1
brctl addif br-lan $1
ifconfig $1 up
echo 1 > /proc/sys/net/ipv6/conf/$1-wds0/disable_ipv6
ifconfig $1-wds0 up
brctl addif br-lan $1-wds0
