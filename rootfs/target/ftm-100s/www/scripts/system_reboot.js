var	msg;
var	msgConfirmRestart = 0;
var msgResetaring = 1;
var msgRestartFailed=2;
function onInit()
{
	msg = new Array();
	msg[msgConfirmRestart] = "시스템을 재시작 하시겠습니까?";
	msg[msgResetaring] = '시스템 재시작 중입니다.\n잠시 후 재시작해 주시기 바랍니다.[최대 30초]';
	msg[msgRestartFailed] = '시스템 재시작을 실패 하였습니다.\n잠시 후 다시 시도해 주십시오.';
	document.getElementById('page_title').innerHTML = '시스템 관리';
	document.getElementById('section1_title').innerHTML='시스템 재시작';
	document.getElementById('restart_info').innerHTML='시스템 재시작을 원하시면, 아래의 버튼을 누르시기 바랍니다.';
	document.getElementById('btn_restart').value = '재시작';
	
		
	document.getElementById('body').hidden = false;
}

function onLoad()
{
	onInit();
	enablePageTimeout();
}


function onSystemRestart()
{
	if (confirm(msg[msgConfirmRestart]))
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
}

