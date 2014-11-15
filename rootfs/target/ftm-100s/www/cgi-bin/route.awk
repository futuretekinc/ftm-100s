BEGIN{
	default_route = "";
}{
	if (($1 ~ /0.0.0.0/) && ($8 ~ ifname))
	{
		defuault_route = $2	
	}
}
END{
	print default_route
}