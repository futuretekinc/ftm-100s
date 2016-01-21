var	msg;
var	msgConfirmStart = 0;
var msgConfirmStarting = 1;
var msgConfirmSuccess=2;
var msgRestartFail=3;
var msgIMEIFail=4;

var msgPPPDSuccess=5;
var msgPPPDFail=6;
var msgModemSuccess=7;
var msgModemFail=8;

function onInit()
{
	msg = new Array();
	msg[msgConfirmStart] = "OTA 인증을 시작 하시겠습니까?";
	msg[msgConfirmStarting] = '인증을 시작합니다.\n잠시만 기다려 주십시오.[최대 1분]';
	msg[msgConfirmSuccess] = '인증이 완료되었습니다.';
	msg[msgRestartFail] = '인증이 실패하였습니다.\n 다시 인증을 시도하시겠습니까?';
	msg[msgIMEIFail] = '인증이 중단되었습니다.\n IMEI 등록이 안된 USIM입니다.';

	msg[msgPPPDSuccess] = 'pppd 가 중단되었습니다.';
	msg[msgPPPDFail] = 'pppd 중단이 실패되었습니다.';
	msg[msgModemSuccess] = 'modem 이 재시작되었습니다.';
	msg[msgModemFail] = 'modem 재시작이 실패되었습니다.';

	//msg[msgRestartFailed] = '시스템 재시작을 실패 하였습니다.\n잠시 후 다시 시도해 주십시오.';
	document.getElementById('page_title').innerHTML = 'IOT 인증';
	document.getElementById('section1_title').innerHTML='Test Mode';
	document.getElementById('ota_label').innerHTML='OTA 인증 : ';
	//document.getElementById('ota_info').innerHTML='OTA 인증을 시작 하시려면, 아래의 버튼을 누르시기 바랍니다.';
	//document.getElementById('btn_ota').value = '인증';
	
		
	document.getElementById('body').hidden = false;
}

function onLoad()
{
	onInit();
	enablePageTimeout();
}

function onOTAButtonClick()
{
	if (confirm(msg[msgConfirmStart]))
	{
		if (confirm(msg[msgConfirmStarting]))
		{
			onOTAConfirm();
		}
	}
}

function onPPPDClick()
{
	if(typeof window.ActiveXObject != 'undefined')
	{
		xmlhttp = (new ActiveXObject("Microsoft.XMLHTTP"));
	}
	else
	{
		xmlhttp = (new XMLHttpRequest());
	}
	
	var data = "/cgi-bin/ota?cmd=pppd";
	
	xmlhttp.open( "POST", data, true );
	xmlhttp.setRequestHeader("Content-Type","application/x-www-form-urlencoded;charset=euc-kr");
	xmlhttp.onreadystatechange = function()
	{
		if( (xmlhttp.readyState == 4) && (xmlhttp.status == 200) )
		{
			try
			{
				result	= xmlhttp.responseXML.documentElement.getElementsByTagName("RESULT")[0];
				if (result.firstChild.nodeValue == 'OK')
				{
					alert(msg[msgPPPDSuccess]);
				}
				else
				{
					alert(msg[msgPPPDFail]);
				}
			}
			catch(e)
			{
				//window.location.href = '/';
			}
		}
	}
	xmlhttp.send();
}

function onModemClick()
{
	if(typeof window.ActiveXObject != 'undefined')
	{
		xmlhttp = (new ActiveXObject("Microsoft.XMLHTTP"));
	}
	else
	{
		xmlhttp = (new XMLHttpRequest());
	}
	
	var data = "/cgi-bin/ota?cmd=modem";
	
	xmlhttp.open( "POST", data, true );
	xmlhttp.setRequestHeader("Content-Type","application/x-www-form-urlencoded;charset=euc-kr");
	xmlhttp.onreadystatechange = function()
	{
		if( (xmlhttp.readyState == 4) && (xmlhttp.status == 200) )
		{
			try
			{
				result	= xmlhttp.responseXML.documentElement.getElementsByTagName("RESULT")[0];
				if (result.firstChild.nodeValue == 'OK')
				{
					alert(msg[msgModemSuccess]);
				}
				else
				{
					alert(msg[msgModemFail]);
				}
			}
			catch(e)
			{
				//window.location.href = '/';
			}
		}
	}
	xmlhttp.send();
}

function waitingPopup()
{
	var popup = window.open('','pop','width=200px, height=10px'),
        popdoc, msg, script;
    if (popup) {
        popdoc = popup.document;
        msg = popdoc.body.appendChild(popdoc.createElement('p'));
        msg.innerHTML = 'Please, wait until process has finished.';
        script = popdoc.createElement('script');
        script.text = '(function () {setTimeout(function () {self.close();}, 5000);}());';
        popdoc.body.appendChild(script);
    }
}

function onOTAConfirm()
{
	if(typeof window.ActiveXObject != 'undefined')
	{
		xmlhttp = (new ActiveXObject("Microsoft.XMLHTTP"));
	}
	else
	{
		xmlhttp = (new XMLHttpRequest());
	}
	
	var data = "/cgi-bin/ota?cmd=ota";
	
	xmlhttp.open( "POST", data, true );
	xmlhttp.setRequestHeader("Content-Type","application/x-www-form-urlencoded;charset=euc-kr");
	xmlhttp.onreadystatechange = function()
	{
		if( (xmlhttp.readyState == 4) && (xmlhttp.status == 200) )
		{
			try
			{
				result	= xmlhttp.responseXML.documentElement.getElementsByTagName("RESULT")[0];
				if (result.firstChild.nodeValue == 'SUCCESS')
				{
					alert(msg[msgConfirmSuccess]);
				}
				else if (result.firstChild.nodeValue == 'STOP')
				{
					alert(msg[msgIMEIFail]);
				}
				else
				{
					if (confirm(msg[msgRestartFail])) {
						onOTAConfirm();
					}
				}
			}
			catch(e)
			{
				//window.location.href = '/';
			}
		}
		//alert(xmlhttp.responseText);
	}
	xmlhttp.send();
}