--[[
LuCI - Lua Configuration Interface

Copyright 2011 Jo-Philipp Wich <xm@subsignal.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id: vhost-details.lua,v 1.1.1.1 2012/09/20 11:21:01 fiona Exp $
]]--

local sys = require "luci.sys"
local dsp = require "luci.dispatcher"
local ft  = require "luci.tools.firewall"

local m, s, o

arg[1] = arg[1] or ""

m = Map("firewall",
	translate("Firewall - Virtual Hosts"),
	translate("This page allows you to change advanced properties of the virtual \
	           host entry. In most cases there is no need to modify \
			   those settings."))

m.redirect = dsp.build_url("admin/system/firewall/vhosts")

if m.uci:get("firewall", arg[1]) ~= "redirect" then
	luci.http.redirect(m.redirect)
	return
else
	local name = m:get(arg[1], "name") or m:get(arg[1], "_name")
	if not name or #name == 0 then
		name = translate("(Unnamed Entry)")
	end
	m.title = "%s - %s" %{ translate("Firewall - Virtual Hosts"), name }
end

local wan_zone = nil

m.uci:foreach("firewall", "zone",
	function(s)
		local n = s.network or s.name
		if n then
			local i
			for i in n:gmatch("%S+") do
				if i == "wan" then
					wan_zone = s.name
					return false
				end
			end
		end
	end)
s = m:section(NamedSection, arg[1], "redirect", "")
s.anonymous = true
s.addremove = false

ft.opt_enabled(s, Button)
ft.opt_name(s, Value, translate("Name"))


o = s:option(Value, "proto", translate("Protocol"))
o:value("tcp udp", "TCP+UDP")
o:value("tcp", "TCP")
o:value("udp", "UDP")
o:value("icmp", "ICMP")

function o.cfgvalue(...)
	local v = Value.cfgvalue(...)
	if not v or v == "tcpudp" then
		return "tcp udp"
	end
	return v
end


o = s:option(Value, "src", translate("Source zone"))
o.nocreate = true
o.default = "wan"
o.template = "cbi/firewall_zonelist"


o = s:option(DynamicList, "src_mac",
	translate("Source MAC address"),
	translate("Only match incoming traffic from these MACs."))
o.rmempty = true
o.datatype = "macaddr"
o.placeholder = translate("any")


o = s:option(Value, "src_ip",
	translate("Source IP address"),
	translate("Only match incoming traffic from this IP or range."))
o.rmempty = true
o.datatype = "neg(ip4addr)"
o.placeholder = translate("any")


o = s:option(Value, "src_port",
	translate("Source port"),
	translate("Only match incoming traffic originating from the given source port or port range on the client host"))
o.rmempty = true
o.datatype = "portrange"
o.placeholder = translate("any")


o = s:option(Value, "src_dip",
	translate("External IP address"),
	translate("Only match incoming traffic directed at the given IP address."))

o.rmempty = true
o.datatype = "ip4addr"
o.placeholder = translate("any")


o = s:option(Value, "src_dport", translate("External port"),
	translate("Match incoming traffic directed at the given " ..
		"destination port or port range on this host"))
o.datatype = "portrange"



o = s:option(Value, "dest", translate("Internal zone"))
o.nocreate = true
o.default = "lan"
o.template = "cbi/firewall_zonelist"


o = s:option(Value, "dest_ip", translate("Internal IP address"),
	translate("Redirect matched incoming traffic to the specified \
		internal host"))
o.datatype = "ip4addr"
for i, dataset in ipairs(sys.net.arptable()) do
	o:value(dataset["IP address"])
end


o = s:option(Value, "dest_port",
	translate("Internal port"),
	translate("Redirect matched incoming traffic to the given port on \
		the internal host"))
o.placeholder = translate("any")
o.datatype = "portrange"


o = s:option(Flag, "reflection", translate("Enable NAT Loopback"))
o.rmempty = true
o.default = o.enabled
o:depends("src", wan_zone)
o.cfgvalue = function(...)
	return Flag.cfgvalue(...) or "1"
end


s:option(Value, "extra",
	translate("Extra arguments"),
	translate("Passes additional arguments to iptables. Use with care!"))


return m
