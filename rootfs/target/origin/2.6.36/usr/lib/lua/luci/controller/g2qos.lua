-- 
-- Copyright (C) 2012 Cortina Systems, Inc.
-- All rights reserved.
--

module("luci.controller.g2qos", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/g2qos") then
		return
	end
	local page
	page = entry({"admin", "network", "g2qos"}, cbi("g2qos"), _("G2 QoS"), 30)
	page.dependent = true	
end
