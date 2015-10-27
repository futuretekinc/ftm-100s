<!-- Network Status -->
var usim=true;

var keys = ["TIME (YYYYMMDDHHMMSS)", "DL EARFCN", "RX Power", "TX Adjust",
"TX Power", "Pilot PN Offset", "Ec/lo", "System Identification",
"Network Identification", "Registration Zone", "Registration Zone", "Base Station Identification"];

function onInit()
{
	document.getElementById('page_title').innerHTML = '네트워크 상태 정보';
	document.getElementById('section1_title').innerHTML = '무선 접속 정보';
	document.getElementById('section2_title').innerHTML = '내부 포트 정보';
	document.getElementById('section3_title').innerHTML = '모뎀 정보';
	document.getElementById('usim_label').innerHTML = 'USIM 상태';
	document.getElementById('cnum_label').innerHTML = "전화번호";
	//document.getElementById('usage').innerHTML = '데이터 사용량 정보';
	document.getElementById('rx').innerHTML = '다운로드 사용량';
	document.getElementById('tx').innerHTML = '업로드 사용량';
	//document.getElementById('link').innerHTML = 'KT Link';
	//document.getElementById('usage_label').innerHTML = '(실제 데이터양과 다를 수 있음.)';
	document.getElementById('name1').innerHTML = '포트';
	document.getElementById('ipaddr1').innerHTML = 'IP 주소';
	//document.getElementById('netmask1').innerHTML = '서브넷마스크';
	//document.getElementById('ptpaddr1').innerHTML = 'P-to-P 서버';
	document.getElementById('name2').innerHTML = '포트';
	document.getElementById('ipaddr2').innerHTML = 'IP 주소';
	document.getElementById('netmask2').innerHTML = '서브넷마스크';
	document.getElementById('macaddr2').innerHTML = 'MAC 주소';
	document.getElementById('body').hidden = false;
	//document.getElementById('netmask1').hidden = true;
}

function usim_socket_status()
{
	if(typeof window.ActiveXObject != 'undefined')
	{
		xmlhttp = (new ActiveXObject("Microsoft.XMLHTTP"));
	}
	else
	{
		xmlhttp = (new XMLHttpRequest());
	}
	
	var data = "/cgi-bin/usim?cmd=usim_socket_status";

	xmlhttp.open( "POST", data, true );
	xmlhttp.setRequestHeader("Content-Type","application/x-www-form-urlencoded;charset=euc-kr");
	xmlhttp.onreadystatechange = function()
	{
		if( (xmlhttp.readyState == 4) && (xmlhttp.status == 200) )
		{
			try
            {
            	result = xmlhttp.responseXML.documentElement.getElementsByTagName("res")[0];
            	if (result.firstChild.nodeValue == 'OK') {

            		// 파싱
            		var resultNode = xmlhttp.responseXML.documentElement.getElementsByTagName("text")[0];
					var result = resultNode.firstChild.nodeValue;

					if (result == "done" || result == "URC MESSAGE")
					{
						document.getElementById('message').innerHTML='다시 시도해 주십시오..';
						return;
					}
					
					if (result == 0)
					{
						// 유심 미장착
						alert("USIM이 장착되어있지 않습니다.\nUSIM을 장착하신 후 전원을 껐다 켜주십시오.");
						document.getElementById("usim_status").innerHTML = "SIM NOT INSERT";
						return
					} else {// if (result == 1) {
						// 유심장착
						usim_different_status();
					}

            	} else {
            		// error
            		alert("Please Refresh..");
            	}
            }
            catch(e)
            {

            }
		}
	}
	xmlhttp.send();
}

function usim_different_status()
{
	if(typeof window.ActiveXObject != 'undefined')
	{
		xmlhttp = (new ActiveXObject("Microsoft.XMLHTTP"));
	}
	else
	{
		xmlhttp = (new XMLHttpRequest());
	}
	
	var data = "/cgi-bin/usim?cmd=usim_different_status";

	xmlhttp.open( "POST", data, true );
	xmlhttp.setRequestHeader("Content-Type","application/x-www-form-urlencoded;charset=euc-kr");
	xmlhttp.onreadystatechange = function()
	{
		if( (xmlhttp.readyState == 4) && (xmlhttp.status == 200) )
		{
			try
            {
            	result = xmlhttp.responseXML.documentElement.getElementsByTagName("res")[0];
            	if (result.firstChild.nodeValue == 'OK') {

            		// 파싱
            		var resultNode = xmlhttp.responseXML.documentElement.getElementsByTagName("text")[0];
					var result = resultNode.firstChild.nodeValue;

					if (result == "done" || result == "URC MESSAGE")
					{
						document.getElementById('message').innerHTML='다시 시도해 주십시오..';
						return;
					}

					//result = 6;
					//if (result == 0)
					//{
						// 서비스등록
					//	document.getElementById("usim_status").innerHTML = "READY";
					//}
					if (result == 3)
					{
						// 기기인증 실패 (타단말 유심 의심)
						alert("타 이통사 USIM 입니다.\n새로운 USIM을 장착한 후 전원을 껏다 켜주십시오.");
						document.getElementById("usim_status").innerHTML = "타 이통사 USIM";
						return;
					}
					
					usim_open_status();

            	} else {
            		// error
            		alert("Please Refresh..");
            	}
            }
            catch(e)
            {

            }
		}
	}
	xmlhttp.send();
}

function usim_open_status()
{
	if(typeof window.ActiveXObject != 'undefined')
	{
		xmlhttp = (new ActiveXObject("Microsoft.XMLHTTP"));
	}
	else
	{
		xmlhttp = (new XMLHttpRequest());
	}
	
	var data = "/cgi-bin/usim?cmd=usim_open_status";

	xmlhttp.open( "POST", data, true );
	xmlhttp.setRequestHeader("Content-Type","application/x-www-form-urlencoded;charset=euc-kr");
	xmlhttp.onreadystatechange = function()
	{
		if( (xmlhttp.readyState == 4) && (xmlhttp.status == 200) )
		{
			try
            {
            	result = xmlhttp.responseXML.documentElement.getElementsByTagName("res")[0];
            	if (result.firstChild.nodeValue == 'OK') {

            		// 파싱
            		var resultNode = xmlhttp.responseXML.documentElement.getElementsByTagName("text")[0];
					var result = resultNode.firstChild.nodeValue;

					if (result == "done" || result == "URC MESSAGE")
					{
						document.getElementById('message').innerHTML='다시 시도해 주십시오..';
						return;
					}

					//result = "OPEN";
					//if (result == "READY")
					//{
						// 개통유심
					//	document.getElementById("usim_status").innerHTML = "READY";
					//}
					if (result == 1)
					{
						// 미개통 유심
						alert("미개통 USIM입니다.\n개통후 전원을 껏다 켜 주십시오.");
						document.getElementById("usim_status").innerHTML = "미개통 USIM";
						return;
					}
//					is_limited();
					usim_cnum();
					//usim_sending_stop_status();

            	} else {
            		// error
            		alert("Please Refresh..");
            	}
            }
            catch(e)
            {

            }
		}
	}
	xmlhttp.send();
}

function usim_cnum()
{
	if(typeof window.ActiveXObject != 'undefined')
	{
		xmlhttp = (new ActiveXObject("Microsoft.XMLHTTP"));
	}
	else
	{
		xmlhttp = (new XMLHttpRequest());
	}
	
	var data = "/cgi-bin/usim?cmd=cnum";

	xmlhttp.open( "POST", data, true );
	xmlhttp.setRequestHeader("Content-Type","application/x-www-form-urlencoded;charset=euc-kr");
	xmlhttp.onreadystatechange = function()
	{
		if( (xmlhttp.readyState == 4) && (xmlhttp.status == 200) )
		{
			try
            {
            	result = xmlhttp.responseXML.documentElement.getElementsByTagName("res")[0];
            	if (result.firstChild.nodeValue == 'OK') {

            		// 파싱
            		var resultNode = xmlhttp.responseXML.documentElement.getElementsByTagName("text")[0];
					var result = resultNode.firstChild.nodeValue;

					if (result == "done" || result == "URC MESSAGE")
					{
						document.getElementById('message').innerHTML='다시 시도해 주십시오..';
						return;
					}
				
					var resultArr = result.split(",");
					document.getElementById("cnum_value").innerHTML = resultArr[1].substring(1, 13);
				
					is_limited();

            	} else {
            		// error
            		alert("Please Refresh..");
            	}
            }
            catch(e)
            {

            }
		}
	}
	xmlhttp.send();
}

function is_limited()
{
	if(typeof window.ActiveXObject != 'undefined')
	{
		xmlhttp = (new ActiveXObject("Microsoft.XMLHTTP"));
	}
	else
	{
		xmlhttp = (new XMLHttpRequest());
	}
	
	var data = "/cgi-bin/usim?cmd=is_limited";

	xmlhttp.open( "POST", data, true );
	xmlhttp.setRequestHeader("Content-Type","application/x-www-form-urlencoded;charset=euc-kr");
	xmlhttp.onreadystatechange = function()
	{
		if( (xmlhttp.readyState == 4) && (xmlhttp.status == 200) )
		{
			try
            {
            	result = xmlhttp.responseXML.documentElement.getElementsByTagName("res")[0];
            	if (result.firstChild.nodeValue == 'OK') {

            		// 파싱
            		var resultNode = xmlhttp.responseXML.documentElement.getElementsByTagName("text")[0];
					var result = resultNode.firstChild.nodeValue;

					if (result == "done" || result == "URC MESSAGE")
					{
						document.getElementById('message').innerHTML='다시 시도해 주십시오..';
						return;
					}
					
					if (result == "N")
					{
						document.getElementById("usim_status").innerHTML = "No Service";
						return;
					}
					else
					{
						//usim_sending_stop_status(); 발신정지 커맨드를 아직 모름
						document.getElementById("usim_status").innerHTML = "READY";
						new_pppData();
					}

            	} else {
            		// error
            		alert("Please Refresh..");
            	}
            }
            catch(e)
            {

            }
		}
	}
	xmlhttp.send();
}

function usim_sending_stop_status()
{
	if(typeof window.ActiveXObject != 'undefined')
	{
		xmlhttp = (new ActiveXObject("Microsoft.XMLHTTP"));
	}
	else
	{
		xmlhttp = (new XMLHttpRequest());
	}
	
	var data = "/cgi-bin/usim?cmd=usim_sending_stop_status";

	xmlhttp.open( "POST", data, true );
	xmlhttp.setRequestHeader("Content-Type","application/x-www-form-urlencoded;charset=euc-kr");
	xmlhttp.onreadystatechange = function()
	{
		if( (xmlhttp.readyState == 4) && (xmlhttp.status == 200) )
		{
			try
            {
            	result = xmlhttp.responseXML.documentElement.getElementsByTagName("res")[0];
            	if (result.firstChild.nodeValue == 'OK') {

            		// 파싱
            		var resultNode = xmlhttp.responseXML.documentElement.getElementsByTagName("text")[0];
					var result = resultNode.firstChild.nodeValue;

					if (result == "done" || result == "URC MESSAGE")
					{
						document.getElementById('message').innerHTML='다시 시도해 주십시오..';
						return;
					}

					//result = "Barred";
					if (result == "OK")
					{
						// 정상 서비스 상태
						document.getElementById("usim_status").innerHTML = "READY";
					}
					if (result == "Barred")
					{
						// 발신정지 상태
						alert("단말이 발신정지 상태입니다.\n고객센터에 연락하여 발신정지 해지를 요청하십시오.\n발신정지가 해지되면 단말을 재부팅 해주십시오.");
						document.getElementById("usim_status").innerHTML = "발신정지";
						//return;
					}

					new_pppData();

            	} else {
            		// error
            		alert("Please Refresh..");
            	}
            }
            catch(e)
            {

            }
		}
	}
	xmlhttp.send();
}

function new_pppData()
{
	if(typeof window.ActiveXObject != 'undefined')
	{
		xmlhttp = (new ActiveXObject("Microsoft.XMLHTTP"));
	}
	else
	{
		xmlhttp = (new XMLHttpRequest());
	}
	
	var data = "/cgi-bin/getdata?cmd=state";

	xmlhttp.open( "POST", data, true );
	xmlhttp.setRequestHeader("Content-Type","application/x-www-form-urlencoded;charset=euc-kr");
	xmlhttp.onreadystatechange = function()
	{
		
		if( (xmlhttp.readyState == 4) && (xmlhttp.status == 200) )
		{
			try
            {
            	result = xmlhttp.responseXML.documentElement.getElementsByTagName("res")[0];
            	if (result.firstChild.nodeValue == 'OK') {

            		// 파싱
            		var resultNode = xmlhttp.responseXML.documentElement.getElementsByTagName("text")[0];
					if (resultNode.firstChild != null)
					{
						var result = resultNode.firstChild.nodeValue;
						var resultArr = result.split(" ");	
						var rx_data = resultArr[0];
						var tx_data = resultArr[1];
						var rx = document.getElementById("rx_data");
						var tx = document.getElementById("tx_data");
						rx.innerHTML = bytesToSize(rx_data);
						tx.innerHTML = bytesToSize(tx_data);
					}
					new_NetworkState();
            	} else {
            		// error
					new_NetworkState();
            	}
            }
            catch(e)
            {

            }
		}
	}
	xmlhttp.send();
}

function new_NetworkState()
{
	if(typeof window.ActiveXObject != 'undefined')
	{
		xmlhttp = (new ActiveXObject("Microsoft.XMLHTTP"));
	}
	else
	{
		xmlhttp = (new XMLHttpRequest());
	}
	
	var data = "/cgi-bin/network_state?cmd=state";

	xmlhttp.open( "POST", data, true );
	xmlhttp.setRequestHeader("Content-Type","application/x-www-form-urlencoded;charset=euc-kr");
	xmlhttp.onreadystatechange = function()
	{
		if( (xmlhttp.readyState == 4) && (xmlhttp.status == 200) )
		{
			try
            {
            	result = xmlhttp.responseXML.documentElement.getElementsByTagName("res")[0];
            	if (result.firstChild.nodeValue == 'OK') {

            		// 파싱
            		var result2 = xmlhttp.responseXML.documentElement.getElementsByTagName("text")[0];
					
            		var text = result2.firstChild.nodeValue;
					//console.log (text);

					if (text == "done" || text == "URC MESSAGE")
					{
						document.getElementById('message').innerHTML='다시 시도해 주십시오..';
						return;
					}

					var wcdma_table = document.getElementById("wcdma");
					console.log(wcdma_table);
					var trimText = trim(text);
					var textArr = trimText.split(",");
					console.log(textArr);
					for (var i=0; i<textArr.length; i++)
					{
						var rowlen;
						var row;

						var key = keys[i];
						var value;
						var special_value;

						if (i < 9)
						{
							value = textArr[i];
							console.log(value);
							row = wcdma_table.insertRow(-1);
							row.insertCell(0).innerHTML = "<td class='center'><p>" + key + "</p></td>";
							row.cells[0].setAttribute('class', 'center');
							row.insertCell(1).innerHTML = "<td class='center'><p>" + value + "</p></td>";
							row.cells[1].setAttribute('class', 'center');
						} else if (i == 9)
						{
							special_value = textArr[i];
						} else if (i == 10)
						{
							special_value += ", " + textArr[i];
							console.log(special_value);
							row = wcdma_table.insertRow(-1);
							row.insertCell(0).innerHTML = "<td class='center'><p>" + key + "</p></td>";
							row.cells[0].setAttribute('class', 'center');
							row.insertCell(1).innerHTML = "<td class='center'><p>" + special_value + "</p></td>";
							row.cells[1].setAttribute('class', 'center');
						} else {
							value = textArr[i];
							console.log(value);
							row = wcdma_table.insertRow(-1);
							row.insertCell(0).innerHTML = "<td class='center'><p>" + key + "</p></td>";
							row.cells[0].setAttribute('class', 'center');
							row.insertCell(1).innerHTML = "<td class='center'><p>" + value + "</p></td>";
							row.cells[1].setAttribute('class', 'center');
						}
						
						
					}

					loadpppIP();
            	} else {
            		// error
					document.getElementById('message').innerHTML='';
            		alert(result.firstChild.nodeValue);
					//loadCnum();
            	}
            }
            catch(e)
            {

            }
		}
	}
	xmlhttp.send();
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
						macaddr = interfaces[i].getElementsByTagName("MACADDR")[0].firstChild.nodeValue;
						
						if (ifname != "eth0" && ifname != "usb0")
						{
							var table = document.getElementById("lan");
							var rowlen = table.rows.length;
							var row = table.insertRow(-1);
						
							row.insertCell(0).innerHTML = "<td class='center'><p>" + ifname + "</p></td>";
							row.insertCell(1).innerHTML = "<td class='center'><p>" + ipaddr + "</p></td>";
							row.insertCell(2).innerHTML = "<td class='center'><p>" + netmask + "</p></td>"
							row.insertCell(3).innerHTML = "<td class='center'><p>" + macaddr + "</p></td>";
						
							for(j = 0 ; j < row.cells.length ; j++)
							{
								row.cells[j].setAttribute('class', 'center');
							}
						}
				}
				
				interfaces = xmlhttp.responseXML.documentElement.getElementsByTagName("PTP");
				for(i = 0 ; i < interfaces.length ; i++)
				{
						ifname 	= interfaces[i].getElementsByTagName("IFNAME")[0].firstChild.nodeValue;
						ipaddr  = interfaces[i].getElementsByTagName("IPADDR")[0].firstChild.nodeValue;
						netmask = interfaces[i].getElementsByTagName("NETMASK")[0].firstChild.nodeValue;

						//peer 		= interfaces[i].getElementsByTagName("PEER")[0].firstChild.nodeValue;
			
						if (ifname != "eth0" && ifname != "usb0")
						{	
							var table = document.getElementById("wwan");
							var rowlen = table.rows.length;
							var row = table.insertRow(-1);
						
							row.insertCell(0).innerHTML = "<td class='center'><p>" + ifname + "</p></td>";
							row.insertCell(1).innerHTML = "<td class='center'><p>" + ipaddr + "</p></td>";
							//row.insertCell(2).innerHTML = "<td class='center'><p>" + netmask + "</p></td>"
							//row.insertCell(3).innerHTML = "<td class='center'><p>" + peer + "</p></td>";;
	
							for(j = 0 ; j < row.cells.length ; j++)
							{
								row.cells[j].setAttribute('class', 'center');
							}
						}
				}
				usim_socket_status();
				//loadpppData();
				//loadUsimInfo();
				//loadNetworkState();
			}
			catch(e)
			{
			}
		}
	}
	xmlhttp.send();
	
}


function loadpppData()
{
	if(typeof window.ActiveXObject != 'undefined')
	{
		xmlhttp = (new ActiveXObject("Microsoft.XMLHTTP"));
	}
	else
	{
		xmlhttp = (new XMLHttpRequest());
	}
	
	var data = "/cgi-bin/getdata?cmd=state";

	xmlhttp.open( "POST", data, true );
	xmlhttp.setRequestHeader("Content-Type","application/x-www-form-urlencoded;charset=euc-kr");
	xmlhttp.onreadystatechange = function()
	{
		
		if( (xmlhttp.readyState == 4) && (xmlhttp.status == 200) )
		{
			try
            {
            	result = xmlhttp.responseXML.documentElement.getElementsByTagName("res")[0];
            	if (result.firstChild.nodeValue == 'OK') {

            		// 파싱
            		var resultNode = xmlhttp.responseXML.documentElement.getElementsByTagName("text")[0];
					if (resultNode.firstChild != null)
					{
						var result = resultNode.firstChild.nodeValue;
						var resultArr = result.split(" ");	
						var rx_data = resultArr[0];
						var tx_data = resultArr[1];
						var rx = document.getElementById("rx_data");
						var tx = document.getElementById("tx_data");
						rx.innerHTML = bytesToSize(rx_data);
						tx.innerHTML = bytesToSize(tx_data);
					}
					
					//loadUsimInfo();
					loadUsimStatus();
            	} else {
            		// error
					//loadUsimInfo();
					loadUsimStatus();
            	}
            }
            catch(e)
            {

            }
		}
	}
	xmlhttp.send();
}

function loadUsimStatus()
{
	document.getElementById('message').innerHTML='잠시만 기다려 주십시오..';
	if(typeof window.ActiveXObject != 'undefined')
	{
		xmlhttp = (new ActiveXObject("Microsoft.XMLHTTP"));
	}
	else
	{
		xmlhttp = (new XMLHttpRequest());
	}
	
	var data = "/cgi-bin/usim?cmd=state_status";

	xmlhttp.open( "POST", data, true );
	xmlhttp.setRequestHeader("Content-Type","application/x-www-form-urlencoded;charset=euc-kr");
	xmlhttp.onreadystatechange = function()
	{
		if( (xmlhttp.readyState == 4) && (xmlhttp.status == 200) )
		{
			try
            {
            	result = xmlhttp.responseXML.documentElement.getElementsByTagName("res")[0];
            	if (result.firstChild.nodeValue == 'OK') {

            		// 파싱
            		var resultNode = xmlhttp.responseXML.documentElement.getElementsByTagName("text")[0];
					var result = resultNode.firstChild.nodeValue;
					var label = document.getElementById("usim_status");
					//result = "false"
					if (result == "true")
					{
						loadNwcause();
						usim=true;
					} else if (result == "false")
					{
						label.innerHTML = "미개통"
						usim=false;
						loadNetworkState();
					}

            	} else {
            		// error
            		alert("Please Refresh..");
            	}
            }
            catch(e)
            {

            }
		}
	}
	xmlhttp.send();
}

var refresh_count = 0;
function loadNwcause()
{
	document.getElementById('message').innerHTML='잠시만 기다려 주십시오..';
	if(typeof window.ActiveXObject != 'undefined')
	{
		xmlhttp = (new ActiveXObject("Microsoft.XMLHTTP"));
	}
	else
	{
		xmlhttp = (new XMLHttpRequest());
	}
	
	var data = "/cgi-bin/usim?cmd=state_nwcause";

	xmlhttp.open( "POST", data, true );
	xmlhttp.setRequestHeader("Content-Type","application/x-www-form-urlencoded;charset=euc-kr");
	xmlhttp.onreadystatechange = function()
	{
		if( (xmlhttp.readyState == 4) && (xmlhttp.status == 200) )
		{
			try
            {
            	result = xmlhttp.responseXML.documentElement.getElementsByTagName("res")[0];
            	if (result.firstChild.nodeValue == 'OK') {

            		// 파싱
            		var resultNode = xmlhttp.responseXML.documentElement.getElementsByTagName("text")[0];
					var result = resultNode.firstChild.nodeValue;
					var label = document.getElementById("usim_status");
					//result = "false"

					if (result == "2")
					{
						loadUsimInfo();
						return;
					} else {
						label.innerHTML = "발신정지"
						alert("단말이 발신정지 상태입니다.\n고객센터에 연락하여 발신정지 해지를 요청하십시오.\n발신정지가 해지되면 단말을 재부팅 해주십시오.");
						loadNetworkState();
					}
            	} else {
            		// error
            		alert("Please Refresh..");
            	}
            }
            catch(e)
            {

            }
		}
	}
	xmlhttp.send();
}

function loadpppIP()
{
	if(typeof window.ActiveXObject != 'undefined')
	{
		xmlhttp = (new ActiveXObject("Microsoft.XMLHTTP"));
	}
	else
	{
		xmlhttp = (new XMLHttpRequest());
	}
	
	var data = "/cgi-bin/pppip?cmd=state";

	xmlhttp.open( "POST", data, true );
	xmlhttp.setRequestHeader("Content-Type","application/x-www-form-urlencoded;charset=euc-kr");
	xmlhttp.onreadystatechange = function()
	{
		
		if( (xmlhttp.readyState == 4) && (xmlhttp.status == 200) )
		{
			try
            {
            	result = xmlhttp.responseXML.documentElement.getElementsByTagName("res")[0];
            	if (result.firstChild.nodeValue == 'OK') {

            		// 파싱
            		var resultNode = xmlhttp.responseXML.documentElement.getElementsByTagName("text")[0];
					if (resultNode.firstChild != null)
					{
						var result = resultNode.firstChild.nodeValue;
						//alert(result);

						var table = document.getElementById("wwan");
						var rowlen = table.rows.length;
						var row = table.insertRow(-1);
						
						row.insertCell(0).innerHTML = "<td class='center'><p>" + "ppp0" + "</p></td>";
						row.insertCell(1).innerHTML = "<td class='center'><p>" + result + "</p></td>";
						//row.insertCell(2).innerHTML = "<td class='center'><p>" + "255.255.255.0" + "</p></td>"
						//row.insertCell(3).innerHTML = "<td class='center'><p>" + peer + "</p></td>";;

						for(j = 0 ; j < row.cells.length ; j++)
						{
							row.cells[j].setAttribute('class', 'center');
						}
					}
					document.getElementById('message').innerHTML='';
            	} else {
            		document.getElementById('message').innerHTML='';
            	}
            }
            catch(e)
            {

            }
		}
	}
	xmlhttp.send();
}

function bytesToSize(bytes) {
   var k = 1000;
   var sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB'];
   if (bytes == 0) return '0 Bytes';
   var i = parseInt(Math.floor(Math.log(bytes) / Math.log(k)),10);
   return (bytes / Math.pow(k, i)).toPrecision(3) + ' ' + sizes[i];
}
