var msgMissFileName=0;
var msgReset=1;
var msgRestore=2;
var msgRestoreReset=3;
var msg;

function onInit()
{
	document.getElementById('page_title').innerHTML = "설정 백업 / 복구";
	document.getElementById('section1_title').innerHTML = "설정 백업 / 복구";
	document.getElementById('config_backup').innerHTML = "모든 설정을 설정파일로 저장하여 PC로 다운로드합니다. PC에 저장된 설정파일은 설정 복구시 사용됩니다.";
	document.getElementById('config_restore').innerHTML = "PC에 저장해둔 설정파일을 이용해 설정을 복구합니다.";
	document.getElementById('config_init').innerHTML = "시스템의 모든 설정이 초기화된 후 다시 시작 됩니다.";
	document.getElementById('btn_backup').value = "설정 파일 백업";
	document.getElementById('btn_restore').value = "설정 파일 복구";
	document.getElementById('btn_init').value = "초기 설정 복원";

	msg = new Array();
	msg[msgMissFileName] = "미지원 파일 형식입니다.\n확인 후 다시 시도해 주십시오.";
	msg[msgReset] 		 = "시스템을 공장초기화 상태로 설정하시겠습니까?";
	msg[msgRestore] 	 = "시스템을 복구 하시겠습니까?";
	msg[msgRestoreReset] = "시스템이 재시작합니다..";
	document.getElementById('body').hidden = false;
}

function onLoad()
{
	onInit();
}

function configBackup()
{
	self.location.href = "/cgi-bin/config?cmd=backup";
}

function configRestore()
{
	var file_btn = document.getElementById('btn_file');
	var f_name = file_btn.value.substring(file_btn.value.lastIndexOf("\\")+1);

	if (f_name != "config.tar.gz")
	{
		alert(msg[msgMissFileName]);
		return;
	}
	
	if (confirm(msg[msgRestore]))
	{
		alert(msg[msgRestoreReset]);
		var upload_form = document.getElementById('upload_form');
		upload_form.submit();
	}
}

function systemInit()
{
	/*
		var file_btn = document.getElementById('btn_init');

		if (confirm(msg[msgReset]))
		{
				alert(msg[msgRestoreReset]);
				self.location.href = "/cgi-bin/init?cmd=init";
		}
		*/
	if (confirm(msg[msgReset]))
	{
		if(typeof window.ActiveXObject != 'undefined')
		{
			xmlhttp = (new ActiveXObject("Microsoft.XMLHTTP"));
		}
		else
		{
			xmlhttp = (new XMLHttpRequest());
		}
		
		var data = "/cgi-bin/init?cmd=init";
		
		xmlhttp.open( "POST", data, true );
		xmlhttp.setRequestHeader("Content-Type","application/x-www-form-urlencoded;charset=euc-kr");
		xmlhttp.onreadystatechange = function()
		{
			if( (xmlhttp.readyState == 4) && (xmlhttp.status == 200) )
			{
				try
				{
					res = xmlhttp.responseXML.documentElement.getElementsByTagName("res")[0].firstChild.nodeValue;
					if (res == "OK")
					{
						// reboot
						alert(msg[msgRestoreReset]);
						onSystemRestart();
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