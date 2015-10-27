#!/bin/ash

udhcpd_state() {
	if [ -e /var/run/udhcpd.pid ]
	then
		PID=$(cat /var/run/udhcpd.pid)
		return	$(ps | awk -v pid=$PID 'BEGIN{ found = 1; } { if ($1 == pid) {found = 0;} }END{ print found }')
	fi

	return	1
}

udhcpd_service(){
	case $1 in
		start) {
			if ( udhcpd_state )
			then
				echo already start
			else

				udhcpd
				sleep	1
				
				if ( udhcpd_state )
				then
					echo	success
				else
					echo	failed
				fi
			fi	

		};;

		restart){
			if ( udhcpd_state )
			then
				cat /var/run/udhcpd.pid | xargs kill
			fi

			udhcpd
			sleep	1
			
			if ( udhcpd_state )
			then
				echo	success
			else
				echo	failed
			fi
		
		};;

		stop) {
			if ( udhcpd_state )
			then
				cat /var/run/udhcpd.pid | xargs kill
				if [ $? -eq 0 ]
				then
					echo	success
				else
					echo	failed
				fi
			else
				echo	success
			fi
		};;
		
		state) {
			if ( udhcpd_state  )
			then
				echo	running
			else
				echo	stopped
			fi
		};;
	esac
}


netfilter_state() {
	return $(iptables -L -t filter | awk 'BEGIN{}{if($2 ~ /^INPUT$/){a=$4}; if ($2 ~ /^OUTPUT$/){b=$4}; if ($2 ~ /^FORWARD$/) {c=$4};}END{ if ((a ~ /^ACCEPT/) && (b ~ /^ACCEPT/) && (c ~ /^ACCEPT/)) { print 1 } else {print 0 } }');
}

netfilter_start() {
	iptables-restore < /etc/sysconfig/iptables

	return	0;
}

netfilter_stop() {
	iptables -F -t filter
	iptables -X -t filter
	iptables -P INPUT ACCEPT
	iptables -P OUTPUT ACCEPT
	iptables -P FORWARD ACCEPT

	return	0;
}

netfilter_service() {
	case $1 in
		start) {
			if ( netfilter_state )
			then
				echo already
			else
				netfilter_start
				
				if ( netfilter_state )
				then
					echo success
				else
					echo failed
				fi
			fi
		};;

		restart) {
			if ( netfilter_state )
			then
				netfilter_stop	
			fi

			netfilter_start
			
			if ( netfilter_state )
			then
				echo success
			else
				echo failed
			fi

		};;

		stop) {
			if ( netfilter_state )
			then
				netfilter_stop	

				if ( netfilter_state )
				then
					echo failed
				else
					echo success
				fi
			else
				echo success 
			fi
		};;

		state) {
			if ( netfilter_state )
			then
				echo	running
			else
				echo	stopped
			fi
		};;

		update) {
			cp -f /etc/sysconfig/iptables /etc/sysconfig/iptables.old
			cat /etc/sysconfig/iptables.static | awk '{ if ($1 !~ /^COMMIT$/){ print $0; }}' > /tmp/iptables
			awk -f /www/cgi-bin/iptables/ftmrule2iptables.awk $2 >> /tmp/iptables

			if [ -e /tmp/iptables ]
			then
				cp -f /tmp/iptables /etc/sysconfig/iptables
				#rm /tmp/iptables
				echo success
			else
				echo failed
			fi
		};;
	esac
}

case $1 in 
	udhcpd) { 
		udhcpd_service $2
	};;

	netfilter) {
		netfilter_service $2 $3
	};;
esac
