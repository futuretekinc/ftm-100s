-- 
-- Copyright (C) 2012 Cortina Systems, Inc.
-- All rights reserved.
--

require "luci.sys"
require "luci.fs"
m = Map("g2qos", translate("G2 QoS"),
        translate("With <abbr title=\"Quality of Service\">QoS</abbr> you " ..
                "can prioritize network traffic selected by addresses, " ..
                "ports or services."))

--
-- WAN
--
s = m:section(NamedSection, "wan", "g2qos", translate("WAN QoS"))

v = s:option(Flag, "enabled",
	     translate("Enable WAN QoS"))
v.rmempty = false

v = s:option(Value, "upstream",
	     translate("Upstream Bandwidth in Kbps"))
v.datatype = "range(5,1000000)"
v.default = 1000000
v:depends("enabled", 1)

v = s:option(Value, "downstream",
	     translate("Downstream Bandwidth in Kbps"), translate("Range: 5Kbps - 1000000Kbps"))
-- v.datatype = "uinteger"
v.datatype = "range(5,1000000)"
v.default = 1000000
v:depends("enabled", 1)


s = m:section(NamedSection, "wan", "g2qos",
              translate("Queue Mapping (SP/DRR)"))

-- Mode			SP				DRR
-- Priority	7	5	1	0	0	0	0	0
-- Weight	N/A	N/A	N/A	50	30	10	5	5
-- Queue ID	0	1	2	3	4	5	6	7

v = s:option(ListValue, "scheduler", 
	     translate("Scheduling Algorithm"), "PQ stands for the priority queue in SP mode, 7 is the highest and 0 is the lowest.")
v:value("sp", translate("SP - Strict Priority"))
v:value("drr", translate("DRR - Deficit Round Robin"))
v.default = 'sp'
v:depends("enabled", 1)

for i=0,7 do
   v = s:option(DummyValue, "q" .. i .. "_sp", "Q" .. i)
   v:depends("scheduler", "sp")
end

for i=0,7 do
   v = s:option(Value, "q" .. i .. "_drr", "Q" .. i .. " (10%weight)")
   v:depends("scheduler", "drr")
   v.default = "0"
end

v = s:option(Value, "drr_rate",
             translate("Total Rate Limit in Kbps"), translate("Range: 5Kbps - 1000000Kbps"))
v.datatype = "range(5,1000000)"
v:depends("scheduler", "drr")
v.default = 1000000

--
-- Bandwidth Profiles
--
s = m:section(TypedSection, "profile",
	      translate("Bandwidth Profiles"))
s.addremove = true
s.anonymous = true
s.template = "cbi/tblsection"

v = s:option(Value, "name", translate("Profile name"))
v.rmempty = false
function v.validate(self, value, section)
   -- There are probably characters that won't work in the shell
   if ( value:match("^[a-zA-Z][a-zA-Z0-9_]+$") ) then
      return value
   else
      return nil, translate("Profile names must match ^[a-zA-Z][a-zA-Z0-9_]+$")
   end
end

v = s:option(ListValue, "queue", translate("Queue"))
for i=0,7 do
   v:value("" .. i, "Q" .. i)
end
v.default = "1"

--[[
v = s:option(Value, "maxbw",
	     translate("Maximum Bandwidth in Kbps"))
v.rmempty = false
v.datatype = "uinteger"
v.default = 1000000

v = s:option(Value, "minbw",
	     translate("Minimum Bandwidth in Kbps"))
v.rmempty = false
v.datatype = "uinteger"
v.default = 1000000
]]--

v = s:option(Value, "ratelimit",
             translate("Rate Limit in Kbps"))
v.rmempty = false
v.datatype = "uinteger"
v.default = 1000000

--
-- Traffic Classifications
--
s = m:section(TypedSection, "traffic",
	      translate("Traffic Selectors"))
s.addremove = true
s.anonymous = true
-- s.template = "cbi/tblsection"

v = s:option(ListValue, "profile", translate("Bandwidth Profile"))
-- Need to read current list of bandwidth profiles
m.uci:foreach("g2qos", "profile", 
	      function(s)
		 v:value( s.name, s.name )
	      end
	   )

--[[
v = s:option(ListValue, "service", translate("Service"))
-- Need to read the classification database
-- m2 = Map("g2qos_classes", "", "")
m.uci:foreach("g2qos", "classification",
	       function(s)
		  v:value( s.classname, s.menuname )
	       end
	    )
v.default = "any"
]]--

v = s:option(ListValue, "match", translate("Match"))
v:value("ip", "IP")
v:value("macaddr", "MAC Address")
v:value("port", "Port")
-- v:value("vlan", "VLAN ID")
v:value("protocol", "IP Protocol")
v:value("dscp", "DSCP")
v:value("cos", "802.1p")
--v:value("bssid", "BSSID")
v.default = "ip"

v = s:option(Value, "src_ipaddr", translate("Source IP Address"))
v.datatype = 'ipaddr'
v:value("0.0.0.0", "Any")
v.default = '127.0.0.1'
v:depends("match", "ip")

v = s:option(Value, "dst_ipaddr", translate("Dest IP Address"))
v.datatype = 'ipaddr'
v:value("0.0.0.0", "Any")
v.default = '127.0.0.1'
v:depends("match", "ip")

v = s:option(Value, "src_macaddr", translate("Source MAC Address"))
v.datatype = 'macaddr'
v:value("00:00:00:00:00:00", "Any")
v.default = '11:22:33:44:55:66'
v:depends("match", "macaddr")

v = s:option(Value, "dst_macaddr", translate("Dest MAC Address"))
v.datatype = 'macaddr'
v:value("00:00:00:00:00:00", "Any")
v.default = '11:22:33:44:55:66'
v:depends("match", "macaddr")

v = s:option(Value, "src_port", translate("Source Port"))
v:value("any", "Any")
v.default = "any"
v:depends("match", "port")

v = s:option(Value, "dst_port", translate("Dest Port"))
v:value("any", "Any")
v.default = "any"
v:depends("match", "port")

--[[v = s:option(ListValue, "vlan", translate("VLAN"))
v:value("default", "Default VLAN")
v:value("vlan1", "VLAN1")
v:value("vlan2", "VLAN2")
v:value("any", "ANY")
v.default = "default"
v:depends("match", "vlan")
]]--

v = s:option(ListValue, "protocol", translate("Protocol"))
v:value("tcp", "TCP")
v:value("udp", "UDP")
v.default = "tcp"
v:depends("match", "protocol")

--[[
ToS dec	ToS hex	ToS bin	ToS Prec. (bin)	ToS Prec. (dec)	ToS Delay Flag	ToS Throgh-
put Flag	ToS Relia-
bility FLag	DSCP bin	DSCP hex	DSCP dec	DSCP Class
0	0×00	00000000	000	0	0	0	0	000000	0×00	0	none
32	0×20	00100000	001	1	0	0	0	001000	0×08	8	cs1
40	0×28	00101000	001	1	0	1	0	001010	0x0A	10	af11
48	0×30	00110000	001	1	1	0	0	001100	0x0C	12	af12
56	0×38	00111000	001	1	1	1	0	001110	0x0E	14	af13
64	0×40	01000000	010	2	0	0	0	010000	0×10	16	cs2
72	0×48	01001000	010	2	0	1	0	010010	0×12	18	af21
80	0×50	01010000	010	2	1	0	0	010100	0×14	20	af22
88	0×58	01011000	010	2	1	1	0	010110	0×16	22	af23
96	0×60	01100000	011	3	0	0	0	011000	0×18	24	cs3
104	0×68	01101000	011	3	0	1	0	011010	0x1A	26	af31
112	0×70	01110000	011	3	1	0	0	011100	0x1C	28	af32
120	0×78	01111000	011	3	1	1	0	011110	0x1E	30	af33
128	0×80	10000000	100	4	0	0	0	100000	0×20	32	cs4
136	0×88	10001000	100	4	0	1	0	100010	0×22	34	af41
144	0×90	10010000	100	4	1	0	0	100100	0×34	36	af42
152	0×98	10011000	100	4	1	1	0	100110	0×26	38	af43
160	0xA0	10100000	101	5	0	0	0	101000	0×28	40	cs5
184	0xB8	10111000	101	5	1	1	0	101110	0x2E	46	ef
192	0xC0	11000000	110	6	0	0	0	110000	0×30	48	cs6
224	0xE0	11100000	111	7	0	0	0	111000	0×38	56	cs7
--]]

v = s:option(ListValue, "dscp", translate("DSCP Value"))
v:value("0x00", "CS0(0)")
v:value("0x20", "CS1(8)")
v:value("0x28", "AF11(10)")
v:value("0x30", "AF12(12)")
v:value("0x38", "AF13(14)")
v:value("0x40", "CS2(16)")
v:value("0x48", "AF21(18)")
v:value("0x50", "AF22(20)")
v:value("0x58", "AF23(22)")
v:value("0x60", "CS3(24)")
v:value("0x68", "AF31(26)")
v:value("0x70", "AF32(28)")
v:value("0x78", "AF33(30)")
v:value("0x80", "CS4(32)")
v:value("0x88", "AF41(34)")
v:value("0x90", "AF42(36)")
v:value("0x98", "AF43(38)")
v:value("0xA0", "CS5(40)")
v:value("0xB8", "EF(46)")
v:value("0xC0", "CS6(48)")
v:value("0xE0", "CS7(56)")

v.default = '0xE0'
v:depends("match", "dscp")

v = s:option(ListValue, "cos", translate("CoS Value"))
v:value("any", "Any")
for i=0,7 do
   v:value(i,i)
end
v.default = "any"
v:depends("match", "cos")

v = s:option(Value, "vlan", translate("VLAN ID"))
v.default = "100"
v:depends("match", "cos")
v.datatype = "range(1,4095)"


--
-- LAN
--
s = m:section(NamedSection, "lan", "g2qos", translate("LAN QoS"))

v = s:option(Flag, "enabled",
	     translate("Enable QoS for LAN ports"))
v.rmempty = false

v = s:option(ListValue, "cpu_port",
	     translate("CPU Port Classify Using"), "VLAN would cause WebUI breakage!")
v:value("cos", "CoS")
v:value("dscp", "DSCP")
v.default = "cos"
v:depends("enabled", 1)

v = s:option(Value, "vlan", translate("VLAN ID"))
v.default = "100"
v:depends("cpu_port", "cos")
v.datatype = "range(1,4095)"

v = s:option(Value, "lan_ipaddr", translate("LAN IP Address"))
v.optional = false
v.default = "192.168.1.1"
v:depends("cpu_port", "cos")
v.datatype = "ip4addr"

v = s:option(Value, "wan_ipaddr", translate("WAN IP Address"))
v.default = "10.1.1.1"
v:depends("cpu_port", "cos")
v.optional = false
v.datatype = "ip4addr"


--[[
v = s:option(ListValue, "port2",
	     translate("Port 2 Classify Using"))
v:value("cos", "CoS")
v:value("dscp", "DSCP")
v.default = "cos"
v:depends("enabled", 1)

v = s:option(ListValue, "port3",
	     translate("Port 3 Classify Using"))
v:value("cos", "CoS")
v:value("dscp", "DSCP")
v.default = "cos"
v:depends("enabled", 1)

v = s:option(ListValue, "port4",
	     translate("Port 4 Classify Using"))
v:value("cos", "CoS")
v:value("dscp", "DSCP")
v.default = "cos"
v:depends("enabled", 1)
--]]

v = s:option(ListValue, "scheduler", 
	     translate("Scheduling Algorithm"),"PQ stands for the priority queue in SP mode, 7 is the highest and 0 is the lowest.")
v:value("sp", translate("Strict Priority"))
v:value("wrr", translate("Weighted Round Robin"))
v.default = 'sp'
v:depends("enabled", 1)

for i=0,7 do
   v = s:option(DummyValue, "q" .. i .. "_sp", "Q" .. i)
   v:depends("scheduler", "sp")
end

for i=0,7 do
   v = s:option(Value, "q" .. i .. "_wrr", "Q" .. i .. " (10%weight)")
   v:depends("scheduler", "wrr")
   v.default = "0"
end

v = s:option(Value, "wrr_rate",
             translate("Total Rate Limit in bps"), translate("Range: 3125bps - 1000000000bps"))
v.datatype = "range(3125,100000000)"
v:depends("scheduler", "wrr")
v.default = 100000000

--
-- Mapping
--
s = m:section(NamedSection, "mapping", "g2qos", translate("DSCP/CoS Mappings"))

s:tab( "cos", translate("Port CoS Map"))
s:tab( "dscp", translate("Port DSCP Map"))
s:tab( "remark", translate("DSCP Remarking"))

--
-- CoS Mapping
--
v = s:taboption("cos", ListValue, "cos0",
		translate("CoS 0 Queue:"))
for i=0,7 do
   v:value("" .. i, "Q" .. i)
end
v.default = "0"

v = s:taboption("cos", ListValue, "cos1",
		translate("CoS 1 Queue:"))
for i=0,7 do
   v:value("" .. i, "Q" .. i)
end
v.default = "1"

v = s:taboption("cos", ListValue, "cos2",
		translate("CoS 2 Queue:"))
for i=0,7 do
   v:value("" .. i, "Q" .. i)
end
v.default = "2"

v = s:taboption("cos", ListValue, "cos3",
		translate("CoS 3 Queue:"))
for i=0,7 do
   v:value("" .. i, "Q" .. i)
end
v.default = "3"

v = s:taboption("cos", ListValue, "cos4",
		translate("CoS 4 Queue:"))
for i=0,7 do
   v:value("" .. i, "Q" .. i)
end
v.default = "4"

v = s:taboption("cos", ListValue, "cos5",
		translate("CoS 5 Queue:"))
for i=0,7 do
   v:value("" .. i, "Q" .. i)
end
v.default = "5"

v = s:taboption("cos", ListValue, "cos6",
		translate("CoS 6 Queue:"))
for i=0,7 do
   v:value("" .. i, "Q" .. i)
end
v.default = "6"

v = s:taboption("cos", ListValue, "cos7",
		translate("CoS 7 Queue:"))
for i=0,7 do
   v:value("" .. i, "Q" .. i)
end
v.default = "7"

--
-- DSCP Mapping
--
for i=0,63 do
   v = s:taboption("dscp", ListValue, "dscp" .. i,
		   translate("DSCP " .. i .. " Queue:"))
   for i=0,7 do
      v:value("" .. i, "Q" .. i)
   end
   v.default = "1"
end

--
-- Remarking
--

v = s:taboption("remark", Flag, "dscp_enabled",
             translate("Do you want to enable DSCP Remarking?"))
v.rmempty = false

v = s:taboption("remark", ListValue, "cos02dscp",
		translate("Remark DSCP 0 to DSCP:"))
for i=0,63 do
   v:value(i,i)
end
v.default = 0

v = s:taboption("remark", ListValue, "cos12dscp",
		translate("Remark DSCP 1 to DSCP:"))
for i=0,63 do
   v:value(i,i)
end
v.default = 8

v = s:taboption("remark", ListValue, "cos22dscp",
		translate("Remark DSCP 2 to DSCP:"))
for i=0,63 do
   v:value(i,i)
end
v.default = 16

v = s:taboption("remark", ListValue, "cos32dscp",
		translate("Remark DSCP 3 to DSCP:"))
for i=0,63 do
   v:value(i,i)
end
v.default = 24

v = s:taboption("remark", ListValue, "cos42dscp",
		translate("Remark DSCP 4 to DSCP:"))
for i=0,63 do
   v:value(i,i)
end
v.default = 32

v = s:taboption("remark", ListValue, "cos52dscp",
		translate("Remark DSCP 5 to DSCP:"))
for i=0,63 do
   v:value(i,i)
end
v.default = 40

v = s:taboption("remark", ListValue, "cos62dscp",
		translate("Remark DSCP 6 to DSCP:"))
for i=0,63 do
   v:value(i,i)
end
v.default = 48

v = s:taboption("remark", ListValue, "cos72dscp",
		translate("Remark DSCP 7 to DSCP:"))
for i=0,63 do
   v:value(i,i)
end
v.default = 56

return m
