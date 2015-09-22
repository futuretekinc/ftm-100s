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

	document.getElementById('page_title').innerHTML='ThingPlus 설정';
	document.getElementById('section1_title').innerHTML='API KEY 설정';
	document.getElementById('apply').value='적용';
	document.getElementById('body').hidden = false;
	
}

function onLoad()
{
	onInit();
	loadApiKey();
}

function loadApiKey()
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
	
	var data = "/cgi-bin/apikey?cmd=state";

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
            		var apikey = result2.firstChild.nodeValue;
					//alert(apikey);

					var apikey_tf = document.getElementById("apikey");
					if (apikey != "done")
					{
						apikey_tf.value = apikey.replace(/\"/g, '');
					} else {
						apikey_tf.value = "";
					}
					document.getElementById('message').innerHTML="";
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

function setApiKey()
{	
	if(typeof window.ActiveXObject != 'undefined') {
		xmlhttp = (new ActiveXObject("Microsoft.XMLHTTP"));
	} else {
		xmlhttp = (new XMLHttpRequest());
	}
	
	var data = "/cgi-bin/apikey?cmd=set"
	var apikey_tf = document.getElementById("apikey");
	data += "&api=" + apikey_tf.value;
	
	xmlhttp.open( "GET", data, true );
	xmlhttp.setRequestHeader("Content-Type","application/x-www-form-urlencoded;charset=euc-kr");
	xmlhttp.onreadystatechange = function()
	{
		if( (xmlhttp.readyState == 4) && (xmlhttp.status == 200) )
		{
			try
			{
				result = xmlhttp.responseXML.documentElement.getElementsByTagName("res")[0];
				if (result.firstChild.nodeValue == 'OK') {
					alert("apikey : OK");
				} else {
					alert("apikey : ERROR");
				}
			}
			catch(e)
			{

			}
		}
	}
	xmlhttp.send();
}
