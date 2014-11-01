require("uci")
uci = uci.cursor()

m = Map("dhcp", translate("DHCP Server"))

s = m:section(NamedSection, "lan", "dhcp")

-- o = s:option(Flag, "ftp_enabled", translate("Enable FTP Server"))
-- o.rmempty = false

o = s:option(Value, "start", translate("DHCP IP Address Start"))
o.template = "cbi/pip4"
o.rmempty = false
o.datatype = "integer"

o = s:option(Value, "end", translate("DHCP IP Address End"))
o.template = "cbi/pip4"
o.rmempty = false
o.datatype = "integer"

o = s:option(Value, "leasetime", translate("Maximum Lease Time"),
	     translate("Expiry time of leased addresses, minimum is 2 Minutes (<code>2m</code>)."))
o.rmempty = false
o.default = "12h"

function o.validate( self, value )
   return( value:match("^%d+[hmd]$") )
end

return m
