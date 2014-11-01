m = Map("wireless", "QCA AR9380 Wireless Configuration - [2.4GHz - 11n/g/b]", "")

-- s = m:section(NamedSection, "wlan1", "wifi-device", translate("WiFi Offload Mode"))
-- o = s:option(Flag, "wfo_ar9880", translate("Enabled WFO"))
-- o.rmempty=false

s = m:section(NamedSection, "wlan1", "wifi-device", translate("Basic Settings"))
s.anonymous=true

s:tab("radio_1", translate("2.4GHz/Radio Settings"))
s:tab("advanced", translate("Advanced Settings"))

--
-- 2.4GHz
--

st = s:taboption("radio_1", DummyValue, "__status", translate("Status"))
st.template = "admin_network/wifi_status"
st.ifname   = "wlan1.network1"

o = s:taboption("radio_1", ListValue, "hwmode", translate("Wireless Network Mode"))
o:value( '11G', '802.11B/G-Mixed' )
o:value( 'pureg', '802.11G only' )
o:value( '11NGHT40MINUS', '802.11B/G/N-Mixed' )
o:value( '11NGHT40PLUS', '802.11N only' )

htmode = s:taboption("radio_1", ListValue, "htmode", translate("Channel Bandwidth"))
htmode:depends("hwmode", "11NGHT40MINUS")
htmode:depends("hwmode", "11NGHT40PLUS")
htmode:value("HT40", "20/40MHz")
htmode:value("HT20", "20MHz")

o = s:taboption("radio_1", ListValue, "ext_channel", translate("Extension Channel"))
--o:value( 'auto', 'Auto' )
o:depends("htmode", "HT40")
o:value( 'MINUS', 'Lower' )
o:value( 'PLUS', 'Upper' )

o = s:taboption("radio_1", ListValue, "channel", translate("Wireless Channel"))
o:value( '11ng', 'Auto' )
o:value( '1', '1 (2.412GHz)' )
o:value( '2', '2 (2.417GHz)' )
o:value( '3', '3 (2.422GHz)' )
o:value( '4', '4 (2.427GHz)' )
o:value( '5', '5 (2.432GHz)' )
o:value( '6', '6 (2.437GHz)' )
o:value( '7', '7 (2.442GHz)' )
o:value( '8', '8 (2.447GHz)' )
o:value( '9', '9 (2.452GHz)' )
o:value( '10', '10 (2.457GHz)' )
o:value( '11', '11 (2.462GHz)' )

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

--s = m:section(TypedSection, "wifi-iface_2", translate("Wireless Security"))
--s.anonymous=true

-- s = m:section(NamedSection, "wlan1", "wifi-iface", translate("Wireless Security"))
-- s.anonymous=true
-- s.addremove = false

----------------------- Interface -----------------------

s = m:section(NamedSection, "wlan1", "wifi-iface", translate("Interface Configuration"))
ifsection = s
s.addremove = false
s.anonymous = true
s.defaults.device = "wlan1"

s:tab("general", translate("General Setup"))
s:tab("encryption", translate("Wireless Security"))
s:tab("macfilter", translate("MAC-Filter"))
s:tab("advanced", translate("Advanced Settings"))

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
--o:value("auto",    "Auto",    {auth="wpa"}, {auth="wpa2"}, {auth="wpawpa2"})
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

