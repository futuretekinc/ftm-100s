m = Map("ftpsamba", translate("FTP/SAMBA"))

s = m:section(NamedSection, "ftpsamba", "settings")

o = s:option(Flag, "ftp_enabled", translate("Enable FTP Server"))
o.rmempty = false

o = s:option(Flag, "samba_enabled", translate("Enable SAMBA Server"))
o.rmempty = false

o = s:option(ListValue, "permission", translate("Permission"))
o:value("rw", "Read+Write")
o:value("ro", "Read")

o = s:option(DummyValue, "id", translate("ID"))
o.rmempty = false

o = s:option(Value, "password", translate("Password"))
o.rmempty = false
o.password = true

local file,err = io.open("/tmp/ftpsmb", "w")
local so = o.cfgvalue(s)
file:write("ftp_old="..so.ftpsamba.ftp_enabled.."\nsmb_old="..so.ftpsamba.samba_enabled)
file:close()

return m
