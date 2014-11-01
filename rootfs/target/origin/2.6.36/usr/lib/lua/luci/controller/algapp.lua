module("luci.controller.algapp", package.seeall)
 
function index()
   if not nixio.fs.access("/etc/config/algapp") then
      return
   end
 
   local page
 
   page = entry({"admin", "services", "algapp"}, 
                cbi("algapp"), 
                _("ALG"))
   page.i18n = "algapp"
   page.dependent = true
end
