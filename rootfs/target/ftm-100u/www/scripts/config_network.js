<!-- Network Configuration -->
function IsValidForm()
{
	if (typeof(document.f.ipaddr[0]) == 'undefined')
	{
		if (!IsValidIP(document.f.ipaddr, false))
		{
			return	Error('Missing or invalid IP address.', document.f.ipaddr);
		}

		if (!IsValidIP(document.f.netmask, false))
		{
			return	Error('Missing or invalid subnetmask address.', document.f.netmask);
		}
	}
	else 
	{
		for(i = 0 ; i < document.f.ipaddr.length ; i++)
		{
			if (!IsValidIP(document.f.ipaddr[i], false))
			{
				return	Error('Missing or invalid IP address.', document.f.ipaddr[i]);
			}

			if (!IsValidIP(document.f.netmask[i], false))
			{
				return	Error('Missing or invalid subnetmask address.', document.f.netmask[i]);
			}
		}
	}
	/*
	if (document.f.dns[0].length != 0 && !IsValidIP(document.f.dns[0], false))
	{
		return	Error('Missing or invalid DNS address.', document.f.dns[0]);
	}
	
	if (document.f.dns[0].length != 1 && !IsValidIP(document.f.dns[1], false))
	{
		return	Error('Missing or invalid DNS address.', document.f.dns[1]);
	}
	*/
	return	true;
}

function addInterface(_ifname, _ipaddr, _netmask)
{
	if_table = document.getElementById('eth');

	index = if_table.rows.length;
	console.log(index);
	row = if_table.insertRow(index);

	cell = row.insertCell(0);
	cell.setAttribute('class', 'index');
	cell.innerHTML = index;

	cell = row.insertCell(1);
	cell.setAttribute('class', 'ifname');
	cell.setAttribute('id', 'ifname' + (index-1));
	cell.innerHTML = _ifname;

	cell = row.insertCell(2);
	newElement = document.createElement('input');
	newElement.setAttribute('class', 'ipaddr');
	newElement.setAttribute('name', 'ipaddr');
	newElement.setAttribute('value', _ipaddr);
	cell.appendChild(newElement);

	cell = row.insertCell(3);
	newElement = document.createElement('input');
	newElement.setAttribute('class', 'netmask');
	newElement.setAttribute('name', 'netmask');
	newElement.setAttribute('value', _netmask);
	cell.appendChild(newElement);

}

var	msgApplyOK = 0;
var	msgApplyFailed = 1;
var msgConfirm = 2;
var	msg;

function onInit()
{
	msg = new Array();

	msg[msgApplyOK] = '네트워크 정보가 정상적으로 변경되었습니다.';
	msg[msgApplyFailed] = '네트워크 정보 변경에 문제가 발생하였습니다.';
	msg[msgConfirm] = '네트워크 정보를 수정하고 시스템을 다시 시작하시겠습니까?';

	document.getElementById('section1_title').innerHTML='내부 포트 설정';
	document.getElementById('page_title').innerHTML='네트워크 설정';
	document.getElementById('name').innerHTML='포트';
	document.getElementById('ipaddr1').innerHTML='IP주소';
	document.getElementById('netmask').innerHTML='서브넷마스크';
	//document.getElementById('section2_title').innerHTML='도메인 네임 서버 설정';
	//document.getElementById('ipaddr2').innerHTML='IP주소';
	document.getElementById('body').hidden = false;
	document.getElementById('apply').value = '적용 후 시스템 다시 시작';
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

					if (ifname != "eth0" && ifname != "usb0")
					{
						addInterface(ifname, ipaddr, netmask);
					}
				}
				
				/*
				DNS = xmlhttp.responseXML.documentElement.getElementsByTagName("DNS");
				
				for(i = 0 ; i < DNS.length ; i++)
				{
						ipaddr  = DNS[i].getElementsByTagName("IPADDR")[0].firstChild.nodeValue;
			
						document.f.dns[i].value = ipaddr;
				}
				*/
			}
			catch(e)
			{
			}
		}
	}
	xmlhttp.send();
}


function onApply()
{
	var confirmAlert = confirm(msg[msgConfirm]);
	if (confirmAlert == false)
	{
		return;
	} 
	else 
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
	
	var data = "/cgi-bin/network?cmd=set";
	if (typeof(document.f.ipaddr[0]) == 'undefined')
	{
		data += "&ifname0=" + document.getElementById('ifname0').innerHTML;
		data += "&ipaddr0=" + document.f.ipaddr.value;
		data += "&netmask0=" + document.f.netmask.value;
	}
	else
	{
		for(i = 0 ; i < document.f.ipaddr.length ; i++)
		{
			data += "&ifname" + i + "=" + document.getElementById('ifname' + i).innerHTML;
			data += "&ipaddr" + i + "=" + document.f.ipaddr[i].value;
			data += "&netmask" + i + "=" + document.f.netmask[i].value;
		
		}
	}
	//data += "&dns0=" + document.f.dns[0].value;
	//data += "&dns1=" + document.f.dns[1].value;
	
	xmlhttp.open( "POST", data, true );
	xmlhttp.setRequestHeader("Content-Type","application/x-www-form-urlencoded;charset=euc-kr");
	xmlhttp.onreadystatechange = function()
	{
		if( (xmlhttp.readyState == 4) && (xmlhttp.status == 200) )
		{
			try
			{
				retElement = xmlhttp.responseXML.documentElement.getElementsByTagName("RET")[0];
				if (retElement.firstChild.nodeValue  == 'OK')
				{
					alert(msg[msgApplyOK]);
					//onSystemRestart();
					loadDHCP();
				}
				else
				{
					alert(msg[msgApplyFailed]);
				}
						
			}
			catch(e)
			{
			}
		}
	}
	xmlhttp.send();
	}
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

//==========================================================================================================
function loadDHCP()
{
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
				saveDHCP( element );
			}
			catch(e)
			{
			}
		}
	}
	xmlhttp.send();
}

function saveDHCP( _element )
{
	if(typeof window.ActiveXObject != 'undefined')
	{
		xmlhttp = (new ActiveXObject("Microsoft.XMLHTTP"));
	}
	else
	{
		xmlhttp = (new XMLHttpRequest());
	}
	
	var enable_checked;
	var static_leases_checked;
	
	if (_element.getElementsByTagName("STATUS")[0].firstChild.nodeValue == 'running')
	{
		enable_checked = true;
	}
	else
	{
		enable_checked = false;
	}
	
	if (_element.getElementsByTagName("STATIC")[0].firstChild.nodeValue == true)
	{
		static_leases_checked = true;
	}
	else
	{
		static_leases_checked = false;
	}

	var if_value = _element.getElementsByTagName("INTERFACE")[0].firstChild.nodeValue;
	var ip_pool_start_value = _element.getElementsByTagName("START")[0].firstChild.nodeValue;
	var ip_pool_end_value = _element.getElementsByTagName("END")[0].firstChild.nodeValue;
	var router_value = _element.getElementsByTagName("ROUTER")[0].firstChild.nodeValue;	
	var lease_time_value = _element.getElementsByTagName("TIME")[0].firstChild.nodeValue;
	var dns1_value = _element.getElementsByTagName("DNS1")[0].firstChild.nodeValue;
	var dns2_value = _element.getElementsByTagName("DNS2")[0].firstChild.nodeValue;

	var static_leases = _element.getElementsByTagName("STATIC_LEASE");
	var ipaddr=[];
	var macaddr=[];
	for(i = 0 ; i < static_leases.length ; i++)
	{
		ipaddr.push(static_leases[i].getElementsByTagName("IP")[0].firstChild.nodeValue);
		macaddr.push(static_leases[i].getElementsByTagName("MAC")[0].firstChild.nodeValue);
	}

	//======================================
	var net_addr = document.f.ipaddr.value;

	/*
	if (if_value == "eth1")
	{
		net_addr = document.f.ipaddr[1].value;
	}
	else
	{
		net_addr = document.f.ipaddr[0].value;
	}
	*/
	var net_addr_arr = net_addr.split(".");
	
	var start_addr_arr = ip_pool_start_value.split(".");
	var end_addr_arr = ip_pool_end_value.split(".");
	var router_addr_arr = router_value.split(".");

	var set_start_addr = net_addr_arr[0] + "." + net_addr_arr[1] + "." + net_addr_arr[2] + "." + start_addr_arr[3];
	var set_end_addr = net_addr_arr[0] + "." + net_addr_arr[1] + "." + net_addr_arr[2] + "." + end_addr_arr[3];
	var set_router_addr = net_addr_arr[0] + "." + net_addr_arr[1] + "." + net_addr_arr[2] + "." + net_addr_arr[3];
	//alert(set_start_addr);
	//alert(set_end_addr);
	//======================================
	
	var data = "/cgi-bin/dhcp?cmd=set";
	data += "&enable=" + enable_checked;
	data += "&if=" + if_value;
	data += "&start=" + set_start_addr;
	data += "&end=" + set_end_addr;
	data += "&router=" + set_router_addr;
	data += "&time=" + lease_time_value;
	data += "&static=" + static_leases_checked;
	data += "&dns1=" + dns1_value;
	data += "&dns2=" + dns2_value;

	if (macaddr.length > 0)
	{
		for(i = 0 ; i < macaddr.length ; i++)
		{
			data += "&mac" + i + "=" + macaddr[i];
			data += "&ip" + i + "=" + ipaddr[i];
			
		}			
	}
	// else
// 	{
// 			data += "&mac0=" + "00:00:00:00:00:00";
// 			data += "&ip0=" + "0.0.0.0";
// 	}

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
					//alert('DHCP 서버 설정이 정상적으로 변경되었습니다.');
					onSystemRestart();
				}
				else
				{
					//msg = xmlhttp.responseXML.documentElement.getElementsByTagName("MSG")[0].firstChild.nodeValue;		
					//alert('DHCP 서버 설정에 문제가 발생하였습니다.\n' + msg);
					alert(msg[msgApplyFailed]);
				}
						
			}
			catch(e)
			{
			}
		}
	}
	xmlhttp.send();
}