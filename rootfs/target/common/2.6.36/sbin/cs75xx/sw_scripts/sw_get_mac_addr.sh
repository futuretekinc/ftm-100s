#!/bin/sh
# Get MAC addresses from specific port
# Usage: sw_get_mac_addr.sh [port] ([max count])

result=""
testing=""
i=0
pre_addr=0

if [[ "$2" != "" ]]; then
	max=$2
else
	max=100
fi

printf "%5s %20s %4s %5s %10s\n" "Idx" "MAC" "VID" "port" "static"

for i in `seq 0 $max`; do
	result=`sw_cfg -c RTK_L2_ADDR_NEXT_GET -s; \
		sw_cfg -c RTK_L2_ADDR_NEXT_GET -f read_method -v 7; \
		sw_cfg -c RTK_L2_ADDR_NEXT_GET -f port -v "$1"; \
		sw_cfg -c RTK_L2_ADDR_NEXT_GET -f address -v "$i"; \
		sw_cfg -c RTK_L2_ADDR_NEXT_GET -e`

	testing=`echo $result | grep 'error'`
	if [ ! -z "$testing" ]; then
		exit
	fi

	mac=`echo "$result" | awk '/l2_data\.mac/ { print $3;}'`
	static=`echo "$result" | awk '/l2_data\.is_static/ { print $3;}'`
	vid=`echo "$result" | awk '/l2_data\.cvid/ { print $3;}'`
	port=`echo "$result" | awk '/l2_data\.port/ { print $3;}'`
	addr=`echo "$result" | awk '/address/ { print $3;}'`

	if [[ "$testing" == "" && "$mac" != "" && "$addr" != "$pre_addr" ]]; then
#		echo Index $i: $mac
		printf "%5d %20s %4d %5d %10d\n" $addr $mac $vid $port $static
	fi
	pre_addr=$addr
done
