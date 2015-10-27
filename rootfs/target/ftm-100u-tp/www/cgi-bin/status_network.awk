BEGIN {   
	detect  =0;
	idx	  	=0;
	ethcount=0;
	ethinfo[1]="";
	ethinfo[2]="";
	p2pcount=0;
	p2pinfo[1]="";
}
{
	if (($2 ~ /Link/) && ($3 ~ /encap:*/))
	{	
		split($3, a, ":");

		ifname 	= $1;
		type		= a[2];
		macaddr	= 0;
		ptp			= 0;
		ipaddr 	= 0;
		netmask	= 0;
		detect	= 1;
		item		= 2;
	}
	
	if (detect == 1)
	{
		n = split($0, array, " ");
		if(n == 0)
		{
			if (item == 5)
			{
				if (type == "Ethernet")
				{
					ethcount++;
					printf("eth %d %s %s %s %s\n", ethcount, ifname, ipaddr, netmask, macaddr);
				}
	
				if (type == "Point-to-Point")
				{
					p2pcount++;
					printf("p2p %d %s %s %s %s\n", p2pcount, ifname, ipaddr, netmask, ptp);
				}
			}

			ifname 	= 0;
			type		= 0;
			macaddr	= 0;
			ptp			= 0;
			ipaddr 	= 0;
			netmask	= 0;
			detect	= 0;
			item		= 0;
		}
		
		if ($4 ~ /HWaddr/)
		{
			macaddr = $5;
			item++;
		}
		
		if ($2 ~ /addr:[0-9]+.[0-9]+.[0-9]+.[0-9]+/)
		{
			split($2, a, ":");
			ipaddr = a[2];
			item++;
		}
				
		if ($3 ~ /P-t-P:[0-9]+.[0-9]+.[0-9]+.[0-9]+/)
		{
		print hello
			split($3, a, ":");
			ptp= a[2];
			item++;
		}

		if ($4 ~ /Mask:[0-9]+.[0-9]+.[0-9]+.[0-9]+/)
		{
			split($4, a, ":");
			netmask= a[2];
			item++;
		}
	}
	

}
END {  
}        
