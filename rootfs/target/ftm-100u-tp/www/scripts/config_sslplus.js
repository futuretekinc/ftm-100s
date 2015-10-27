<!-- DHCP Status -->
var	msg;
var	msgApplyOK=0;
var msgApplyFailed=1;
var	msgPasswordMismatch=2;

function onInit()
{
	msg = new Array();
	msg[msgApplyOK] = 'SSL 클라이언트가 정상적으로 설정 되었습니다.';
	msg[msgApplyFailed] = 'SSL 클라이언트 설정 변경에 문제가 발생하였습니다.';
	msg[msgPasswordMismatch]= "비밀번호가 일치하지 않습니다.\n확인 후 다시 시도해 주십시오."	
	
	document.getElementById('page_title').innerHTML ='SSL 설정';
	document.getElementById('section1_title').innerHTML ='클라이언트 설정';
	document.getElementById('enable').innerHTML="<input type='checkbox' name='enable'>사용";
	document.getElementById('userid').innerHTML ='사용자:';
	document.getElementById('passwd').innerHTML ='비밀번호:';
	document.getElementById('confirm_passwd').innerHTML ='비밀번호 확인:';
	document.getElementById('vpnip').innerHTML ='VPN IP 주소:';
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
	
	var data = "/cgi-bin/ssl?cmd=status";
	
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
				document.f.userid.value = element.getElementsByTagName("USERID")[0].firstChild.nodeValue;
				document.f.passwd.value = "";
				document.f.confirm_passwd.value = "";
				document.f.vpn_ip.value = element.getElementsByTagName("VPN_IP")[0].firstChild.nodeValue;
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
	if(document.f.passwd.value != document.f.confirm_passwd.value)
	{
		return	Error(msg[msgPasswordMismatch], document.f.passwd);
	}

	if (!IsValidIP(document.f.vpn_ip, false))
	{
		return	Error('Missing or invalid IP address.', document.f.vpn_ip);
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
	
	var data = "/cgi-bin/ssl?cmd=set";
	data += "&enable=" + document.f.enable.checked;
	data += "&userid=" + document.f.userid.value;
	data += "&passwd=" + document.f.passwd.value;
	data += "&vpn_ip=" + document.f.vpn_ip.value;

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
					alert(msg[msgApplyOK]);
				}
				else
				{
					msg = xmlhttp.responseXML.documentElement.getElementsByTagName("MSG")[0].firstChild.nodeValue;		
					alert(msg[msgApplyFailed] + msg);
				
				}
						
			}
			catch(e)
			{
			}
		}
	}
	xmlhttp.send();
}
