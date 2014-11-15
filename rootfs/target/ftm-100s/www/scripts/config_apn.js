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
					var textArr = trimText.split("||");
					var ATCOMMAND = textArr[0].split(":")[0];
					var ATCOMMAND_RES = textArr[0].split(":")[1];

					var cid = ATCOMMAND_RES.split(",")[0];
					var pdp_type = ATCOMMAND_RES.split(",")[1];
					var apn = ATCOMMAND_RES.split(",")[2];
					var pdp_addr = ATCOMMAND_RES.split(",")[3];
					var d_comp = ATCOMMAND_RES.split(",")[4];
					var h_comp = ATCOMMAND_RES.split(",")[5];
					
					//qosArr = ATCOMMAND_RES.split(",");
					//alert(apn);
					var apn_tf = document.getElementById("apn");
					apn_tf.value = apn.replace(/\"/g, '');

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
	if (confirm("설정 후 전화접속을 다시 시도합니다.\n(약 10초에서 1분사이에 시간이 소요됩니다.)"))
	{
		if(typeof window.ActiveXObject != 'undefined') {
			xmlhttp = (new ActiveXObject("Microsoft.XMLHTTP"));
		} else {
			xmlhttp = (new XMLHttpRequest());
		}
		
		var sms_select = document.getElementById("smsSelect");
		var data = "/cgi-bin/apn?cmd=set"

		//var cid_select = document.getElementById("cidSelect");
		var apn_tf = document.getElementById("apn");

		data += "&cid=1"; //cid_select[cid_select.selectedIndex].value;
		data += "&pdp_type=IP";
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
						alert("APN : OK");
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
