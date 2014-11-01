-- Map( config, title, description )
-- where config is the name of the config file in /etc/config,
-- also the name of the init.d file in /etc/init.d

local lanip = require ("luci.model.uci").cursor().get("network","lan","ipaddr") or "192.168.1.1"

m = Map("transmission", translate("Torrent Server"), 
	translate("Access the Bit Torrent Client web page by clicking this link:  <a href=\"http://" .. lanip .. ":9091/\" target=\"_blank\">http://".. lanip .. ":9091</a>"))

--
-- Section: transmission
--
s = m:section(TypedSection, "transmission")
s.anonymous=true

s:tab("general", translate("General"))
s:tab("bandwidth", translate("Bandwidth"))
s:tab("scheduling", translate("Scheduling"))
s:tab("peer", translate("Peer Management"))
s:tab("btpeerports", translate("Transmission Peer Ports"))
s:tab("remote", translate("Remote Control"))
s:tab("advanced", translate("Advanced"))

o = s:taboption("general", Flag, "enabled", translate("Enable"))
o.rmempty=false

o = s:taboption("advanced", Value, "config_dir", translate("Configuration Directory"))
o.datatype='string'

o = s:taboption("advanced", Value, "run_daemon_as_user", translate("Which user runs the daemon"))
o.datatype='string'

o = s:taboption("bandwidth", ListValue, "alt_speed_enabled", translate("Override Normal Speed Limits"))
o:value( 'true', 'True' );
o:value( 'false', 'False' );

o = s:taboption("bandwidth", Value, "alt_speed_down", translate("Alternate Download Speed in KByte/s"))
o.datatype='uinteger'

o = s:taboption("bandwidth", Value, "alt_speed_up", translate("Alternate Upload Speed in KByte/s"))
o.datatype='uinteger'

o = s:taboption("scheduling", ListValue, "alt_speed_time_enabled", translate("Scheduled Times For Alternate Speed Limits"))
o:value( 'true', 'True' );
o:value( 'false', 'False' );

o = s:taboption("scheduling", ListValue, "alt_speed_time_day", translate("On Days"))
o:value( '127', 'Everyday' );
o:value( '62', 'Weekdays' );
o:value( '65', 'Weekends' );
o:value( '1', 'Sunday' );
o:value( '2', 'Monday' );
o:value( '4', 'Tuesday' );
o:value( '8', 'Wednesday' );
o:value( '16', 'Thursday' );
o:value( '32', 'Friday' );
o:value( '64', 'Saturday' );

o = s:taboption("scheduling", ListValue, "alt_speed_time_begin", translate("Begin Time"))
o:value( '0', '0:00' );
o:value( '15', '0:15' );
o:value( '30', '0:30' );
o:value( '45', '0:45' );
o:value( '60', '1:00' );
o:value( '75', '1:15' );
o:value( '90', '1:30' );
o:value( '105', '1:45' );
o:value( '120', '2:00' );
o:value( '135', '2:15' );
o:value( '150', '2:30' );
o:value( '165', '2:45' );
o:value( '180', '3:00' );
o:value( '195', '3:15' );
o:value( '210', '3:30' );
o:value( '225', '3:45' );
o:value( '240', '4:00' );
o:value( '255', '4:15' );
o:value( '270', '4:30' );
o:value( '285', '4:45' );
o:value( '300', '5:00' );
o:value( '315', '5:15' );
o:value( '330', '5:30' );
o:value( '345', '5:45' );
o:value( '360', '6:00' );
o:value( '375', '6:15' );
o:value( '390', '6:30' );
o:value( '405', '6:45' );
o:value( '420', '7:00' );
o:value( '435', '7:15' );
o:value( '450', '7:30' );
o:value( '465', '7:45' );
o:value( '480', '8:00' );
o:value( '495', '8:15' );
o:value( '510', '8:30' );
o:value( '525', '8:45' );
o:value( '540', '9:00' );
o:value( '555', '9:15' );
o:value( '570', '9:30' );
o:value( '585', '9:45' );
o:value( '600', '10:00' );
o:value( '615', '10:15' );
o:value( '630', '10:30' );
o:value( '645', '10:45' );
o:value( '660', '11:00' );
o:value( '675', '11:15' );
o:value( '690', '11:30' );
o:value( '705', '11:45' );
o:value( '720', '12:00' );
o:value( '735', '12:15' );
o:value( '750', '12:30' );
o:value( '765', '12:45' );
o:value( '780', '13:00' );
o:value( '795', '13:15' );
o:value( '810', '13:30' );
o:value( '825', '13:45' );
o:value( '840', '14:00' );
o:value( '855', '14:15' );
o:value( '870', '14:30' );
o:value( '885', '14:45' );
o:value( '900', '15:00' );
o:value( '915', '15:15' );
o:value( '930', '15:30' );
o:value( '945', '15:45' );
o:value( '960', '16:00' );
o:value( '975', '16:15' );
o:value( '990', '16:30' );
o:value( '1005', '16:45' );
o:value( '1020', '17:00' );
o:value( '1035', '17:15' );
o:value( '1050', '17:30' );
o:value( '1065', '17:45' );
o:value( '1080', '18:00' );
o:value( '1095', '18:15' );
o:value( '1110', '18:30' );
o:value( '1125', '18:45' );
o:value( '1140', '19:00' );
o:value( '1155', '19:15' );
o:value( '1170', '19:30' );
o:value( '1185', '19:45' );
o:value( '1200', '20:00' );
o:value( '1215', '20:15' );
o:value( '1230', '20:45' );
o:value( '1260', '21:00' );
o:value( '1275', '21:15' );
o:value( '1290', '21:30' );
o:value( '1305', '21:45' );
o:value( '1320', '22:00' );
o:value( '1335', '22:15' );
o:value( '1350', '22:30' );
o:value( '1365', '22:45' );
o:value( '1380', '23:00' );
o:value( '1395', '23:15' );
o:value( '1410', '23:30' );
o:value( '1425', '23:45' );

o = s:taboption("scheduling", ListValue, "alt_speed_time_end", translate("End Time"))
o:value( '0', '0:00' );
o:value( '15', '0:15' );
o:value( '30', '0:30' );
o:value( '45', '0:45' );
o:value( '60', '1:00' );
o:value( '75', '1:15' );
o:value( '90', '1:30' );
o:value( '105', '1:45' );
o:value( '120', '2:00' );
o:value( '135', '2:15' );
o:value( '150', '2:30' );
o:value( '165', '2:45' );
o:value( '180', '3:00' );
o:value( '195', '3:15' );
o:value( '210', '3:30' );
o:value( '225', '3:45' );
o:value( '240', '4:00' );
o:value( '255', '4:15' );
o:value( '270', '4:30' );
o:value( '285', '4:45' );
o:value( '300', '5:00' );
o:value( '315', '5:15' );
o:value( '330', '5:30' );
o:value( '345', '5:45' );
o:value( '360', '6:00' );
o:value( '375', '6:15' );
o:value( '390', '6:30' );
o:value( '405', '6:45' );
o:value( '420', '7:00' );
o:value( '435', '7:15' );
o:value( '450', '7:30' );
o:value( '465', '7:45' );
o:value( '480', '8:00' );
o:value( '495', '8:15' );
o:value( '510', '8:30' );
o:value( '525', '8:45' );
o:value( '540', '9:00' );
o:value( '555', '9:15' );
o:value( '570', '9:30' );
o:value( '585', '9:45' );
o:value( '600', '10:00' );
o:value( '615', '10:15' );
o:value( '630', '10:30' );
o:value( '645', '10:45' );
o:value( '660', '11:00' );
o:value( '675', '11:15' );
o:value( '690', '11:30' );
o:value( '705', '11:45' );
o:value( '720', '12:00' );
o:value( '735', '12:15' );
o:value( '750', '12:30' );
o:value( '765', '12:45' );
o:value( '780', '13:00' );
o:value( '795', '13:15' );
o:value( '810', '13:30' );
o:value( '825', '13:45' );
o:value( '840', '14:00' );
o:value( '855', '14:15' );
o:value( '870', '14:30' );
o:value( '885', '14:45' );
o:value( '900', '15:00' );
o:value( '915', '15:15' );
o:value( '930', '15:30' );
o:value( '945', '15:45' );
o:value( '960', '16:00' );
o:value( '975', '16:15' );
o:value( '990', '16:30' );
o:value( '1005', '16:45' );
o:value( '1020', '17:00' );
o:value( '1035', '17:15' );
o:value( '1050', '17:30' );
o:value( '1065', '17:45' );
o:value( '1080', '18:00' );
o:value( '1095', '18:15' );
o:value( '1110', '18:30' );
o:value( '1125', '18:45' );
o:value( '1140', '19:00' );
o:value( '1155', '19:15' );
o:value( '1170', '19:30' );
o:value( '1185', '19:45' );
o:value( '1200', '20:00' );
o:value( '1215', '20:15' );
o:value( '1230', '20:45' );
o:value( '1260', '21:00' );
o:value( '1275', '21:15' );
o:value( '1290', '21:30' );
o:value( '1305', '21:45' );
o:value( '1320', '22:00' );
o:value( '1335', '22:15' );
o:value( '1350', '22:30' );
o:value( '1365', '22:45' );
o:value( '1380', '23:00' );
o:value( '1395', '23:15' );
o:value( '1410', '23:30' );
o:value( '1425', '23:45' );

o = s:taboption("advanced", Value, "bind_address_ipv4", translate("Bind Address IPv4"))
o.datatype='ipaddr'

o = s:taboption("advanced", Value, "bind_address_ipv6", translate("Bind Address IPv6"))
o.datatype='ipaddr'

o = s:taboption("peer", ListValue, "blocklist_enabled", translate("Enable BlockList"))
o:value( 'true', 'True' );
o:value( 'false', 'False' );

o = s:taboption("peer", Value, "blocklist_url", translate("BlockList URL"))
o.datatype='string'

o = s:taboption("advanced", Value, "cache_size_mb", translate("Cache Size in MB"))
o.datatype='uinteger'

o = s:taboption("peer", ListValue, "dht_enabled", translate("Enable Distributed HashTable"))
o:value( 'true', 'True' );
o:value( 'false', 'False' );

o = s:taboption("general", Value, "download_dir", translate("Download Directory"))
o.datatype='string'

o = s:taboption("peer", ListValue, "encryption", translate("Encryption"))
o:value( '0', 'Off' );
o:value( '1', 'Preferred' );
o:value( '2', 'Forced' );

o = s:taboption("advanced", ListValue, "idle_seeding_limit_enabled", translate("Enable Idle Seeding Limit"))
o:value( 'true', 'True' );
o:value( 'false', 'False' );

o = s:taboption("advanced", Value, "idle_seeding_limit", translate("Idle Seeding Limit"))
o.datatype='uinteger'

o = s:taboption("advanced", ListValue, "incomplete_dir_enabled", translate("Enable Incomplete Directory"))
o:value( 'true', 'True' );
o:value( 'false', 'False' );

o = s:taboption("advanced", Value, "incomplete_dir", translate("Incomplete Directory"))
o.datatype='string'

o = s:taboption("advanced", ListValue, "lazy_bitfield_enabled", translate("Enable Lazy Bitfield"))
o:value( 'true', 'True' );
o:value( 'false', 'False' );

o = s:taboption("advanced", ListValue, "lpd_enabled", translate("Enable LPD"))
o:value( 'true', 'True' );
o:value( 'false', 'False' );

o = s:taboption("advanced", Value, "message_level", translate("Message Level"))
o.datatype='uinteger'

o = s:taboption("advanced", Value, "open_file_limit", translate("Max number of open files"))
o.datatype='uinteger'

o = s:taboption("peer", Value, "peer_limit_global", translate("Max number of connected peers"))
o.datatype='uinteger'

o.rmempty=false
o = s:taboption("peer", Value, "peer_limit_per_torrent", translate("Max number of connected peers for single torrent"))
o.datatype='uinteger'

o = s:taboption("btpeerports", Value, "peer_port", translate("Port To Listen On For Incoming Peer Connections"))
o.datatype='uinteger'

o = s:taboption("btpeerports", Flag, "peer_port_random_on_start", translate("Assign Random Peer Port"))
o.rmempty=false

o = s:taboption("btpeerports", Value, "peer_port_random_low", translate("Lowest Port Number For Random Peer Port"))
o.datatype='uinteger'

o = s:taboption("btpeerports", Value, "peer_port_random_high", translate("Highest Port Number For Random Peer Port"))
o.datatype='uinteger'

o = s:taboption("peer", Flag, "peer_socket_tos", translate("Enable Type Of Service"))
o.rmempty=false

o = s:taboption("peer", ListValue, "pex_enabled", translate("Enable Peer EXchange"))
o:value( 'true', 'True' );
o:value( 'false', 'False' );

o = s:taboption("btpeerports", ListValue, "port_forwarding_enabled", translate("Enable Port Forwarding"))
o:value( 'true', 'True' );
o:value( 'false', 'False' );

o = s:taboption("advanced", Flag, "preallocation", translate("Enable PreAllocation"))
o.rmempty=false

o = s:taboption("advanced", Flag, "prefetch_enabled", translate("Enable PreFetch"))
o.rmempty=false

o = s:taboption("scheduling", ListValue, "ratio_limit_enabled", translate("Enable Ratio Limit"))
o:value( 'true', 'True' );
o:value( 'false', 'False' );

o = s:taboption("scheduling", Value, "ratio_limit", translate("Ratio Of Upload To Download"))
o.datatype='ufloat'

o = s:taboption("advanced", ListValue, "rename_partial_files", translate("Rename Partial Files"))
o:value( 'true', 'True' );
o:value( 'false', 'False' );

o = s:taboption("remote", ListValue, "rpc_enabled", translate("Enable RPC"))
o:value( 'true', 'True' );
o:value( 'false', 'False' );

o = s:taboption("remote", Value, "rpc_bind_address", translate("RPC Bind Address"))
o.datatype='ipaddr'

o = s:taboption("remote", Value, "rpc_url", translate("RPC URL"))
o.datatype='string'

o = s:taboption("remote", Value, "rpc_port", translate("RPC Port"))
o.datatype='port'

o = s:taboption("remote", ListValue, "rpc_authentication_required", translate("Enable RPC Authentication"))
o:value( 'true', 'True' );
o:value( 'false', 'False' );

o = s:taboption("remote", Value, "rpc_username", translate("RPC Username"))
o.datatype='string'

o = s:taboption("remote", Value, "rpc_password", translate("RPC Password"))
o.password= true

o = s:taboption("remote", ListValue, "rpc_whitelist_enabled", translate("Enable RPC White List"))
o:value( 'true', 'True' );
o:value( 'false', 'False' );

o = s:taboption("remote", Value, "rpc_whitelist", translate("RPC White List"))
o.datatype='string'

o = s:taboption("advanced", ListValue, "script_torrent_done_enabled", translate("Enable Script for Torrent Done"))
o:value( 'true', 'True' );
o:value( 'false', 'False' );

o = s:taboption("advanced", Value, "script_torrent_done_filename", translate("Filename of Torrent Done Script"))
o.datatype='string'

o = s:taboption("bandwidth", ListValue, "speed_limit_down_enabled", translate("Enable Download Speed Limit"))
o:value( 'true', 'True' );
o:value( 'false', 'False' );

o = s:taboption("bandwidth", Value, "speed_limit_down", translate("Download Speed Limit in KBytes/s"))
o.datatype='uinteger'

o = s:taboption("bandwidth", ListValue, "speed_limit_up_enabled", translate("Enable Upload Speed Limit"))
o:value( 'true', 'True' );
o:value( 'false', 'False' );

o = s:taboption("bandwidth", Value, "speed_limit_up", translate("Upload Speed Limit in KBytes/s"))
o.datatype='uinteger'

o = s:taboption("advanced", ListValue, "start_added_torrents", translate("Start Added Torrents"))
o:value( 'true', 'True' );
o:value( 'false', 'False' );

o = s:taboption("advanced", ListValue, "trash_original_torrent_files", translate("Trash Original Torrent Files"))
o:value( 'true', 'True' );
o:value( 'false', 'False' );

o = s:taboption("advanced", Value, "umask", translate("Umask"), translate("Set file mode creation mask in base 10 (NOT octal base)"))
o.datatype='uinteger'

o = s:taboption("advanced", Value, "upload_slots_per_torrent", translate("Number Of Peers Who Can Download A Torrent"))
o.datatype='uinteger'

o = s:taboption("general", ListValue, "watch_dir_enabled", translate("Enables directory watching and autoload"))
o:value( 'true', 'True' );
o:value( 'false', 'False' );

o = s:taboption("general", Value, "watch_dir", translate("Directory to watch for new .torrent files to autoload"))
o.datatype='string'

return m

