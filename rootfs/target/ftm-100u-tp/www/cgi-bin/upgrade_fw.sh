#!/bin/sh

if [ -f /tmp/$1 ]
then
	case "$1" in
		UBOOT)
			LIST=`cat /proc/mtd | awk '{ if ($4 ~ /U-Boot/) { print $1 }}' | sed 's/://'`
			;;

		KERNEL)
			LIST=`cat /proc/mtd | awk '{ if ($4 ~ /Kernel(/) { print $1 }}' | sed 's/://'`
			;;

		RAMDISK)
			LIST=`cat /proc/mtd | awk '{ if ($4 ~ /Ramdisk(/) { print $1 }}' | sed 's/://'`
			;;

	esac
	for mtd in $LIST
	do
		echo $mtd
#		dd if=/tmp/$1 of=/mtd/$mtd conv=fsync
	done
fi
