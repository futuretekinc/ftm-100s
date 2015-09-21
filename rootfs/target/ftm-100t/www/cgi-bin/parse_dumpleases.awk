{
	macaddr=substr($0, 1, 17);
	ipaddr =substr($0, 19,16);
	hostname=substr($0, 35,20);
	time=substr($0, 55, 20);

	if (macaddr !~ /Mac/)
	{
		print	"<START>"
		print	"MAC:", macaddr	
		print	"IP:", ipaddr	
		print	"HOSTNAME:", hostname
		print	"EXPIRESIN:", time 
		print	"<END>"
	}
}
