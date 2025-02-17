--[[
LuCI - Lua Configuration Interface

Copyright 2011 Jo-Philipp Wich <xm@subsignal.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id: firewall.lua 8139 2012-01-01 15:31:25Z jow $
]]--

module("luci.tools.firewall", package.seeall)

local ut = require "luci.util"
local ip = require "luci.ip"
local nx = require "nixio"

local translate, translatef = luci.i18n.translate, luci.i18n.translatef

function fmt_neg(x)
	if type(x) == "string" then
		local v, neg = x:gsub("^ *! *", "")
		if neg > 0 then
			return v, "%s " % translate("not")
		else
			return x, ""
		end
	end
	return x, ""
end

function fmt_mac(x)
	if x and #x > 0 then
		local m, n
		local l = { translate("MAC"), " " }
		for m in ut.imatch(x) do
			m, n = fmt_neg(m)
			l[#l+1] = "<var>%s%s</var>" %{ n, m }
			l[#l+1] = ", "
		end
		if #l > 1 then
			l[#l] = nil
			if #l > 3 then
				l[1] = translate("MACs")
			end
			return table.concat(l, "")
		end
	end
end

function fmt_port(x, d)
	if x and #x > 0 then
		local p, n
		local l = { translate("port"), " " }
		for p in ut.imatch(x) do
			p, n = fmt_neg(p)
			local a, b = p:match("(%d+)%D+(%d+)")
			if a and b then
				l[1] = translate("ports")
				l[#l+1] = "<var>%s%d-%d</var>" %{ n, a, b }
			else
				l[#l+1] = "<var>%s%d</var>" %{ n, p }
			end
			l[#l+1] = ", "
		end
		if #l > 1 then
			l[#l] = nil
			if #l > 3 then
				l[1] = translate("ports")
			end
			return table.concat(l, "")
		end
	end
	return d and "<var>%s</var>" % d
end

function fmt_ip(x, d)
	if x and #x > 0 then
		local l = { translate("IP"), " " }
		local v, a, n
		for v in ut.imatch(x) do
			v, n = fmt_neg(v)
			a, m = v:match("(%S+)/(%d+%.%S+)")
			a = a or v
			a = a:match(":") and ip.IPv6(a, m) or ip.IPv4(a, m)
			if a and (a:is6() and a:prefix() < 128 or a:prefix() < 32) then
				l[1] = translate("IP range")
				l[#l+1] = "<var title='%s - %s'>%s%s</var>" %{
					a:minhost():string(),
					a:maxhost():string(),
					n, a:string()
				}
			else
				l[#l+1] = "<var>%s%s</var>" %{
					n,
					a and a:string() or v
				}
			end
			l[#l+1] = ", "
		end
		if #l > 1 then
			l[#l] = nil
			if #l > 3 then
				l[1] = translate("IPs")
			end
			return table.concat(l, "")
		end
	end
	return d and "<var>%s</var>" % d
end

function fmt_zone(x, d)
	if x == "*" then
		return "<var>%s</var>" % translate("any zone")
	elseif x and #x > 0 then
		return "<var>%s</var>" % x
	elseif d then
		return "<var>%s</var>" % d
	end
end

function fmt_icmp_type(x)
	if x and #x > 0 then
		local t, v, n
		local l = { translate("type"), " " }
		for v in ut.imatch(x) do
			v, n = fmt_neg(v)
			l[#l+1] = "<var>%s%s</var>" %{ n, v }
			l[#l+1] = ", "
		end
		if #l > 1 then
			l[#l] = nil
			if #l > 3 then
				l[1] = translate("types")
			end
			return table.concat(l, "")
		end
	end
end

function fmt_proto(x, icmp_types)
	if x and #x > 0 then
		local v, n
		local l = { }
		local t = fmt_icmp_type(icmp_types)
		for v in ut.imatch(x) do
			v, n = fmt_neg(v)
			if v == "tcpudp" then
				l[#l+1] = "TCP"
				l[#l+1] = "UDP"
				l[#l+1] = ", "
			elseif v ~= "all" then
				local p = nx.getproto(v)
				if p then
					-- ICMP
					if (p.proto == 1 or p.proto == 58) and t then
						l[#l+1] = translatef(
							"%s%s with %s",
							n, p.aliases[1] or p.name, t
						)
					else
						l[#l+1] = "%s%s" %{
							n,
							p.aliases[1] or p.name
						}
					end
					l[#l+1] = ", "
				end
			end
		end
		if #l > 0 then
			l[#l] = nil
			return table.concat(l, "")
		end
	end
end

function fmt_limit(limit, burst)
	burst = tonumber(burst)
	if limit and #limit > 0 then
		local l, u = limit:match("(%d+)/(%w+)")
		l = tonumber(l or limit)
		u = u or "second"
		if l then
			if u:match("^s") then
				u = translate("second")
			elseif u:match("^m") then
				u = translate("minute")
			elseif u:match("^h") then
				u = translate("hour")
			elseif u:match("^d") then
				u = translate("day")
			end
			if burst and burst > 0 then
				return translatef("<var>%d</var> pkts. per <var>%s</var>, \
				    burst <var>%d</var> pkts.", l, u, burst)
			else
				return translatef("<var>%d</var> pkts. per <var>%s</var>", l, u)
			end
		end
	end
end

function fmt_target(x, dest)
	if dest and #dest > 0 then
		if x == "ACCEPT" then
			return translate("Accept forward")
		elseif x == "REJECT" then
			return translate("Refuse forward")
		elseif x == "NOTRACK" then
			return translate("Do not track forward")
		else --if x == "DROP" then
			return translate("Discard forward")
		end
	else
		if x == "ACCEPT" then
			return translate("Accept input")
		elseif x == "REJECT" then
			return translate("Refuse input")
		elseif x == "NOTRACK" then
			return translate("Do not track input")
		else --if x == "DROP" then
			return translate("Discard input")
		end
	end
end


function opt_enabled(s, t, ...)
	if t == luci.cbi.Button then
		local o = s:option(t, "__enabled")
		function o.render(self, section)
			if self.map:get(section, "enabled") ~= "0" then
				self.title      = translate("Rule is enabled")
				self.inputtitle = translate("Disable")
				self.inputstyle = "reset"
			else
				self.title      = translate("Rule is disabled")
				self.inputtitle = translate("Enable")
				self.inputstyle = "apply"
			end
			t.render(self, section)
		end
		function o.write(self, section, value)
			if self.map:get(section, "enabled") ~= "0" then
				self.map:set(section, "enabled", "0")
			else
				self.map:del(section, "enabled")
			end
		end
		return o
	else
		local o = s:option(t, "enabled", ...)
		      o.enabled = ""
			  o.disabled = "0"
		      o.default = o.enabled
		return o
	end
end

function opt_name(s, t, ...)
	local o = s:option(t, "name", ...)

	function o.cfgvalue(self, section)
		return self.map:get(section, "name") or
			self.map:get(section, "_name") or "-"
	end

	function o.write(self, section, value)
		if value ~= "-" then
			self.map:set(section, "name", value)
			self.map:del(section, "_name")
		else
			self:remove(section)
		end
	end

	function o.remove(self, section)
		self.map:del(section, "name")
		self.map:del(section, "_name")
	end

	return o
end
