<!-- DHCP Status -->
function onInit()
{
	document.getElementById('page_title').innerHTML = "DHCP 서버 정보";
	document.getElementById('section1_title').innerHTML = "DHCP 서버 설정 정보";
	document.getElementById('section2_title').innerHTML = "DHCP IP 할당 정보";
	document.getElementById('title_dhcp_status').innerHTML = "상태: ";
	document.getElementById('title_interface').innerHTML = "인터페이스: ";
	document.getElementById('title_start').innerHTML = "할당 시작 주소: ";
	document.getElementById('title_end').innerHTML = "할당 끝 주소: ";
	document.getElementById('title_time').innerHTML = "할당 시간: ";
	document.getElementById('title_router').innerHTML = "라우터: ";
	document.getElementById('title_static').innerHTML = "고정 IP: ";
	document.getElementById('title_dns1').innerHTML = "도메인네임 서버주소 1: ";
	document.getElementById('title_dns2').innerHTML = "도메인네임 서버주소 2: ";

	document.getElementById('index2').innerHTML = "번호";
	document.getElementById('macaddr2').innerHTML = "MAC 주소";
	document.getElementById('ipaddr2').innerHTML = "IP 주소";
	document.getElementById('hostname').innerHTML = "이름";
	document.getElementById('time2').innerHTML = "만료시간";

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
				_status	= xmlhttp.responseXML.documentElement.getElementsByTagName("STATUS")[0];
				_ifname	= xmlhttp.responseXML.documentElement.getElementsByTagName("INTERFACE")[0];
				_start 	= xmlhttp.responseXML.documentElement.getElementsByTagName("START")[0];
				_end  	= xmlhttp.responseXML.documentElement.getElementsByTagName("END")[0];
				_time  	= xmlhttp.responseXML.documentElement.getElementsByTagName("TIME")[0];
				_router	= xmlhttp.responseXML.documentElement.getElementsByTagName("ROUTER")[0];
				_static	= xmlhttp.responseXML.documentElement.getElementsByTagName("STATIC")[0];
				_dns1	= xmlhttp.responseXML.documentElement.getElementsByTagName("DNS1")[0];
				_dns2	= xmlhttp.responseXML.documentElement.getElementsByTagName("DNS2")[0];
				
				document.getElementById('status').innerHTML		= _status.firstChild.nodeValue;
				if (document.getElementById('status').innerHTML == "stopped")
				{
					return;
				}
				document.getElementById('interface').innerHTML	= _ifname.firstChild.nodeValue;
				document.getElementById('start').innerHTML		= _start.firstChild.nodeValue;
				document.getElementById('end').innerHTML		= _end.firstChild.nodeValue;
				document.getElementById('time').innerHTML		= _time.firstChild.nodeValue + " seconds";
				document.getElementById('router').innerHTML		= _router.firstChild.nodeValue;
				document.getElementById('dns1').innerHTML		= _dns1.firstChild.nodeValue;
				document.getElementById('dns2').innerHTML		= _dns2.firstChild.nodeValue;
				if (_static.firstChild.nodeValue == 1)
				{
					document.getElementById('static').innerHTML = "enable";
				}
				else
				{
					document.getElementById('static').innerHTML = "disable";
				}
				
				/*
				static_leases = xmlhttp.responseXML.documentElement.getElementsByTagName("STATIC_LEASE");
				if (static_leases.length != 0)
				{
					for(i = 0 ; i < static_leases.length ; i++)
					{
						ipaddr = static_leases[i].getElementsByTagName("IP")[0].firstChild.nodeValue;
						macaddr= static_leases[i].getElementsByTagName("MAC")[0].firstChild.nodeValue;
							
						table = document.getElementById('dhcp_server_config');

						row = table.insertRow(-1);
						cell= row.insertCell(0);
						cell= row.insertCell(1);
						cell.innerHTML = macaddr;
						cell= row.insertCell(2);
						cell.innerHTML = ipaddr;
					}
				}
				*/
				
				leases = xmlhttp.responseXML.documentElement.getElementsByTagName("LEASE");
				active_ip(leases);
			}
			catch(e)
			{
			}
		}
	}
	xmlhttp.send();
}

function active_ip( leases )
{
	if(typeof window.ActiveXObject != 'undefined')
	{
		xmlhttp = (new ActiveXObject("Microsoft.XMLHTTP"));
	}
	else
	{
		xmlhttp = (new XMLHttpRequest());
	}
	
	var data = "/cgi-bin/dhcp?cmd=real_status";

	xmlhttp.open( "POST", data, true );
	xmlhttp.setRequestHeader("Content-Type","application/x-www-form-urlencoded;charset=euc-kr");
	xmlhttp.onreadystatechange = function()
	{
		if( (xmlhttp.readyState == 4) && (xmlhttp.status == 200) )
		{
			try
            {
            	result = xmlhttp.responseXML.documentElement.getElementsByTagName("IP");
				
				var arr = [];                                                                      
				for (var k = 0; k < result.length; k++)                                            
				{                                                                                  
					arr.push(result[k].firstChild.nodeValue);                                  
				}
				
				ips = arr.reduce(function(a,b){if(a.indexOf(b)<0)a.push(b);return a;},[]);

				list_count=0;
				for(j = 0 ; j < ips.length ; j++)
				{
					ip = ips[j];
					ip = ip.replace(/\(/g,''); //특정문자 제거
					ip = ip.replace(/\)/g,''); //특정문자 제거
					//alert(ip);

					if (leases.length != 0)
					{
						for(i = 0 ; i < leases.length ; i++)
						{
							macaddr = leases[i].getElementsByTagName("MAC")[0].firstChild.nodeValue;
							ipaddr = leases[i].getElementsByTagName("IP")[0].firstChild.nodeValue;
							
							if (hostname = leases[i].getElementsByTagName("HOSTNAME")[0].firstChild == null)
							{
								hostname = "";
							} else {
								hostname = leases[i].getElementsByTagName("HOSTNAME")[0].firstChild.nodeValue;
							}
							
							expiresin = leases[i].getElementsByTagName("EXPIRESIN")[0].firstChild.nodeValue;
							//alert(i);
							if (ip == ipaddr)
							{
								table = document.getElementById('dhcp_active_leases');

								row = table.insertRow(list_count+1);
								cell= row.insertCell(0);
								cell.innerHTML = list_count+1;
								cell.setAttribute('class', 'title center');
								cell= row.insertCell(1);
								cell.innerHTML = macaddr;
								cell.setAttribute('class', 'center');
								cell= row.insertCell(2);
								cell.innerHTML = ipaddr;
								cell.setAttribute('class', 'center');
								cell= row.insertCell(3);
								cell.innerHTML = hostname;
								cell.setAttribute('class', 'center');
								cell= row.insertCell(4);
								cell.innerHTML = expiresin;
								cell.setAttribute('class', 'center');

								list_count++;
							}

							
						}
					}
				}
				
            }
            catch(e)
            {

            }
		}
	}
	xmlhttp.send();
}