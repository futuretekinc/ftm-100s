#!/bin/sh
#
#This shell scripts is use to demenstrate the software upgrade and setup uboot's superblock
#
#kernel  : ./bin/g2/scratch/bankx/uImage
#rootfs  : ./bin/g2/scratch/bankx/rootfs.img  (NAND and NOR flash)
#

erase_kernel_mtd(){

	ksize=`ls -la $kfw_name | awk '{ print $5}'`
	size4=`mtd_debug info $k_mtd | grep mtd.size |awk '{ print $3}'`
	blk_size=`mtd_debug info $k_mtd |grep mtd.erasesize | awk '{print $3}'`
	blks=$(($ksize/$blk_size+1))
	erase_size=$(($blks*$blk_size))

	echo -n "Erase $k_mtd size=$erase_size ..."
	mtd_debug erase $k_mtd 0 $erase_size  >/dev/null
	if [ $? = 0 ]; then
    echo "SUCESS"
	else
    echo "FAIL 3"
  	exit 3
	fi
}

erase_rd_mtd(){
    rsize=`ls -la $rfw_name | awk '{ print $5}'`
    size5=`mtd_debug info $r_mtd | grep mtd.size |awk '{ print $3}'`

    blk_size=`mtd_debug info $r_mtd |grep mtd.erasesize | awk '{print $3}'`
    blks=$(($rsize/$blk_size+1))
    erase_size=$(($blks*$blk_size))

    echo -n "Erase $r_mtd size=$erase_size ..."
    mtd_debug erase $r_mtd 0 $erase_size  >/dev/null
	if [ $? = 0 ]; then
    echo "SUCESS"
	else
    echo "FAIL 3"
  	exit 3
	fi    
}


usage="${0} tftp_server_ip"

shift `expr $OPTIND - 1`
[ -z ${1} ] && { 
    echo $usage
    exit 
}
serverip=${1}
flash_type=`awk -v RS=' ' -v FS='[=:]' '/mtdparts/ {print $2;}' /proc/cmdline | awk -F "_" '{print $2}'`

echo "flash type = $flash_type found."

##serverip="192.168.65.183"

echo "TFTP Server IP : $serverip"

k_mtd=/dev/`cat /proc/mtd |grep kernel_standby |awk -F ":" '{print $1}'`
r_mtd=/dev/`cat /proc/mtd |grep rootfs_standby |awk -F ":" '{print $1}'`

sb0=/dev/`cat /proc/mtd |grep sb0 |awk -F ":" '{print $1}'`
sb1=/dev/`cat /proc/mtd |grep sb1 |awk -F ":" '{print $1}'`

kfw_name=uImage
if [ $flash_type = "nor" ]; then                                                                        
    rfw_name=rootfs.img                          
    echo "NOR flash rootfs name : $rfw_name"
else                                                                                                    
    rfw_name=rootfs.img
    echo "NAND flash rootfs name : $rfw_name" 
fi

active_sb=`uci get superblock.device.name`

k_name=kernel
r_name=rootfs
if [ $active_sb = $sb0 ]; then
  #upgrade /dev/mtd2
  sb_mtd=$sb1
else
  #upgrade /dev/mtd1
  sb_mtd=$sb0
fi

pwd=`pwd`
cd /tmp

echo -n "Downloading $kfw_name from TFTP Server $serverip.."
tftp -g -r $kfw_name $serverip
retval=$?
echo "Done"

if [[ "$retval" != 0 ]]; then
	echo "TFTP fails to get $kfw_name for server $serverip"
	echo "program exit."
	exit 1
fi

if [ ! -f "$kfw_name" ]; then
   echo" file $kfw_name not found ! exit 2.."
   exit 2
fi

ksize=`ls -la $kfw_name | awk '{ print $5}'`
echo  "Writing size $ksize $kfw_name to $k_mtd ..."

if [ $flash_type = "nor" ]; then
	mtd write $kfw_name kernel_standby
else
  erase_kernel_mtd
  nandwrite -p $k_mtd $kfw_name
fi

retval=$?
if [[ $retval = 0 ]]; then
    echo "SUCESS"
else
    echo "FAIL 4"
    exit 4
fi

echo -n "Update $k_name md5 to $sb_mtd superblock.."
cs.sb --device=$sb_mtd --erasesz=0x20000 --name=$k_name --filesize=$ksize --md5=`md5sum $kfw_name |awk '{ print $1}'` >/dev/null
if [ $? = 0 ]; then
    echo "SUCESS"
else
    echo "FAIL 5"
    exit 5
fi
echo -n "Downloading $rfw_name from TFTP Server $serverip.."
tftp -g -r $rfw_name $serverip
retval=$?
echo "Done"

if [[ $retval != 0 ]]; then
	echo "TFTP fails to get $rfw_name for server $serverip"
	echo "program exit."
exit 1
fi

if [ ! -f $rfw_name ]; then
   echo" file $rfw_name not found ! exit 6.."
   exit 6
fi

rsize=`ls -la $rfw_name | awk '{ print $5}'`
echo "Writing size $rsize $rfw_name to $r_mtd..."

if [ $flash_type = "nor" ]; then
	mtd write $rfw_name rootfs_standby

else
	 erase_rd_mtd
   nandwrite -p $r_mtd $rfw_name
fi
retval=$?
if [[ $retval = 0 ]]; then
    echo "SUCESS"
else
    echo "FAIL 7"
    exit 7
fi

echo -n "Update $r_name md5 to $sb_mtd superblock.."
cs.sb --device=$sb_mtd --erasesz=0x20000 --name=$r_name --filesize=$rsize --md5=`md5sum $rfw_name|awk '{ print $1}'`  >/dev/null

cs.sb --device=$sb_mtd    --erasesz=0x20000 --valid=1 --commit=0 --active=1 >/dev/null
cs.sb --device=$active_sb --erasesz=0x20000 --valid=1 --commit=1 --active=0 >/dev/null

rm -f kfw_name
rm -f rfw_name
cd $pwd

echo "Upgrade successful !"
echo "System would boot from $sb_mtd partition next time!"
