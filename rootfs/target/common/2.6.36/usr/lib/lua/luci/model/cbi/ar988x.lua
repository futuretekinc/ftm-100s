local lanip = require ("luci.model.uci").cursor().get("network","lan","ipaddr") or "192.168.1.1"

m = Map("wireless", "QCA 11AC Wireless Configuration - [5GHz - 11ac/n/a]", "")

s = m:section(NamedSection, "wlan0", "wifi-device", translate("WiFi Offload Mode (WFO)"))
--o = s:option(Flag, "wfo_ar9880", translate("Enabled WFO"), "Once WFO applied, please reboot system!")

o = s:option(ListValue, "mode_id", translate("MODE_ID"),
        --translate("Once the MODE_ID has been change, please reboot by clicking this link:  <a href=\"http://" .. lanip .. ":9091/\" target=\"_blank\">Reboot System</a>"))
        translate("Once the MODE_ID has been change, please reboot by clicking this link: <a href=\"%s\">Reboot System</a>."):format(luci.dispatcher.build_url("admin", "system", "reboot")))

o:value( '-1', '[mode -1] – Reserved Mode' )
o:value( '0', '[mode 0] – All off' )
o:value( '1', '[mode 1] – HW NAT enabled + WIFI (QCA driver)' )
o:value( '2', '[mode 2] – L2TP enabled' )
o:value( '3', '[mode 3] - IPSec disabled: WIFI (QCA driver)' )
o:value( '4', '[mode 4] - IPSec (PE) + WIFI (QCA driver)' )
o:value( '5', '[mode 5] - IPSec on A9 (crypto accl) + WIFI (QCA driver)' )
o:value( '6', '[mode 6] - SW NAT Enabled + WIFI (QCA driver)' )
o:value( '7', '[mode 7] - IPMC + WIFI (QCA driver)' )
o:value( '8', '[mode 8]  - WFO on (PE offload)' )
o:value( '9', '[mode 9] - HW NAT + QCA WFO (PE offload)' )
o:value( '10', '[mode 10] - L2TP + QCA WFO (PE offload)' )
o:value( '11', '[mode 11] - IPMC + QCA WFO (PE offload) ' )
o:value( '12', '[mode 12] - IPSec on A9 (crypto accl) + QCA WFO on (PE offload)' )
o:value( '13', '[mode 13] - PPPoE + QCA WFO (PE offload)' )
o:value( '14', '[mode 14] - IPSec (on Tensillica) + WIFI (QCA Driver on A9)' )
o.rmempty=false


s = m:section(NamedSection, "wlan0", "wifi-device", translate("Start Mode"))
o = s:option(ListValue, "start_mode", translate("AP Start Mode"))
o.widget = "radio" 
o.orientation = "horizontal"
o:value("0", translate("Single"))
o:value("1", translate("Dual Band Concurrent"))


s = m:section(NamedSection, "wlan0", "wifi-device", translate("Basic Settings"))
s.anonymous=true

s:tab("radio_1", translate("11AC/Radio Settings"))
s:tab("advanced", translate("Advanced Settings"))

--
-- 11ac/n/a 5GHz
--

st = s:taboption("radio_1", DummyValue, "__status", translate("Status"))
st.template = "admin_network/wifi_status"
st.ifname   = "wlan0.network1"

o = s:taboption("radio_1", Flag, "disabled", translate("Radio Disabled"))
o.rmempty=false

o = s:taboption("radio_1", ListValue, "hwmode", translate("Wireless Network Mode"))
o:value( '11ACVHT80', '802.11AC/N/A-Mixed' )
o:value( '11NAHT40MINUS', '802.11A/N-Mixed' )
o:value( '11A', '802.11A only' )

htmode = s:taboption("radio_1", ListValue, "htmode", translate("Channel Bandwidth"))
htmode:depends("hwmode", "11NAHT40MINUS")
htmode:depends("hwmode", "11NAHT40PLUS")
htmode:depends("hwmode", "11ACVHT80")
htmode:value("HT80", "80MHz")
htmode:value("HT40", "20/40MHz")
htmode:value("HT20", "20MHz")

o = s:taboption("radio_1", ListValue, "ext_channel", translate("Extension Channel"))
--o:value( 'auto', 'Auto' )
o:depends("htmode", "HT80")
o:depends("htmode", "HT40")
o:value( 'MINUS', 'Lower' )
o:value( 'PLUS', 'Upper' )

o = s:taboption("radio_1", ListValue, "channel", translate("Wireless Channel"))
--o:depends("htmode", "HT20")
o:value( '11na', 'Auto' )
o:value( '36', '36 (5.180GHz)' )
o:value( '40', '40 (5.200GHz)' )
o:value( '44', '44 (5.220GHz)' )
o:value( '48', '48 (5.240GHz)' )
--o:value( '52', '52 (5.260GHz)' )
--o:value( '56', '56 (5.280GHz)' )
--o:value( '60', '60 (5.300GHz)' )
--o:value( '64', '64 (5.320GHz)' )
--o:value( '100', '100 (5.500GHz)' )
--o:value( '104', '104 (5.520GHz)' )
--o:value( '108', '108 (5.540GHz)' )
--o:value( '112', '112 (5.560GHz)' )
--o:value( '116', '116 (5.580GHz)' )
--o:value( '132', '132 (5.660GHz)' )
--o:value( '136', '136 (5.680GHz)' )
--o:value( '140', '140 (5.700GHz)' )
o:value( '149', '149 (5.745GHz)' )
o:value( '153', '153 (5.765GHz)' )
o:value( '157', '157 (5.785GHz)' )
o:value( '161', '161 (5.805GHz)' )
o:value( '165', '165 (5.825GHz)' )

o = s:taboption("radio_1", Value, "ssid", translate("SSID") )
o.rmempty=false

o = s:taboption("radio_1", Flag, "hidden", translate("Hide SSID"))
o.rmempty=false

o = s:taboption("radio_1", Value, "txpower", translate("Default Transmit Power"), "dBm")
o.rmempty=false

--[[
o = s:taboption("radio_1", Flag, "uapsd", translate("Enable U-APSD"))
o.rmempty=false

o = s:taboption("radio_1", Flag, "ssid_isolate", translate("Enable SSID Isolation"))
o.rmempty=false
]]--

--
-- 2.4GHz Advanced Settings
--

o = s:taboption("advanced", Value, "beacon_int", translate("Beacon Interval"),
             translate("Milliseconds, Range: 20 - 1023, Default:100"))
o.datatype = "range(20,1023)"

o = s:taboption("advanced", Value, "dtim_int", translate("DTIM Interval"),
             translate("Range: 1 - 255, Default: 2"))
o.datatype = "range(1,255)"

o = s:taboption("advanced", Value, "rts_thr", translate("RTS Threshold"),
             translate("Range: 256 - 2346, Default: 2346"))
o.datatype = "range(256,2346)"

o = s:taboption("advanced", Value, "frag_thr", translate("Fragmentation Threshold"),
             translate("Range: 257 - 2346, Default: 2346"))
o.datatype = "range(257,2346)"

o = s:taboption("advanced", ListValue, "preamble", translate("Preamble Mode"))
o:value( 'long', 'Long' )
o:value( 'short', 'Short' )

o = s:taboption("advanced", ListValue, "protection", translate("Protection Mode"))
o:value( 'none', 'None' )
o:value( 'CTS', 'CTS-to-Self Protection' )

o = s:taboption("advanced", Value, "short_retry", translate("Short Retry Limit"),
             translate("Range: 0 - 128, Default: 16"))
o.datatype = "range(0,128)"

o = s:taboption("advanced", Value, "long_retry", translate("Long Retry Limit"),
             translate("Range: 0 - 128, Default: 16"))
o.datatype = "range(0,128)"

--s = m:section(TypedSection, "wifi-iface", translate("Wireless Security"))
--s.anonymous=true

----------------------- Interface -----------------------
s = m:section(NamedSection, "wlan0", "wifi-iface", translate("Interface Configuration"))
ifsection = s
s.addremove = false
s.anonymous = true
s.defaults.device = "wlan0"

s:tab("general", translate("General Setup"))
s:tab("encryption", translate("Wireless Security"))
s:tab("macfilter", translate("MAC-Filter"))
s:tab("advanced", translate("Advanced Settings"))


-- s = m:section(NamedSection, "wlan0", "wifi-iface", translate("Wireless Security"))
-- s.anonymous=true

-- Set the access policy of ACL table.
-- Value:
-- 0: Disable this function
-- 1: Allow all entries of ACL table to associate AP
-- 2: Reject all entries of ACL table to associate AP

        mp = s:taboption("macfilter", ListValue, "macpolicy", translate("MAC-Address Filter"))
        mp:value("0", translate("Disable"))
        mp:value("1", translate("Allow listed only"))
        mp:value("2", translate("Allow all except listed"))

        ml = s:taboption("macfilter", DynamicList, "maclist", translate("MAC-List"), "[MAC address], e.g. 00:11:22:33:44:55")
        ml.datatype = "macaddr"
        ml:depends({macpolicy="1"})
        ml:depends({macpolicy="2"})

o = s:taboption("encryption", ListValue, "auth", translate("Encryption"))

o:value("open", "No Encryption")
o:value("wep", "WEP-64 or 128 bit hardware key")
o:value("wpa", "WPA-PSK")
o:value("wpa2", "WPA2-PSK")
o:value("wpawpa2", "WPA/WPA2-PSK Mixed")

o = s:taboption("encryption", ListValue,"encryption",translate("Cipher"))
--o:depends({auth="wep"})
o:depends({auth="wpa"})
o:depends({auth="wpa2"})
o:depends({auth="wpawpa2"})
-- o:value("auto",    "Auto",    {auth="wpa"}, {auth="wpa2"}, {auth="wpawpa2"})
o:value("CCMP",     "Force CCMP (AES)",     {auth="wpa"}, {auth="wpa2"}, {auth="wpawpa2"})
o:value("TKIP",     "Force TKIP",     {auth="wpa"}, {auth="wpa2"}, {auth="wpawpa2"})
o:value("CCMP TKIP",     "Force TKIP and CCMP (AES)",     {auth="wpa"}, {auth="wpa2"}, {auth="wpawpa2"})
-- o:value("tkip",    "TKIP",    {hwmode="11bg", auth="wpa"}, {hwmode="11bg", auth="wpa2"}, {hwmode="11bg", auth="wpawpa2"})
-- o:value("tkip",    "TKIP", {auth="wpawpa2"})

o:value("64-bit",  "64-bit",  {auth="wep"})
o:value("128-bit", "128-bit", {auth="wep"})

o = s:taboption("encryption", ListValue, "wep_mode", translate("MODE"))
o:depends({auth="wep"})
-- iwconfig $device authmode 1/2
o:value("1", "Open")
o:value("2","Shared")

o = s:taboption("encryption", Value,"wpapsk",translate("Password"))
o.datatype = "wpakey"
o.rmempty = true
o.password = true

o:depends({auth="wpa"})
o:depends({auth="wpa2"})
o:depends({auth="wpawpa2"})

o = s:taboption("encryption", Value,"rekey",translate("Rekey Interval"), "Seconds")
o.rmempty = true
o:depends({auth="wpa"})
o:depends({auth="wpa2"})
o:depends({auth="wpawpa2"})


o = s:taboption("encryption", ListValue,"wep_key",translate("Used Key Slot"))
o:depends({auth="wep"})
o:value("1", "Key #1")
o:value("2", "Key #2")
o:value("3", "Key #3")
o:value("4", "Key #4")

o = s:taboption("encryption", Value,"key1",translate("Key #1"))
o.datatype = "wepkey"
o:depends({auth="wep"})
o.rmempty = true
o.password = true

o = s:taboption("encryption", Value,"key2",translate("Key #2"))
o.datatype = "wepkey"
o:depends({auth="wep"})
o.rmempty = true
o.password = true

o = s:taboption("encryption", Value,"key3",translate("Key #3"))
o.datatype = "wepkey"
o:depends({auth="wep"})
o.rmempty = true
o.password = true

o = s:taboption("encryption", Value,"key4",translate("Key #4"))
o.datatype = "wepkey"
o:depends({auth="wep"})
o.rmempty = true
o.password = true

return m
