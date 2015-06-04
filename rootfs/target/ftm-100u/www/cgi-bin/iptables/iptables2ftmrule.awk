BEGIN{
	input_policy = "ACCEPT";
	output_policy = "ACCEPT";
	forward_policy = "ACCEPT";
	idx = 0;
}
{
	group = 0;	
	chain = unknown;
	direction = unknown;
	ifname = unknown;
	sip	= "0.0.0.0";
	dip	= "0.0.0.0";
	protocol = unknown;
	rule_match=0;
	dport = 0;
	sport = 0;
	policy = unknown;

	len = split($0, array);

	skip = 0;
	for(i = 1 ; i <= len ; i++)
	{
		if (skip > 0)
		{
			skip-- ;
			continue;
		}
		
		if (array[i] ~ /^:INPUT$/)
		{
			group = 1;
			input_policy = $2;
		}
		else if (array[i] ~ /^:OUTPUT$/)
		{
			group = 1;
			output_policy = $2;
		}
		else if (array[i] ~ /^:FORWARD$/)
		{
			group = 1;
			forward_policy = $2;
		}
		else if (array[i] ~ /^-A$/)
		{
			group = 2;
			chain = array[i+1];
			skip = 1;
		}
		else if(array[i] ~ 	/^-i$/ )
		{
			direction = "IN";
			ifname = array[i+1];
			skip = 1;
		}
		else if(array[i] ~ 	/^-o$/ )
		{
			direction = "OUT";
			ifname = array[i+1];
			skip = 1;
		}
		else if(array[i] ~ 	/^-s$/ )
		{
			sip = arrary[i+1];
			skip = 1;
		}
		else if(array[i] ~ 	/^-d$/ )
		{
			dip = arrary[i+1];
			skip = 1;
		}
		else if(array[i] ~ 	/^-p$/ )
		{
			protocol = array[i+1];
			skip = 1;
		}
		else if(array[i] ~ 	/^-m$/ )
		{
			rule_match=1;
			if(array[i+2] ~ 	/^--dport$/ )
			{
				dport = array[i+3];
			}
			else if(array[i] ~ 	/^--sport$/ )
			{
				sport = array[i+3];	
			}
			skip = 3;
		}
		else if(array[i] ~ 	/^--sport$/ )
		{
			sport = array[i+1];
			skip = 1;
		}
		else if(array[i] ~ 	/^--dport$/ )
		{
			dport = array[i+1];
			skip = 1;
		}
		else if(array[i] ~ 	/^--icmp-type$/ )
		{	
			if(direction  ~ 	"IN" )
			{
				dport = array[i+1];
			}
			else if(array[i] ~ 	"OUT" )
			{
				sport = array[i+1];
			}
			skip = 1;
		}
		else if(array[i] ~ 	/^-j$/ )
		{
			policy = array[i+1];
			skip = 1;
		}
		else
		{
			chain = unknown;
		}
	}

	if (chain ~ /^INPUT|^OUTPUT/)
	{
		if ((direction != unknown) && (ifname != unknown) && (protocol != unknown) && (policy != unknown))
		{
			idx++;
			filters[idx] = sprintf("%-7s %-7s %-7s %-15s %-15s %-7s %-15s %-15s %-7s", chain, direction, ifname, sip, dip, protocol, sport, dport, policy);	
		}
	}
	else if (chain ~ /^FORWARD/)
	{
		if ((chain != unknown) && (direction != unknown) && (ifname != unknown) && (policy != unknown))
		{
			idx++;
			filters[idx] = sprintf("%-7s %-7s %-7s %-15s %-15s %-7s %-15s %-15s %-7s", chain, direction, ifname, sip, dip, "all", sport, dport, policy);	
		}
	}
}
END{
	print "TABLE filter"
	print "CHAIN INPUT " input_policy
	print "CHAIN FORWARD " forward_policy
	print "CHAIN OUTPUT " output_policy

	for(i = 1; i <= idx ; i++)
	{
		print "RULE  " filters[i];	
	}
}
