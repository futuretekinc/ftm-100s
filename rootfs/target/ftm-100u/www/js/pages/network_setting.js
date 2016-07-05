/**
 * Created by kindmong on 2015-11-05.
 */
function init() {
    $.li18n.currentLocale = 'kr';
    document.getElementById("menu_dashboard").innerHTML = _t('dashboard');
    document.getElementById("menu_sensors").innerHTML = _t('sensors');
    document.getElementById("menu_clouds").innerHTML = _t('clouds');
    document.getElementById("menu_network").innerHTML = _t('network');
    document.getElementById("menu_system").innerHTML = _t('system');

	document.getElementById("label_name").innerHTML = _t('port');
    document.getElementById("label_ip").innerHTML = _t('ip');
    document.getElementById("label_subnet").innerHTML = _t('subnet');
    document.getElementById("label_mac").innerHTML = _t('mac');
	document.getElementById("modify_btn").innerHTML = _t('modify');
}

$(document).ready(function(){
    init();

    $('input:radio[name="inlineRadioOptions"]').change(function() {
        console.log("Ataeta");
    });
    // LTE 모델일때 비활성
    loadNetworkData();
});

function loadNetworkData() {
    $.ajax({
        type:"get",
        url:"/cgi-bin/network?cmd=status",
        dataType:"xml",
        success : function(xml) {
            // 통신이 성공적으로 이루어졌을 때 이 함수를 타게 된다.
            // TODO
            $(xml).find("ETH").each(function(){
                console.log($(this).find("INDEX").text());
                console.log($(this).find("IFNAME").text());
                console.log($(this).find("IPADDR").text());
                console.log($(this).find("NETMASK").text());
                console.log($(this).find("MACADDR").text());

                if($(this).find("IFNAME").text() == "br-lan") {
                    insertLanData($(this));
                }
                if($(this).find("IFNAME").text() == "eth0") {
                    //insertWanData($(this));
                }
            });
            // Gateway IP
            $(xml).find("DNS").each(function() {
                if($(this).find("INDEX").text() == "1") {
                    //document.getElementById("inputgate").value = $(this).find("IPADDR").text();
                }
            });
        },
        error : function(xhr, status, error) {
			//alert("에러발생");
			window.location.href="/";
        }
    });
}

// LAN 속성을 input에 넣어준다.
function insertLanData(xml) {
	document.getElementById("inputmac2").readOnly = true;
    document.getElementById("ifname2").readOnly = true;
    document.getElementById("ifname2").value = xml.find("IFNAME").text();
    document.getElementById("inputmac2").value = xml.find("MACADDR").text();
    document.getElementById("inputip2").value = xml.find("IPADDR").text();
    document.getElementById("inputsubnet2").value = xml.find("NETMASK").text();
}

// WAN 속성을 input에 넣어준다.
function insertWanData(xml) {
	document.getElementById("inputmac").readOnly = true;
    document.getElementById("inputmac").value = xml.find("MACADDR").text();
    document.getElementById("inputip").value = xml.find("IPADDR").text();
    document.getElementById("inputsubnet").value = xml.find("NETMASK").text();
}

function onApply()
{
	var confirmAlert = confirm("modify?");
	if (confirmAlert == false)
	{
		return;
	} 
	else 
	{
	
	if(typeof window.ActiveXObject != 'undefined')
	{
		xmlhttp = (new ActiveXObject("Microsoft.XMLHTTP"));
	}
	else
	{
		xmlhttp = (new XMLHttpRequest());
	}
	
	var data = "/cgi-bin/network?cmd=set";
//	if (typeof(document.f.ipaddr[0]) == 'undefined')
//	{
//		data += "&ifname0=" + document.getElementById('ifname0').innerHTML;
//		data += "&ipaddr0=" + document.f.ipaddr.value;
//		data += "&netmask0=" + document.f.netmask.value;
//	}
//	else
//	{
//		for(i = 0 ; i < document.f.ipaddr.length ; i++)
//		{
			data += "&ifname0=" + document.getElementById("ifname2").value;
			data += "&ipaddr0=" + document.getElementById("inputip2").value;
			data += "&netmask0=" + document.getElementById("inputsubnet2").value;
		
//		}
//	}
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
					alert("modify complete");
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
	//var net_addr = document.f.ipaddr.value;
	var net_addr = document.getElementById("inputip2").value;
	console.log(net_addr);
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