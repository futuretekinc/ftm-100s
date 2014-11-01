--[[
LuCI - Lua Configuration Interface

Copyright 2012 Viktar Palstsiuk <vipals@gmail.com>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0
]]--

require("luci.tools.webadmin")

m = Map("igmpproxy", translate("IGMP Proxy"),
	translate("IGMP proxy is intended for simple forwarding of Multicast traffic between networks. There must be at least 2 interfaces where one is upstream."))

s = m:section(TypedSection, "igmpproxy", translate("IGMP Proxy settings"))
s.anonymous = true

s:option(Flag, "quickleave", translate("Enable Quickleave mode"),
	translate("Sends Leave instantly (should be used to avoid saturation of the upstream link)"))

s2 = m:section(TypedSection, "phyint", translate("Interfaces")) 
s2.anonymous = true
s2.addremove = true

network = s2:option(ListValue, "network", translate("Network"))
luci.tools.webadmin.cbi_add_networks(network)

l = s2:option(ListValue, "direction", translate("Direction"))
l:value("downstream", translate("Downstream Interface"))
l:value("upstream", translate("Upstream Interface"))
l.default = "downstream"

s2:option(DynamicList, "altnet", translate("Altnets"),
	translate("If multicast traffic originates outside the upstream subnet, " ..
		"the altnet option can be used in order to define legal multicast sources."))

return m
