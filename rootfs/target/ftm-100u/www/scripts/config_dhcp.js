<!-- DHCP Status -->
var	msg;
var	msgRemove=0;

function onInit()
{
	msg = new Array();
	msg[msgRemove]='삭제';
	document.getElementById('page_title').innerHTML ='DHCP 설정';
	document.getElementById('section1_title').innerHTML ='DHCP 서버 설정';
	document.getElementById('enable').innerHTML="<input type='checkbox' name='enable'>사용";
	document.getElementById('if').innerHTML ='인터페이스:';
	document.getElementById('start').innerHTML ='할당 시작 주소:';
	document.getElementById('end').innerHTML ='할당 끝 주소:';
	document.getElementById('time').innerHTML ='할당 유효 시간:';
	document.getElementById('router').innerHTML ='라우터:';
	document.getElementById('dns1').innerHTML ='도메인네임 서버주소 1:';
	document.getElementById('dns2').innerHTML ='도메인네임 서버주소 2:';
	document.getElementById('static_leases').innerHTML ="<input type='checkbox' id='static_leases' name='static_leases'>고정 할당 주소 사용";
	document.getElementById('index').innerHTML ='번호';
	document.getElementById('macaddr').innerHTML ='MAC 주소';
	document.getElementById('ipaddr').innerHTML ='IP 주소';
	document.getElementById('add').value ='추가';
	document.getElementById('apply').value ='적용';
	

	document.getElementById('body').hidden = false;
}

function onLoad()
{
	onInit();

	enablePageTimeout();

	if(typeof window.ActiveXObject != 'undefined')
	{
		xmlhttp = (new ActiveXObject("Microsoft.XMLHTTP"));
	}
	else
	{
		xmlhttp = (new XMLHttpRequest());
	}
	
	var data = "/cgi-bin/dhcp?cmd=status";
	
	xmlhttp.open( "POST", data, true );
	xmlhttp.setRequestHeader("Content-Type","application/x-www-form-urlencoded;charset=euc-kr");
	xmlhttp.onreadystatechange = function()
	{
		if( (xmlhttp.readyState == 4) && (xmlhttp.status == 200) )
		{
			try
			{
				element = xmlhttp.responseXML.documentElement;

				if (element.getElementsByTagName("STATUS")[0].firstChild.nodeValue == 'running')
				{
					document.f.enable.checked = true;
				}
				else
				{
					document.f.enable.checked = false;
				}
				
				if (element.getElementsByTagName("STATIC")[0].firstChild.nodeValue == true)
				{
					document.f.static_leases.checked = true;
				}
				else
				{
					document.f.static_leases.checked = false;
				}

				//document.f.if.value
				document.getElementById('eth_if').innerHTML = element.getElementsByTagName("INTERFACE")[0].firstChild.nodeValue;
				document.f.ip_pool_start.value = element.getElementsByTagName("START")[0].firstChild.nodeValue;
				document.f.ip_pool_end.value = element.getElementsByTagName("END")[0].firstChild.nodeValue;
				document.f.router.value = element.getElementsByTagName("ROUTER")[0].firstChild.nodeValue;	
				document.f.lease_time.value = element.getElementsByTagName("TIME")[0].firstChild.nodeValue;
				document.f.dns1.value = element.getElementsByTagName("DNS1")[0].firstChild.nodeValue;
				document.f.dns2.value = element.getElementsByTagName("DNS2")[0].firstChild.nodeValue;

				static_leases = element.getElementsByTagName("STATIC_LEASE");
				for(i = 0 ; i < static_leases.length ; i++)
				{
					ipaddr 	= static_leases[i].getElementsByTagName("IP")[0].firstChild.nodeValue;
					macaddr	= static_leases[i].getElementsByTagName("MAC")[0].firstChild.nodeValue;
					
					onAddStaticLease(macaddr, ipaddr);
				}
				loadNetwork();
				
			}
			catch(e)
			{
			}
		}
	}
	xmlhttp.send();
}

function IsValidForm()
{
	if (!IsValidIP(document.f.ip_pool_start, false))
	{
		return	Error('Missing or invalid IP address.', document.f.ip_pool_start);
	}
	
	if (!IsValidIP(document.f.ip_pool_end, false))
	{
		return	Error('Missing or invalid subnetmask address.', document.f.ip_pool_end);
	}

	if (typeof(document.f.router) != 'undefined' )
	{
		if (!IsValidIP(document.f.router, false))
		{
			return	Error('Missing or invalid router address.', document.f.router);
		}
	}

	if (typeof(document.f.mac) != 'undefined' )
	{
		if (typeof(document.f.mac.length) != 'undefined')
		{
			for(i = 0 ; i < document.f.mac.length ; i++)
			{
				if (!IsValidMAC(document.f.mac[i], false))
				{
					return	Error('Missing or invalid MAC address.', document.f.mac[i]);
				}
				if (!IsValidIP(document.f.ip[i], false))
				{
					return	Error('Missing or invalid IP address.', document.f.ip[i]);
				}
			}
		}
		else
		{
			if (!IsValidMAC(document.f.mac, false))
			{
				return	Error('Missing or invalid MAC address.', document.f.mac);
			}
			if (!IsValidIP(document.f.ip, false))
			{
				return	Error('Missing or invalid IP address.', document.f.ip);
			}
		}
	}
	return	true;
}

function onApply()
{
	if (IsValidForm() != true)
	{
		return;
	}
	
	if(typeof window.ActiveXObject != 'undefined')
	{
		xmlhttp = (new ActiveXObject("Microsoft.XMLHTTP"));
	}
	else
	{
		xmlhttp = (new XMLHttpRequest());
	}
	
	var data = "/cgi-bin/dhcp?cmd=set";
	data += "&enable=" + document.f.enable.checked;
	data += "&if=" + document.getElementById('eth_if').innerHTML;
	data += "&start=" + document.f.ip_pool_start.value;
	data += "&end=" + document.f.ip_pool_end.value;
	data += "&router=" + document.f.router.value;
	data += "&time=" + document.f.lease_time.value;
	data += "&static=" + document.f.static_leases.checked;
	data += "&dns1=" + document.f.dns1.value;
	data += "&dns2=" + document.f.dns2.value;

	if (typeof(document.f.mac) != 'undefined')
	{
		if (typeof(document.f.mac.length) != 'undefined')
		{
			for(i = 0 ; i < document.f.mac.length ; i++)
			{
				data += "&mac" + i + "=" + document.f.mac[i].value;
				data += "&ip" + i + "=" + document.f.ip[i].value;
				
			}
		}
		else
		{
				data += "&mac0=" + document.f.mac.value;
				data += "&ip0=" + document.f.ip.value;
		}			
	}

	xmlhttp.open( "POST", data, true );
	xmlhttp.setRequestHeader("Content-Type","application/x-www-form-urlencoded;charset=euc-kr");
	xmlhttp.onreadystatechange = function()
	{
		if( (xmlhttp.readyState == 4) && (xmlhttp.status == 200) )
		{
			try
			{
				ret = xmlhttp.responseXML.documentElement.getElementsByTagName("RET")[0].firstChild.nodeValue;		
				
				if (ret == 'OK')
				{
					alert('DHCP 서버 설정이 정상적으로 변경되었습니다.\n단말이 재부팅됩니다.');
					onSystemRestart();
				}
				else
				{
					msg = xmlhttp.responseXML.documentElement.getElementsByTagName("MSG")[0].firstChild.nodeValue;		
					alert('DHCP 서버 설정에 문제가 발생하였습니다.\n' + msg);
				
				}
						
			}
			catch(e)
			{
			}
		}
	}
	xmlhttp.send();
}

function onAddStaticLease(macaddr, ipaddr)
{
	if (typeof(macaddr) == 'undefined')
	{
		macaddr = '00:00:00:00:00:00';			
		ipaddr 	= '0.0.0.0';			
	}
	
	static_lease = document.getElementById('static_lease');

	index = static_lease.rows.length - 1;
	row = static_lease.insertRow(index);
	cell = row.insertCell(0);
	cell.setAttribute('class', 'center');
	cell.innerHTML = index;
			
	cell = row.insertCell(1);
	cell.setAttribute('class', 'center');
	newElement = document.createElement('input');
	newElement.setAttribute('class', 'macaddr');
	newElement.setAttribute('name', 'mac');
	newElement.setAttribute('value', macaddr);
	cell.appendChild(newElement);
			
	cell = row.insertCell(2);
	cell.setAttribute('class', 'center');
	newElement = document.createElement('input');
	newElement.setAttribute('class', 'ipaddr');
	newElement.setAttribute('name', 'ip');
	newElement.setAttribute('value', ipaddr);
	cell.appendChild(newElement);
	
	cell = row.insertCell(3);
	cell.setAttribute('class', 'center');
	newElement = document.createElement('input');
	newElement.setAttribute('type', 'button');
	newElement.setAttribute('value', msg[msgRemove]);
	newElement.setAttribute('class', 'ctrlbtn');
	newElement.setAttribute('onclick', 'onRemoveStaticLease(' + index + ');');
	cell.appendChild(newElement);
}

function onRemoveStaticLease(index)
{
	static_lease = document.getElementById('static_lease');

	if (0 < index && index < static_lease.rows.length - 1)
	{
		static_lease.deleteRow(index);
	}
}

var ip_eth0;
var ip_eth1;
function selectEvent(selectObj)
{
	if (selectObj.value == "eth1")
	{
		document.f.ip_pool_start.value = ip_eth1[0] + "." + ip_eth1[1] + "." + ip_eth1[2] + ".20";
		document.f.ip_pool_end.value = ip_eth1[0] + "." + ip_eth1[1] + "." + ip_eth1[2] + ".254";
		document.f.router.value = ip_eth1[0] + "." + ip_eth1[1] + "." + ip_eth1[2] + "." + ip_eth1[3];
	} else {
		document.f.ip_pool_start.value = ip_eth0[0] + "." + ip_eth0[1] + "." + ip_eth0[2] + ".20";
		document.f.ip_pool_end.value = ip_eth0[0] + "." + ip_eth0[1] + "." + ip_eth0[2] + ".254";
		document.f.router.value = ip_eth0[0] + "." + ip_eth0[1] + "." + ip_eth0[2] + "." + ip_eth0[3];
	}
}

function loadNetwork()
{
	if(typeof window.ActiveXObject != 'undefined')
	{
		xmlhttp = (new ActiveXObject("Microsoft.XMLHTTP"));
	}
	else
	{
		xmlhttp = (new XMLHttpRequest());
	}
	
	var data = "/cgi-bin/network?cmd=status";
	
	xmlhttp.open( "POST", data, true );
	xmlhttp.setRequestHeader("Content-Type","application/x-www-form-urlencoded;charset=euc-kr");
	xmlhttp.onreadystatechange = function()
	{
		if( (xmlhttp.readyState == 4) && (xmlhttp.status == 200) )
		{
			try
			{
				interfaces = xmlhttp.responseXML.documentElement.getElementsByTagName("ETH");
				for(i = 0 ; i < interfaces.length ; i++)
				{
					ifname 	= interfaces[i].getElementsByTagName("IFNAME")[0].firstChild.nodeValue;
					ipaddr  = interfaces[i].getElementsByTagName("IPADDR")[0].firstChild.nodeValue;
					netmask = interfaces[i].getElementsByTagName("NETMASK")[0].firstChild.nodeValue;
					if (i == 0)
					{
						ip_eth0 = ipaddr.split(".");
					}
					if (i == 1)
					{
						ip_eth1 = ipaddr.split(".");
					}
					//alert(ipaddr);
					//addInterface(ifname, ipaddr, netmask);
				}
			}
			catch(e)
			{
			}
		}
	}
	xmlhttp.send();
}

function onSystemRestart()
{
		if(typeof window.ActiveXObject != 'undefined')
		{
				xmlhttp = (new ActiveXObject("Microsoft.XMLHTTP"));
		}
		else
		{
				xmlhttp = (new XMLHttpRequest());
		}

		var data = "/cgi-bin/system?cmd=reboot";

		xmlhttp.open( "POST", data, true );
		xmlhttp.setRequestHeader("Content-Type","application/x-www-form-urlencoded;charset=euc-kr");
		xmlhttp.onreadystatechange = function()
		{
				if( (xmlhttp.readyState == 4) && (xmlhttp.status == 200) )
				{
						try
						{
								ret  = xmlhttp.responseXML.documentElement.getElementsByTagName("RET");
								if (ret[0].firstChild.nodeValue == 'OK')
								{
										alert(msg[msgResetaring]);
								}
								else
								{
										alert(msg[msgRestartFailed]);
								}
						}
						catch(e)
						{
								window.location.href = '/';
						}
				}
		}
		xmlhttp.send();
}