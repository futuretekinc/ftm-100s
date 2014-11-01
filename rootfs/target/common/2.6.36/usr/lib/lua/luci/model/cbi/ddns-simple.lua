m = Map("ddns", translate("DDNS"),
	translate("Dynamic DNS allows your router to be reached with " ..
		"a fixed hostname while having a dynamically changing " ..
		"IP address."))

s = m:section(NamedSection, "myddns", "service")
s.anonymous = true

s:option(Flag, "enabled", translate("Enable"))

s:option(Value, "username", translate("Username")).rmempty = true

pw = s:option(Value, "password", translate("Password"))
pw.rmempty = true
pw.password = true

s:option(Value, "domain", translate("Hostname")).rmempty = true

o = s:option(DummyValue, "_status", "Last Update Status")
o.rawhtml = true
o:depends("enabled", "1")
o.value = 
   function()
      local fd = io.open("/var/run/dynamic_dns/myddns.log")
      local lines = ""
      if fd then
	 local line
	 repeat
	    line = fd:read("*l")
	    if line then
	       lines = lines .. "<br />" .. line
	    end
	 until not line
      else
	 lines = "status not available"
      end
      return lines
   end

-- The DDNS stuff needs a kick.  
--
local sys = require( "luci.sys" )
function m.on_after_commit(self)
   self.uci:foreach( "ddns", "service", 
		     function(section)
			local name = section['.name']
			local enabled = self.uci:get( "ddns", name, "enabled" )
			if enabled then
			   local cmd = "ACTION=ifup INTERFACE=wan /sbin/hotplug-call iface"
			   sys.call( cmd )
			else
			   local pid = "/var/run/dynamic_dns/" .. name .. ".pid"
			   if nixio.fs.access( pid ) then
			      sys.call( "kill `cat " .. pid .. "`" )
			   end
			end
		     end)
end

return m
