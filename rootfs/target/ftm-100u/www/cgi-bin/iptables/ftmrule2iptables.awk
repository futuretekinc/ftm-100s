BEGIN {
}
{
	if ($1 ~ /^TABLE$/)
	{
			printf("*%s\n",  $2);
	}
	else if ($1 ~ /^CHAIN$/)
	{
		printf(":%s %s\n", $2, $3);
	}
	else if($1 ~ /^RULE$/)
	{
		printf("-A %-8s ", $2);
		if ($3 ~ /^IN$/)
		{
			printf("-i %-6s ", $4);
		}
		else if ($3 ~ /^OUT$/)
		{
			printf("-o %-6s ", $4);
		}
		else 
		{
			printf("          ");	
		}

		if ($5 ~ /^0.0.0.0$/)
		{
			printf("                    ");	
		}
		else
		{
			printf("-s %-16s ", $5);
		}

		if ($6 ~ /^0.0.0.0$/)
		{
			printf("                    ");	
		}
		else
		{
			printf("-d %-16s ", $6);
		}

		if ($7 ~ /^tcp$|^udp$/)
		{
			printf("-p %-8s ", $7);
		}
		else if ($7 ~ /^icmp$/)
		{
			printf("-p %-8s ", $7);
		}
		else
		{
			printf("           ");
		}

		if ($8 ~ /^0$/)
		{
			printf("                                          ");	
		}
		else if ($8 ~ /^echo-reply$/)
		{
			printf("--icmp-type echo-reply                   ");
		}
		else
		{
			if ($2 ~ /OUTPUT/)
			{
				printf("-m %-8s --sport %16s     ", $7, $8);	
			}
			else 
			{
				printf("                                          ");	
			}
		}

		if ($9 ~ /^0$/)
		{
			printf("                                          ");	
		}
		else if ($9 ~ /^echo-request$/)
		{
			printf("--icmp-type echo-request                 ");
		}
		else
		{
			if ($2 ~ /^INPUT$/)
			{
				printf("-m %-8s --dport %16s     ", $7, $9);	
			}
			else 
			{
				printf("                                          ");	
			}
		}

		printf("-j %-8s\n", $10);
	}
}
END {
	print	"COMMIT"
}
