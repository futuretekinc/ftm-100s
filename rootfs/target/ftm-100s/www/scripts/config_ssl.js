var	msgApplyOK = 0;
var	msgApplyFailed = 1;
var msgConfirm = 2;
var	msg;
var refresh_count = 0;

function onInit()
{
	msg = new Array();

	msg[msgApplyOK] = '네트워크 정보가 정상적으로 변경되었습니다.';
	msg[msgApplyFailed] = '네트워크 정보 변경에 문제가 발생하였습니다.';
	msg[msgConfirm] = '네트워크 정보를 수정하고 시스템을 다시 시작하시겠습니까?';

	document.getElementById('section_title').innerHTML='SSL 설정';
	document.getElementById('page_title').innerHTML='SSL 설정';
	document.getElementById('apply').value='적용';
	document.getElementById('body').hidden = false;
	
}

function onLoad()
{
	onInit();
	loadSSL();
}

function loadSSL()
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
	
	var data = "/cgi-bin/ssl?cmd=status";

	xmlhttp.open( "POST", data, true );
	xmlhttp.setRequestHeader("Content-Type","application/x-www-form-urlencoded;charset=euc-kr");
	xmlhttp.onreadystatechange = function()
	{
		if( (xmlhttp.readyState == 4) && (xmlhttp.status == 200) )
		{
			try
			{
				xml = xmlhttp.responseXML.documentElement; ;
				console.log(xml.getElementsByTagName("USER")[0].firstChild.nodeValue);
				document.getElementById('user').value = xml.getElementsByTagName("USER")[0].firstChild.nodeValue;
				document.getElementById('password').value = xml.getElementsByTagName("PASSWD")[0].firstChild.nodeValue;
				document.getElementById('server_ip').value = xml.getElementsByTagName("SERVER_IP")[0].firstChild.nodeValue;
				document.getElementById('server_port').value = xml.getElementsByTagName("SERVER_PORT")[0].firstChild.nodeValue;
				document.getElementById('interval').value = xml.getElementsByTagName("INTERVAL")[0].firstChild.nodeValue;
				document.getElementById('message').innerHTML="";
			} catch(e) {
				alert("Please Refresh..");
			}
		}
	}
	xmlhttp.send();
}


function setSSL()
{
	//if (confirm("재부팅이 필요할지 모름???"))
	//{
		if(typeof window.ActiveXObject != 'undefined') {
			xmlhttp = (new ActiveXObject("Microsoft.XMLHTTP"));
		} else {
			xmlhttp = (new XMLHttpRequest());
		}
		
		var data = "/cgi-bin/ssl?cmd=set"

		var traffic_select = document.getElementById("trafficSelect");
		var user = document.getElementById("user");
		var passwd = document.getElementById("password");
		var ip = document.getElementById("server_ip");
		var port = document.getElementById("server_port");
		var interval = document.getElementById("interval");

		data += "&user=" + user.value;
		data += "&passwd=" + passwd.value;
		data += "&ip=" + ip.value;
		data += "&port=" + port.value;
		data += "&interval=" + interval.value;
		
		xmlhttp.open( "POST", data, true );
		xmlhttp.setRequestHeader("Content-Type","application/x-www-form-urlencoded;charset=euc-kr");
		xmlhttp.onreadystatechange = function()
		{
			if( (xmlhttp.readyState == 4) && (xmlhttp.status == 200) )
			{
				try
				{
					result = xmlhttp.responseXML.documentElement.getElementsByTagName("RET")[0];
					
					if (result.firstChild.nodeValue == 'OK') {
						alert("변경되었습니다.");
					} else {
						alert("변경되지 않았습니다.");
					}
				}
				catch(e)
				{

				}
			}
		}
		xmlhttp.send();
	//}
}
