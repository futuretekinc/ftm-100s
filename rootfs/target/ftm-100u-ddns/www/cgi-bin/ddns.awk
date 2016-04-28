BEGIN {
	dns="";
	domain="";
	ip="";
}
{
	if ($1 ~ /^server/)
	{
		dns = $2;
	}
	if ($1 ~ /^zone/)
	{
		domain = $2;
	}
	if ($1 ~ /^update/)
	{
		ip = $6;
	}

}
END {
	print dns, domain, ip;
}
