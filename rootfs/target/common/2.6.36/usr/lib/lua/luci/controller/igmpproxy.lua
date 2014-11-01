--[[
LuCI - Lua Configuration Interface

Copyright 2012 Viktar Palstsiuk <vipals@gmail.com>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

]]--

module "luci.controller.igmpproxy"

function index()
	entry({"admin", "network", "igmpproxy"}, cbi("igmpproxy"), _("IGMP Proxy"), 80)
end
