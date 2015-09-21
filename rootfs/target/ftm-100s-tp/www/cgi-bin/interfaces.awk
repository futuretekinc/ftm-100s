BEGIN {
	ifname = "";
	type = "";
	ipaddr = "";
	netmask = "";
	gateway = "";
}
{
	if ($1 ~ /^iface$/)
	{
		if (length(ifname) != 0)
		{
			print "INTERFACE"
			print ifname;
			print type;
			if (length(ipaddr) != 0)
			{
				print ipaddr;	
			}

			if (length(netmask) != 0)
			{
				print netmask;	
			}

			if (length(gateway) != 0)
			{
				print gateway;	
			}
		}

		if ($2 !~ /^lo$/)
		{
			ifname = $2;
			type = $4;
		}
		else
		{
			ifname = "";	
			type = "";
		}
		
		ipaddr = "";
		netmask="";
		gateway="";
	}

	if ($1 ~ /^address$/)
	{
		if (length(ifname) != 0)
		{
			ipaddr = $2	;
		}
	}

	if ($1 ~ /^netmask$/)
	{
		if (length(ifname) != 0)
		{
			netmask = $2;	
		}
	}

	if ($1 ~ /^gateway$/)
	{
		if (length(ifname) != 0)
		{
			gateway = $2;	
		}
	}
}
END {
	if (length(ifname) != 0)
	{
		print "INTERFACE"
		print ifname;
		print type;
		if (length(ipaddr) != 0)
		{
			print ipaddr;	
		}

		if (length(netmask) != 0)
		{
			print netmask;	
		}

		if (length(gateway) != 0)
		{
			print gateway;	
		}
	}

	if ($2 !~ /^lo$/)
	{
		ifname = $2;
		type = $4;
	}
	else
	{
		ifname = "";	
		type = "";
	}

	ipaddr = "";
	netmask="";
}
