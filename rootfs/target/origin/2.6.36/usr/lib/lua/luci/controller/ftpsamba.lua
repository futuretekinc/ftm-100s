module("luci.controller.ftpsamba", package.seeall)

function index()
   if not nixio.fs.access("/etc/config/ftpsamba") then
      return
   end

   local page
	
   page = entry({"admin", "services", "ftpsamba"}, 
		cbi("ftpsamba"), 
		_("FTP/SAMBA"))
   page.i18n = "ftpsamba"
   page.dependent = true
end
