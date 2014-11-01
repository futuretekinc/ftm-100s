--[[
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>
Copyright 2008 Jo-Philipp Wich <xm@leipzig.freifunk.net>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id: miniupnpd.lua,v 1.2 2012/03/29 19:03:10 peebles Exp $
]]--
module("luci.controller.miniupnpd", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/upnpd") then
		return
	end

	local page

	page = entry({"admin", "services", "miniupnpd"}, 
		     cbi("miniupnpd"), _("UPnP"))
	page.i18n = "miniupnpd"
	page.dependent = true

end
