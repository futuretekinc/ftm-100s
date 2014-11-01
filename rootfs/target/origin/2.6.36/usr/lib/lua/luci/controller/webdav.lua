module("luci.controller.webdav", package.seeall)

function index()
   if not nixio.fs.access("/etc/config/webdav") then
      return
   end

   local page
	
   page = entry({"admin", "services", "webdav"}, 
		cbi("webdav"), 
		_("WebDAV Server"))
   page.i18n = "webdav"
   page.dependent = true
end
