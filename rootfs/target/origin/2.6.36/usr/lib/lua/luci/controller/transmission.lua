module("luci.controller.transmission", package.seeall)
 
function index()
   if not nixio.fs.access("/etc/config/transmission") then
      return
   end
 
   local page
 
   page = entry({"admin", "services", "transmission"}, 
                cbi("transmission"), 
                _("Torrent"))
   page.i18n = "transmission"
   page.dependent = true
end
