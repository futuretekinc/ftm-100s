BEGIN {
	count = 0;
}
{
	count++;
	print $0
	print $6
	print split($0, a, "$6");
	
	if ($6 ~ /\[/)
	{
		print split($6, process, "]:");
		printf("%s %s %s %s %s %s\n", $1, $2, $3, $5, process[1], a[2]);
	}
	else
	{
		print split($6, process, ":");
		printf("%s %s %s %s %s %s\n", $1, $2, $3, $5, process[1], a[2]);
	}
	
	if (count >= 20)
	{
		exit(1);
	}
}
END {
}