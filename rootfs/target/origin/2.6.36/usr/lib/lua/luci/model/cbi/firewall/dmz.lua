local ds = require "luci.dispatcher"
local ft = require "luci.tools.firewall"

m = Map("firewall", translate("Firewall - DMZ"),
	translate("DMZ (Demilitarized Zone) is used to allow a single computer on the LAN to be exposed to the Internet"))

local uci  = require "luci.model.uci".cursor()

local dmz = nil
uci:foreach("firewall", "redirect",
	    function(s)
	       if s['name'] == 'DMZ' then
		  dmz = s
	       end
	    end)

local am = true
if dmz then
   am = false
end

s = m:section(TypedSection, "redirect")
s.addremove = am
s.anonymous = true
function s.filter( self, section )
   local name = self.map:get(section, "name")
   if name and name == "DMZ" then
      return true
   else
      return false
   end
end

function s.create(self, section)
   self.created_section = TypedSection.create( self, section )
   self.map:set( self.created_section, "name", "DMZ" )
   self.map:set( self.created_section, "src", "wan" )
   self.map:set( self.created_section, "proto", "all" )
   self.map:set( self.created_section, "enabled", "0" )
end

function s.parse(self, ...)
   TypedSection.parse(self, ...)
   if self.created_section then
      m.uci:save("firewall")
      m.uci:commit("firewall")
      luci.http.redirect(ds.build_url(
			    "admin/system/firewall/dmz"
		      ))
   end
end

ft.opt_enabled(s, Flag, translate("Enable"))

o = s:option( Value, "dest_ip", translate("IP Address"))
for i, e in ipairs(luci.sys.net.arptable()) do
   o:value( e["IP address"], e["IP address"] )
end
o.datatype = "ipaddr"

return m
