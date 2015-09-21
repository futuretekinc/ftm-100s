BEGIN {
	auto_detect = 0;	
	iface_detect = 0;
	ifname	= 0;
	address = 0;
	network = 0;
	netmask = 0;
	broadcast = 0;
	gateway	= 0;
}
{
	if ($1 ~ /^[# ]*auto/) 
	{
		auto_detect = 1;
	}

	if ($1 ~ /^[# ]*iface/)
	{
		if (auto_detect == 1)
		{
			iface_detect = 1;

			ifname = $2;
		}
	}

	if($1 ~ /^[#]*[ ]+address/)
	{
		address = $2;
	}

	if($1 ~ /^[#]*[ ]+network/)
	{
		network = $2;
	}

	if($1 ~ /^[#]*[ ]+netmask/)
	{
		netmask = $2;
	}
	
	if ($1 ~ /^[#]*[ ]+broadcast/)
	{
		broadcast = $2;	
	}

	if ($1 ~ /^[#]*[ ]+gateway/)
	{
		broadcast = $2;	
	}

	if (split($0,s,/, /) == 0)
	{
		if (iface_detect == 1)
		{
			print "auto " ifname;
			print "iface " ifname " inet static";
			print "    address " address;
			print "    network " network;
			print "    netmask " netmask;
			print "    broadcast " broadcast;
			print "    pre-up [ -f /etc/network/local-network-ok ]";
			print " "
		}
	}
}
END {
	print count;
}

