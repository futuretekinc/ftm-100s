#!/bin/sh

PAGESIZE=131072

find_mtd()
{
	MTD=`cat /proc/mtd | awk -v x=\"$1\" '{ if ($4 ~ x) print $1}' | sed 's/://'`
	echo "$MTD"
}

upgrade_kernel()
{
	success_msg="success"
	case "$1" in
		"primary") 
			MTD=$( find_mtd kernel ) 
			success_msg="primary success"
			;;

		"secodnary") 
			MTD=$( find_mtd kernel_standby ) 
			;;

		"all")
			upgrade_kernel "primary" $2
			upgrade_kernel "secondary" $2
			return
			;;

		*) 
			echo "failed"
			return 
			;;
	esac

	echo "align_file $PAGESIZE $2 /tmp/$2.tmp"
	align_file	$PAGESIZE $2 /tmp/$2.tmp

	echo "flash_eraseall /dev/$MTD"
	flash_erase /dev/$MTD

	echo "flashcp /tmp/$2.tmp /dev/$MTD"
	flashcp /tmp/$2.tmp /dev/$MTD

	rm /tmp/$2.tmp

	echo "$success_msg"
}

upgrade_rootfs()
{
	success_msg="success"
	case "$1" in
		"primary")
			MTD=$( find_mtd rootfs ) 
			success_msg="primary success"
			;;

		"secondary")
			MTD=$( find_mtd rootfs_standby ) 
			;;

		"all")
			upgrade_rootfs "primary" $2
			upgrade_rootfs "secondary" $2
			return
			;;
		*)
			echo "failed"
			return
			;;
	esac

	echo "dd if=$2 of=/tmp/fs.head bs=64 count=1"
	dd if=$2 of=/tmp/fs.head bs=64 count=1
	echo "dd if=$2 of=/tmp/fs.body bs=64 skip=1"
	dd if=$2 of=/tmp/fs.body bs=64 skip=1

	echo "align_file $PAGESIZE /tmp/fs.body /tmp/fs.tmp"
	align_file $PAGESIZE /tmp/fs.body /tmp/fs.tmp

	echo "flash_eraseall /dev/$MTD"
	flash_eraseall /dev/$MTD

	echo "flashcp /tmp/fs.tmp /dev/$MTD"
	flashcp /tmp/fs.tmp /dev/$MTD

	echo "update_sys_info /dev/mtdblock0 rootfs $1 /tmp/fs.head"
	update_sys_info /dev/mtdblock0 rootfs $1 /tmp/fs.head /tmp/head.loc /tmp/new_head.tmp

	OFFSET=`cat /tmp/head.loc`
	echo "flash_erase /dev/mtd0 $OFFSET 1"
	flash_erase /dev/mtd0 $OFFSET 1

	SEEK_BLOCK=$(($OFFSET/$PAGESIZE))
	echo "dd if=/tmp/new_head.tmp of=/dev/mtd0 bs=$PAGESIZE seek=$SEEK_BLOCK"
	dd if=/tmp/new_head.tmp of=/dev/mtd0 bs=$PAGESIZE seek=$SEEK_BLOCK

	rm /tmp/fs.head /tmp/fs.body /tmp/fs.tmp /tmp/head.loc /tmp/new_head.tmp
	echo "$success_msg"

}

case "$1" in
	"kernel")
		upgrade_kernel $2 $3
		;;

	"rootfs")
		upgrade_rootfs $2 $3
		;;
	*)
		;;
esac
