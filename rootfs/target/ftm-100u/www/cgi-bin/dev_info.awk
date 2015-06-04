{
	for (i = 1 ; i <= NF ; i++)
	{
		if ($i	~ /model=*/)
		{
			split($i, tokens, "=");
			print tokens[2];
		}
		if ($i	~ /devid=*/)
		{
			split($i, tokens, "=");
			print tokens[2];
		}
	}
}
