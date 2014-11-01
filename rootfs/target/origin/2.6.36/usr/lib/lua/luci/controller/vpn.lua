module("luci.controller.vpn", package.seeall)

local sys = require("luci.sys")

function index()
   if not nixio.fs.access("/etc/config/vpn-gui") then
      return
   end
 
   local page
 
   page = entry({"admin", "services", "vpn"}, 
                cbi("vpn"), 
                _("VPN Server"))
   page.i18n = "vpn"
   page.dependent = true

   entry({"admin", "services", "vpn", "vpn_info"},
	 call("action_vpn_info")).leaf = true
   entry({"admin", "services", "vpn", "vpn_disconnect"},
	 call("action_vpn_disconnect")).leaf = true
end

function vpn_info()
   local data = {}
   local idx = 1
   local user_data = {}
   local uci = luci.model.uci.cursor()
   uci:foreach("vpn-gui", "vpnuser",
	       function( section ) 
		  user_data[ section.ipaddress ] = section.username
	       end)
   for k, v in ipairs(nixio.getifaddrs()) do
      if v.dstaddr and v.flags.pointtopoint and v.flags.up then
	 v.username = user_data[ v.dstaddr ]
	 data[ idx ] = v
	 idx = idx + 1
      end
   end
   return data
end

function action_vpn_info()
   local data = vpn_info()
   luci.http.prepare_content("application/json")
   luci.http.write_json(data)
end

function action_vpn_disconnect()
   local iface = luci.http.formvalue("iface") or "wlan0"
   local output = sys.exec( "ifconfig " .. iface .. " down" )
   luci.http.prepare_content("application/json")
   luci.http.write_json({})
end
