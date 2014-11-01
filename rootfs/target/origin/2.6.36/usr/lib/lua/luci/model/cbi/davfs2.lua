-- Map( config, title, description )
-- where config is the name of the config file in /etc/config,
-- also the name of the init.d file in /etc/init.d
m = Map("davfs2", translate("WebDAV Client"),
        translate("Mount file systems exported by remote WebDAV servers."))

--
-- Section: davfs2
--
s = m:section(TypedSection, "davfs2", translate("Partition"))
s.anonymous=true
s.addremove = true

o = s:option(Flag, "enabled", translate("Enable"))
o.rmempty=false

o = s:option(Value, "server_ip", translate("Server IP Address"))
o.default = "192.168.0.0"
o.datatype='ipaddr'

o = s:option(Value, "server_port", translate("Server Port"))
o.default = "8080"
o.datatype='port'

o = s:option(Value, "mount_point", translate("Local Mount Point"))
o.default = "/mnt/webdav"
o.datatype='string'

return m

