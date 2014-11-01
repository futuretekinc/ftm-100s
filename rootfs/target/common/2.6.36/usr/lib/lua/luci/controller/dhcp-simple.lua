module("luci.controller.dhcp-simple", package.seeall)

function index()
   local page
   page = entry({"admin", "services", "dhcp"}, 
		cbi("dhcp-simple"), 
		_("DHCP Server"))
   page.i18n = "dhcp"
   page.dependent = true
end
