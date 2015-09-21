BEGIN {
	count = 0;
	static="disable";
	interface="eth0";
	ip_pool_start="192.168.0.20";
	ip_pool_end="192.168.0.254";
	lease_time=86400;
	router = "";
	dnsCnt = 0;
	dns1 = "";
	dns2 = "";
}
{
	if ($1 ~ /^static$/)
	{
		static=$2;
	}

	if($1 ~ /^interface/)
	{
		interface = $2;
	}
	
	if($1 ~ /^start/) 
	{
		ip_pool_start = $2;
	}
	
	if($1 ~ /^end/) 
	{
		ip_pool_end = $2;
	}
	
	if (($1 ~ /^opt/) && ($2 ~ /lease/)) 
	{
		lease_time = $3;
	}
	
	if (($1 ~ /^opt/) && ($2 ~ /router/)) 
	{
		router = $3;
	}
	if (($1 ~/^opt/) && ($2 ~ /dns/))
	{
		dnsCnt++;
		if (dnsCnt == 1)
		{
			dns1 = $3;
		}
		if (dnsCnt == 2)
                {               
                        dns2 = $3;
                }
	}
	if ($1 ~ /static_lease/)
	{
		count++;
		static_lease_mac[count] = $2;
		static_lease_ip[count] = $3;
	}
	
	if (($1 ~ /^#/) && ($2 ~ /^static_lease/))
	{
		count++;
		static_lease_mac[count] = $3;
		static_lease_ip[count] = $4;
	}
}
END {
	print "INTERFACE: ", interface;
	print "START: ", ip_pool_start;
	print "END: ", ip_pool_end;
	print "ROUTER: ", router;
	print "TIME: ", lease_time;
	print "STATIC: ", static;
	print "DNS1: ", dns1;
	print "DNS2: ", dns2;
	
	for(i = 1 ; i <= count ; i++)
	{
		if (static_lease_mac[i] != "")
		{
			printf("STATIC_LEASE: %s %s\n", static_lease_mac[i], static_lease_ip[i]);
		}
	}
}
