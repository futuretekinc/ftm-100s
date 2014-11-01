module("luci.controller.ar988x", package.seeall)

function index()
   if not nixio.fs.access("/etc/config/wireless") then
      return
   end

   local page
	
   page = entry({"admin", "network", "ar988x"},
                arcombine(template("admin_network/wifi_ar988x"), cbi("admin_network/wifi")),
                _("QCA 11AC"))
   page.i18n = "ar988x"
   page.dependent = true

   entry({"admin", "network", "ar988x", "overview"},
                arcombine(template("admin_network/wifi_ar988x"), cbi("admin_network/wifi")),
                _("Wireless Overview"), 10).leaf = true

   entry({"admin", "network", "ar988x", "radio0"},
                arcombine(cbi("ar988x"), cbi("ar988x")),
                _("5GHz(11ac/n/a)"), 20).leaf = true

   entry({"admin", "network", "ar988x", "radio1"},
                 cbi("ar9380-details"),
                _("2.4GHz(11n/g/b)"), 30).leaf = true

end
