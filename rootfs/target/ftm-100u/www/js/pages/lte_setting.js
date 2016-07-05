/**
 * Created by kindmong on 2015-11-05.
 */
$(document).ready(function(){
    init();
});

function init() {
	$.li18n.currentLocale = 'kr';
    document.getElementById("menu_dashboard").innerHTML = _t('dashboard');
    document.getElementById("menu_sensors").innerHTML = _t('sensors');
    document.getElementById("menu_clouds").innerHTML = _t('clouds');
    document.getElementById("menu_network").innerHTML = _t('network');
    document.getElementById("menu_system").innerHTML = _t('system');

	document.getElementById("h_apn").innerHTML = _t('apn_setting');
	document.getElementById("modify_btn").innerHTML = _t('modify');

    $.ajax({
        type:"get",
        url:"/cgi-bin/apn?cmd=state",
        dataType:"xml",
        success : function(xml) {
            // 통신이 성공적으로 이루어졌을 때 이 함수를 타게 된다.
            // TODO
            $(xml).find("data").each(function(){
                console.log($(this).find("text").text());
                result = $(this).find("text").text();
                if (result == "done" || result == "URC MESSAGE") {
                    alert('다시 시도해 주십시오..');
                    return;
                }

                var textArr = result.split(",");
                var apn_tf = document.getElementById("apn");
                apn_tf.value = textArr[1];
            });
        },
        error : function(xhr, status, error) {
			//alert("에러발생");
			window.location.href="/";
        }
    });
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