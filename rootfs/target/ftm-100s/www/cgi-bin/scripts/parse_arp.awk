{
	split($0, ipaddr, " "); 

	if (macaddr !~ /Mac/)
	{
		if (ipaddr[4] != "<incomplete>")
		{
			print "IP:", ipaddr[2]
		}
	}
}
