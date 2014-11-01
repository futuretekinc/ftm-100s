-- Map( config, title, description )
-- where config is the name of the config file in /etc/config,
-- also the name of the init.d file in /etc/init.d
m = Map("minidlna-gui", translate("DLNA Server"),
        translate("Minidlna Server"))

--
-- Section: minidlna
--
s = m:section(NamedSection, "dlna", "minidlna",
              translate("dlna"))
s.anonymous=true

s:tab("general", translate("General Settings"))
s:tab("advanced", translate("Advanced Settings"))

o = s:taboption("general", Flag, "enable", translate("Enable"))
o.rmempty=false

o = s:taboption("general", Value, "port", translate("Port"),
             translate("port for HTTP traffic"))
o.datatype='port'

o = s:taboption("general", Value, "network_interface", translate("Network Interface"),
             translate("network interface to bind to"))
o.datatype='string'

o = s:taboption("general", Value, "media_dir", translate("Media Directory"),
             translate("set this to the directory you want scanned"))
o.datatype='directory'

o = s:taboption("general", Value, "friendly_name", translate("Server Name"))
o.datatype='string'

o = s:taboption("advanced", Value, "album_art_names", translate("Album Art Names"),
             translate("list of file names to check for when searching for album art"))
o.datatype='string'

o = s:taboption("advanced", ListValue, "inotify", translate("Enable iNotify"),
             translate("enable monitoring to automatically discover new files"))
o:value( 'no', 'No' );
o:value( 'yes', 'Yes' );

o = s:taboption("advanced", ListValue, "enable_tivo", translate("Tivo Enable"),
             translate("enable support for streaming .jpg and .mp3 files to a TiVo supporting HMO"))
o:value( 'no', 'No' );
o:value( 'yes', 'Yes' );

o = s:taboption("advanced", ListValue, "strict_dlna", translate("Strict DLNA"),
             translate("allow server-side downscaling of very large JPEG images"))
o:value( 'no', 'No' );
o:value( 'yes', 'Yes' );

o = s:taboption("advanced", Value, "notify_interval", translate("Notify Interval"))
o.datatype='uinteger'

o = s:taboption("advanced", Value, "serial", translate("Serial Number"))
o.datatype='string'

o = s:taboption("advanced", Value, "model_number", translate("Model Number"))
o.datatype='string'

o = s:taboption("advanced", ListValue, "enable_livetv", translate("Enable LiveTV"))
o:value( 'no', 'No' );
o:value( 'yes', 'Yes' );

o = s:taboption("advanced", ListValue, "enable_internet_video", translate("Enable Internet Video"))
o:value( 'no', 'No' );
o:value( 'yes', 'Yes' );

return m

