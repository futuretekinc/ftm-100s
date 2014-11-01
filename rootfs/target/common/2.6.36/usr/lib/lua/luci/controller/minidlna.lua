module("luci.controller.minidlna", package.seeall)
 
function index()
   if not nixio.fs.access("/etc/config/minidlna-gui") then
      return
   end
 
   local page
 
   page = entry({"admin", "services", "minidlna"}, 
                cbi("minidlna"), 
                _("DLNA Server"))
   page.i18n = "minidlna"
   page.dependent = true
end
