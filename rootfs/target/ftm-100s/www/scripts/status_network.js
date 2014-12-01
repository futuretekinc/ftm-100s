<!-- Network Status -->
var usim=true;

function onInit()
{
	document.getElementById('page_title').innerHTML = '네트워크 상태 정보';
	document.getElementById('section1_title').innerHTML = '무선 접속 정보';
	document.getElementById('section2_title').innerHTML = '내부 포트 정보';
	document.getElementById('section3_title').innerHTML = 'LTE 정보';
	document.getElementById('usim_label').innerHTML = 'USIM 상태';
	document.getElementById('usage').innerHTML = '데이터 사용량 정보';
	document.getElementById('rx').innerHTML = '다운로드 사용량';
	document.getElementById('tx').innerHTML = '업로드 사용량';
	document.getElementById('link').innerHTML = 'KT Link';
	document.getElementById('usage_label').innerHTML = '(실제 데이터양과 다를 수 있음.)';
	document.getElementById('name1').innerHTML = '포트';
	document.getElementById('ipaddr1').innerHTML = 'IP 주소';
	document.getElementById('netmask1').innerHTML = '서브넷마스크';
	//document.getElementById('ptpaddr1').innerHTML = 'P-to-P 서버';
	document.getElementById('name2').innerHTML = '포트';
	document.getElementById('ipaddr2').innerHTML = 'IP 주소';
	document.getElementById('netmask2').innerHTML = '서브넷마스크';
	document.getElementById('macaddr2').innerHTML = 'MAC 주소';
	document.getElementById('body').hidden = false;
	document.getElementById('netmask1').hidden = true;
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
				
				loadpppData();
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

function loadNetworkState()
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

					if (text == "done" || text == "URC MESSAGE")
					{
						document.getElementById('message').innerHTML='다시 시도해 주십시오..';
						return;
					}

					var wcdma_table = document.getElementById("wcdma");
					var lte_table = document.getElementById("lte");

					var trimText = trim(text);
					var textArr = trimText.split(",");

					var modem_state= document.getElementById("modem_state");
					modem_state.innerHTML = textArr[0];

					if (textArr[0] == "[LTE]")
					{
						for (var i=0; i<23; i++)
						{
							var key = textArr[i].split(":")[0];
							var trimKey = trim(key);
							var value;
							if (trimKey == "[WCDMA]" || trimKey == "[LTE]")
							{
								value = "subject";
							} else {
								value = textArr[i].split(":")[1];

								var rowlen;
								var row;
								rowlen = wcdma_table.rows.length;
								row = wcdma_table.insertRow(-1);
								row.insertCell(0).innerHTML = "<td class='center'><p>" + trimKey + "</p></td>";
								row.cells[0].setAttribute('class', 'center');
								row.insertCell(1).innerHTML = "<td class='center'><p>" + value + "</p></td>";
								row.cells[1].setAttribute('class', 'center');
							}
						}
					} else {
						for (var i=0; i<29; i++)
						{
							var key = textArr[i].split(":")[0];
							var trimKey = trim(key);
							var value;
							if (trimKey == "[WCDMA]" || trimKey == "[LTE]")
							{
								value = "subject";
							} else {
								value = textArr[i].split(":")[1];

								var rowlen;
								var row;
								rowlen = wcdma_table.rows.length;
								row = wcdma_table.insertRow(-1);
								row.insertCell(0).innerHTML = "<td class='center'><p>" + trimKey + "</p></td>";
								row.cells[0].setAttribute('class', 'center');
								row.insertCell(1).innerHTML = "<td class='center'><p>" + value + "</p></td>";
								row.cells[1].setAttribute('class', 'center');
							}
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

function loadCnum()
{
	if(typeof window.ActiveXObject != 'undefined')
	{
		xmlhttp = (new ActiveXObject("Microsoft.XMLHTTP"));
	}
	else
	{
		xmlhttp = (new XMLHttpRequest());
	}
	
	var data = "/cgi-bin/cnum?cmd=state";

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
            		var result2 = xmlhttp.responseXML.documentElement.getElementsByTagName("num")[0];
					var table = document.getElementById("3g");
					var rowlen = table.rows.length;
					var row = table.rows[1];

					switch (result2.firstChild.nodeValue)
					{
						case "+CME ERROR: 10":
							row.insertCell(18).innerHTML = "<td class='center'><p>" + "SIM not inserted.." + "</p></td>";
						break;
						case "+CME ERROR: 11":
							row.insertCell(18).innerHTML = "<td class='center'><p>" + "SIM PIN required.." + "</p></td>";
						break;
						case "+CME ERROR: 13":
							row.insertCell(18).innerHTML = "<td class='center'><p>" + "SIM failure.." + "</p></td>";
						break;
						case "+CME ERROR: 14":
							row.insertCell(18).innerHTML = "<td class='center'><p>" + "SIM busy.." + "</p></td>";
						break;
						case "+CME ERROR: 15":
							row.insertCell(18).innerHTML = "<td class='center'><p>" + "SIM wrong.." + "</p></td>";
						break;
						default:
							if (usim == true)
							{	
								var trimNumText = trim(result2.firstChild.nodeValue);					
								var phoneNum;

								if (trimNumText == "done")
								{
									phoneNum = "refresh.."
								} else {
									var textNumArr = trimNumText.split("||");
									var NUM_ATCOMMAND = textNumArr[0].split(":")[0];
									var NUM_ATCOMMAND_RES = textNumArr[0].split(":")[1];
									phoneNum = NUM_ATCOMMAND_RES.split(",")[1];
								}
								document.getElementById('message').innerHTML='';
								row.insertCell(18).innerHTML = "<td class='center'><p>" + phoneNum + "</p></td>";
							} else {
								phoneNum = "미개통"
								document.getElementById('message').innerHTML='';
								row.insertCell(18).innerHTML = "<td class='center'><p>" + phoneNum + "</p></td>";
							}
						break;
					}
					row.cells[18].setAttribute('class', 'center');

            	} else {
            		// error
            		//alert("Please Refresh..");
					document.getElementById('message').innerHTML='다시 시도해 주십시오..';
					//alert(result.firstChild.nodeValue);
            	}
            }
            catch(e)
            {

            }
		}
	}
	xmlhttp.send();
}

function loadUsimInfo()
{
	//document.getElementById('message').innerHTML='잠시만 기다려 주십시오..';
	if(typeof window.ActiveXObject != 'undefined')
	{
		xmlhttp = (new ActiveXObject("Microsoft.XMLHTTP"));
	}
	else
	{
		xmlhttp = (new XMLHttpRequest());
	}
	
	var data = "/cgi-bin/usim?cmd=state";

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
					}

					var label = document.getElementById("usim_status");
					switch (result)
					{
						case "+CPIN: READY":
							label.innerHTML = "SIM is Ready..";
							//loadNetworkState();
						break;
						case "+CME ERROR: 10":
							label.innerHTML = "SIM not inserted..";
							//loadNetworkState();
						break;
						case "+CME ERROR: 11":
							label.innerHTML = "SIM PIN required..";
						break;
						case "+CME ERROR: 13":
							label.innerHTML = "SIM failure..";
							//loadNetworkState();
						break;
						case "+CME ERROR: 14":
							label.innerHTML = "SIM busy..";
							//loadNetworkState();
						break;
						case "+CME ERROR: 15":
							label.innerHTML = "SIM wrong..";
							//loadNetworkState();
						break;
						case "false":
							alert("Please Refresh..");
						break;
					}
					loadNetworkState();

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
