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

	document.getElementById('section1_title').innerHTML='APN 설정';
	document.getElementById('page_title').innerHTML='APN 설정';
	document.getElementById('apply').value='적용';
	document.getElementById('body').hidden = false;
	
}

function onLoad()
{
	onInit();
	loadAPN();
}

function loadAPN()
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
	
	var data = "/cgi-bin/apn?cmd=state";

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

					if (apn == "done" || apn=="URC MESSAGE")
					{
						//alert("Please Refresh..");
						document.getElementById('message').innerHTML='다시 시도해 주십시오..';
						return;
					}
					document.getElementById('message').innerHTML='';
					var trimText = trim(text);
					var textArr = trimText.split(",");
					var apn_tf = document.getElementById("apn");
					apn_tf.value = textArr[1];

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

function setAPN()
{
	if (confirm("설정 후 재부팅을 시작합니다."))
	{
		if(typeof window.ActiveXObject != 'undefined') {
			xmlhttp = (new ActiveXObject("Microsoft.XMLHTTP"));
		} else {
			xmlhttp = (new XMLHttpRequest());
		}
		
		//var sms_select = document.getElementById("smsSelect");
		var data = "/cgi-bin/apn?cmd=set"

		//var cid_select = document.getElementById("cidSelect");
		var apn_tf = document.getElementById("apn");

		data += "&cid=0"; //cid_select[cid_select.selectedIndex].value;
		//data += "&pdp_type=IP";
		data += "&apn=" + apn_tf.value;
		
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
						alert("재부팅을 시작합니다.");
						onSystemRestart();
					} else {
						alert("APN : ERROR");
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
