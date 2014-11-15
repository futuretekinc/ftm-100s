#!/bin/sh

#   ---------------------------------------------
#   Set PATH
#   ---------------------------------------------
CONFIG_PATH=/etc/config

LIBRARY_PATH=/lib:/usr/lib:/usr/local/lib
PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/opt/bin

#   ---------------------------------------------
#   Prints execution status.
#
#   arg1 : Execution status
#   arg2 : Continue (0) or Abort (1) on error
#   ---------------------------------------------
status ()
{
       if [ $1 -eq 0 ] ; then
               echo "[SUCCESS]"
       else
               echo "[FAILED]"

               if [ $2 -eq 1 ] ; then
                       echo "... System init aborted."
                       exit 1
               fi
       fi
}

#  ----------------------------------------------
#  Print Model  
#  ----------------------------------------------

get_model()
{
	CMDLINE=`cat /proc/cmdline`
	for x in $CMDLINE; do
		case $x in
			model=*)
				echo "${x#model=}"
				break;
				;;
		esac
	done
}

#  ----------------------------------------------
#  Print Serial Number
#  ----------------------------------------------

get_sn()
{
	CMDLINE=`cat /proc/cmdline`
	for x in $CMDLINE; do
		case $x in
			sn=*)
				echo "${x#sn=}"
				break;
				;;
		esac
	done
}

#  ----------------------------------------------
#  Print File System Version
#  ----------------------------------------------

get_version()
{
	echo `cat /etc/version`
}

#  ----------------------------------------------
#  Print WAN Interface
#  ----------------------------------------------

get_wan()
{
	WAN=`cat $CONFIG_PATH/wan`

	if [ "$WAN" = "ppp0" ]
	then
		echo "ppp0"
	else
		echo "eth0"
	fi
}

set_wan()
{
	echo "$1" > "$CONFIG_PATH/wan"

}

#  ----------------------------------------------
#  Set bridge mode
#  ----------------------------------------------

bridge_on()
{
	echo 'on' > $CONFIG_PATH/bridge
}

bridge_off()
{
	echo 'off' > $CONFIG_PATH/bridge
}
#  ----------------------------------------------
#  Print bridge mdoe
#  ----------------------------------------------

is_bridge()
{
	RETVAL="off"
	BRIDGE=`cat $CONFIG_PATH/bridge`
	if [ "$BRIDGE" = "on" ]
	then
		RETVAL="on"
	fi

	echo $RETVAL
}
