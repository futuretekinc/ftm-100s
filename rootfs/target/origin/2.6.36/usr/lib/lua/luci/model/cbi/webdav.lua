--
-- See: http://luci.subsignal.org/trac/wiki/Documentation/CBI
--

-- Map( config, title, description )
-- where config is the name of the config file in /etc/config,
-- also the name of the init.d file in /etc/init.d
--
m = Map("webdav", translate("WebDAV Server"),
        translate("Create virtual paritions exposed thru WebDAV."))

-- Use TypedSection for uci sections selected by type,
-- NamedSection for uci sections selected by name.
--
-- NamedSection( name, type, title, description)
-- TypedSection( type, title, description)
--
-- Options
--
-- .addremove(=false) 
--     Allows the user to remove and recreate the configuration section
--
-- .dynamic(=false)
--     Marks this section as dynamic. Dynamic sections can contain an 
--     undefinded number of completely userdefined options. 
--
-- .optional(=true)
--     Parse optional options
--
-- .anonymous(=false) (TypedSection only)
--     Do not show section names
--
s = m:section(TypedSection, "partition", translate("Parition"),
	      translate("Add a webdav partition."))
s.addremove = true
s.anonymous = true

o = s:option(Value, "name", translate("Parition name"),
	     translate("Accessible with http://name"))
o.datatype = "hostname"

o = s:option(Flag, "enabled", translate("Enable"),
             translate("Enable this parition."))
o.rmempty=false

o = s:option(Value, "path", translate("Path"),
	     translate("Real directory to expose."))
o.datatype = "directory"

o = s:option(Flag, "dirlisting", translate("Enable browsing"),
             translate("http://name/ will be accessible in browsers."))
o.rmempty=false

o = s:option(Flag, "readonly", translate("Read only"),
             translate("Webdav parition will be read only."))
o.rmempty=false

o = s:option(Flag, "authenticated", translate("Authenticated"),
             translate("Use username/passwords to protect access to this parition."))
		       
o.rmempty=false

s = m:section(TypedSection, "user", translate("User"),
	      translate("Add a username/password for webdav authentication.  " ..
			"Users in this list have access to all authenticated webdav partitions."))
s.addremove = true
s.anonymous = true

o = s:option(Value, "name", translate("Username"))
o = s:option(Value, "password", translate("Password"))
o.password = true

return m
