-- Map( config, title, description )
-- where config is the name of the config file in /etc/config,
-- also the name of the init.d file in /etc/init.d
m = Map("vpn-gui", translate("VPN Server"),
        translate("VPN Server"))

--
-- Section: proftpd
--
s = m:section(NamedSection, "pptpd", "vpn",
              translate("VPN PPTP server"))

o = s:option(Flag, "enable", translate("Enable"))
o.rmempty=false

o = s:option(Flag, "encryption", translate("Encryption"))
o.rmempty=false

s = m:section(NamedSection, "ipsec", "vpn",
              translate("VPN L2TP/IPsec server"))

o = s:option(Flag, "enable", translate("Enable"))
o.rmempty=false

local has_certs = nixio.fs.access("/etc/ipsec.d/private/vpnserverkey.pem") and
                  nixio.fs.access("/etc/ipsec.d/crl/crls/crl.pem") and
                  nixio.fs.access("/etc/ipsec.d/cacerts/cacert.pem") and
                  nixio.fs.access("/etc/ipsec.d/certs/vpnservercert.pem")

o = s:option(ListValue, "policy", translate("IPsec Policy for L2TP"))
if has_certs then
   o:value( "certs", translate("Certificates") )
end
o:value( "psk", translate("Pre Shared Key") )

o = s:option(Value, "psk", translate("Pre-Shared Key"),
             translate("L2TP PSK"))
o:depends("policy", "psk")
o.datatype='wpakey'

s = m:section(TypedSection, "vpnuser", translate("VPN Users"),
              translate("Add VPN Users"))
s.addremove = true
s.anonymous = true

o = s:option(Value, "username", translate("User Name"))
o.datatype='string'

o = s:option(Value, "password", translate("Password"))
o.password=true

o = s:option(Value, "ipaddress", translate("IP Address"))
o.datatype='ipaddr'

s = m:section( SimpleSection )
s.template = "vpn-connections"

return m

