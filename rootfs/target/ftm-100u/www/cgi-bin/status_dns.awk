BEGIN{
	dnscount = 0;
}
{
	if (NF != 0)
	{
		dnscount++;
		printf ("dns %d %s %s\n", dnscount, $1, $2);
	}
}
END{
}