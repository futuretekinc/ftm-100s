module("luci.controller.davfs2", package.seeall)
 
function index()
   if not nixio.fs.access("/etc/config/davfs2") then
      return
   end
 
   local page
 
   page = entry({"admin", "services", "davfs2"}, 
                cbi("davfs2"), 
                _("WebDAV Client"))
   page.i18n = "davfs2"
   page.dependent = true
end
