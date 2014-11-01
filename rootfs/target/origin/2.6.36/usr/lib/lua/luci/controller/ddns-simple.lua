module("luci.controller.ddns-simple", package.seeall)

function index()
   if not nixio.fs.access("/etc/config/ddns") then
      return
   end
        
   local page

   page = entry({"admin", "services", "ddns"}, cbi("ddns-simple"), _("DDNS"))
   page.i18n = "ddns"
   page.dependent = true
end
