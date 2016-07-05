var	msgApplyOK = 0;
var	msgApplyFailed = 1;
var msgConfirm = 2;
var	msg;
var refresh_count = 0;

function onInit()
{
	msg = new Array();

	msg[msgApplyOK] = 'WIFI 정보가 정상적으로 변경되었습니다.';
	msg[msgApplyFailed] = 'WIFI 정보 변경에 문제가 발생하였습니다.';
	msg[msgConfirm] = 'WIFI 정보를 수정하고 시스템을 다시 시작하시겠습니까?';

	document.getElementById('section2_title').innerHTML='WIFI 설정';
	document.getElementById('page_title').innerHTML='WIFI 설정';
	document.getElementById('apply').value='적용';
	document.getElementById('body').hidden = false;
	document.getElementById('enable').innerHTML="<input type='checkbox' name='enable'>사용";
	
}

function onLoad()
{
	onInit();
	loadWIFI();
}

function loadWIFI()
{
	if(typeof window.ActiveXObject != 'undefined')
	{
		xmlhttp = (new ActiveXObject("Microsoft.XMLHTTP"));
	}
	else
	{
		xmlhttp = (new XMLHttpRequest());
	}
	
	var data = "/cgi-bin/wifi?cmd=status";

	xmlhttp.open( "POST", data, true );
	xmlhttp.setRequestHeader("Content-Type","application/x-www-form-urlencoded;charset=euc-kr");
	xmlhttp.onreadystatechange = function()
	{
		if( (xmlhttp.readyState == 4) && (xmlhttp.status == 200) )
		{
			try
			{
				stat = xmlhttp.responseXML.documentElement.getElementsByTagName("status")[0];
				ssid = xmlhttp.responseXML.documentElement.getElementsByTagName("essid")[0];
				pw = xmlhttp.responseXML.documentElement.getElementsByTagName("key")[0];

				if (stat.firstChild.nodeValue == 'enabled')
				{
					document.f.enable.checked = true;
				} else {
					document.f.enable.checked = false;
				}

				var ssidTF = document.getElementById("wifi_ssid");
				var pwTF = document.getElementById("wifi_pw");
				ssidTF.value = ssid.firstChild.nodeValue;

				var pwSplitArr = pw.firstChild.nodeValue.split(":");
				pwTF.value = pwSplitArr[1];
			} catch(e) {
			}
		}
	}
	xmlhttp.send();
}

function setWIFI()
{
	if (document.f.wifi_pw.value.length < 5)
	{
		alert("패스워드를 5자 맞추어 작성해주십시오.");
		document.f.wifi_pw.value = "";
	} else {
		if (confirm("확인 후 OK 팝업이 나타나면 WIFI에 접속하시길 바랍니다."))
		{
			if(typeof window.ActiveXObject != 'undefined') {
				xmlhttp = (new ActiveXObject("Microsoft.XMLHTTP"));
			} else {
				xmlhttp = (new XMLHttpRequest());
			}
			
			var data = "/cgi-bin/wifi?cmd=set"
			data += "&wifi_ssid=" + document.f.wifi_ssid.value;
			data += "&wpa_passphrase=" + document.f.wifi_pw.value;
			data += "&status=" + document.f.enable.checked;
			
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
							alert("WIFI : OK");
						} else {
							alert("WIFI : ERROR");
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
}