BEGIN {
	name = "";
	ipaddr = "";
	dnscount=0;
	dnsinfo[1] = "";
	dnsinfo[2] = "";
}
{
	if ($1 ~ /^nameserver$/)
	{
		fmt = "<tr>\n"\
						"<td class='index'>%d</td>\n"\
						"<td class='name'>\n" \
							"<input class='dnsname' id='dns%d_name' value='%s'>\n" \
						"</td>\n" \
						"<td class='ipaddr'>\n" \
							"<input class='ipaddr' id='dns%d_ipaddr' value='%s'>\n" \
						"</td>\n" \
					"</tr>\n";
		dnscount++;
		dnsinfo[dnscount]=sprintf(fmt, dnscount, dnscount, $1, dnscount, $2);
	}
}
END {
  print "<br>"
	print "<h3>Domain Name Server</h3>"
	print "<div class='clearfix'>"
	print "<table>"
	print "<tbody>"
	print "<tr>"
	print "<td class='title row index'>Index</td>"
	print "<td class='title row name'>Name</td>"
	print "<td class='title row ipaddr'>IP Address</td>"
	print "</tr>";

	for(i = 1 ; i <= 2 ; i++ )
	{
		if (dnsinfo[i] != "")
		{
			print dnsinfo[i];
		}
	}	
		
 	print "</tbody>"
 	print "</table>"
 	print "</div>"
}
