/* Common Utilities */
function GetValue(obj) 
{
  return obj.value.replace(/\s/g, '');
}

function IsValidMAC(obj, empty) 
{
  var str = GetValue(obj);
  if (empty && str.length == 0) return true;
  return str.search(/^[0-9a-fA-F]{1,2}(:[0-9a-fA-F]{1,2}){5}$/) >= 0;
}

function IsValidIP(obj, empty) 
{
	var str = GetValue(obj);
	if (empty && str.length == 0)
	{
		return true;
	}
	
	var fields = str.match(/^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/);
	if (fields != null) 
	{
		var tmp = fields[1] | fields[2] | fields[3] | fields[4];
		return (tmp < 256) && (empty || tmp > 0);
	} 
	else 
	{
		return false;
	}
}

function IsValidPort(obj, empty) 
{
	var str = GetValue(obj);
	if (empty && str.length == 0)
	{
		return true;
	}
	
	var fields = str.match(/^(\d{1,5})$/);
	if (fields != null) 
	{
		return (fields[0] > 0);
	} 
	else 
	{
		return false;
	}
}

function	Error(msg, obj)
{
	alert(msg); 
	obj.focus(); 
	obj.select(); 
	
	return	false;
}

function trim(value){
	value = value.replace(/\s+/, "");//왼쪽 공백제거
	value = value.replace(/\s+$/g, "");//오른쪽 공백제거
	value = value.replace(/\n/g, "|");//행바꿈제거
	value = value.replace(/\r/g, "");//엔터제거
	return value;
}

function onLogout()
{
	var ret = confirm("로그아웃 하시겠습니까?");
	if (ret == true)
	{
		if(typeof window.ActiveXObject != 'undefined')
		{
			xmlhttp = (new ActiveXObject("Microsoft.XMLHTTP"));
		}
		else
		{
			xmlhttp = (new XMLHttpRequest());
		}
		
		var data = "/cgi-bin/logout";
		
		xmlhttp.open( "POST", data, true );
		xmlhttp.setRequestHeader("Content-Type","application/x-www-form-urlencoded;charset=euc-kr");
		xmlhttp.onreadystatechange = function()
		{
			if( (xmlhttp.readyState == 4) && (xmlhttp.status == 200) )
			{
				try
				{
						window.location.href="/";
				}
				catch(e)
				{
				}
			}
		}
		xmlhttp.send();
	}
}

//function onLoadPage(page)
//{
//	window.location.href = "/cgi-bin/page?cmd=" + page;
//}

function onMainLoad()
{
	onLoad();
	document.getElementById('status').innerHTML = '상태';
	document.getElementById('config').innerHTML = '설정';
	document.getElementById('system').innerHTML = '시스템';
	document.getElementById('status_network').innerHTML = '네트워크';
	document.getElementById('status_syslog').innerHTML = '로그';
	document.getElementById('config_network').innerHTML = '네트워크';
	//document.getElementById('config_wifi').innerHTML = 'WIFI';
	document.getElementById('config_firewall').innerHTML = '접근제어';
	document.getElementById('config_apn').innerHTML = 'APN';
	//document.getElementById('config_qos').innerHTML = 'Qos';
	document.getElementById('system_profile').innerHTML = '정보';
	document.getElementById('system_firmware').innerHTML = '펌웨어';
	document.getElementById('system_configmgmt').innerHTML = '설정 백업 / 복구';
	document.getElementById('system_reboot').innerHTML = '재시작';
	document.getElementById('logout').innerHTML = '로그아웃';
}
/**
  * Get Cookie
  * @param name : cookie name
  */
 
function getCookie( name )
{
	var search = name + "=";
	var cookie = document.cookie;
	if( cookie.length > 0 )
	{
		startIndex = cookie.indexOf( name );
		if( startIndex != -1 )
		{
			startIndex += name.length;
			endIndex = cookie.indexOf( ";", startIndex );

			if( endIndex == -1)
			{
				endIndex = cookie.length;
			}

			return unescape( cookie.substring( startIndex + 1, endIndex ) );
		}
		else
		{
			return false;
		}
	}
	else
	{
		return false;
	}
}

/**
  * Set Cookie
  * @param name : cookie name
  * @param value : cookie value
  * @param expire : valid date
  */
function setCookie( name, value, expire )
{
	var today = new Date();
	
	today.setDate( today.getDate() + parseInt( expire ) );
	document.cookie = name + "=" + escape( value ) + "; path=/; expires=" + today.toGMTString() + ";";
}
 
 /**
  * Delete Cookie
  * @param name : cookie name
  */
function deleteCookie( name )
{
	var expire = new Date();

	expire.setDate( expire.getDate() - 1 );
	document.cookie = name + "= " + "; expires=" + expire.toGMTString() + "; path=/";
}

function onPageTimeout()
{
	if(typeof window.ActiveXObject != 'undefined')
	{
		xmlhttp = (new ActiveXObject("Microsoft.XMLHTTP"));
	}
	else
	{
		xmlhttp = (new XMLHttpRequest());
	}
	
	var data = "/cgi-bin/logout";
		
	xmlhttp.open( "POST", data, true );
	xmlhttp.setRequestHeader("Content-Type","application/x-www-form-urlencoded;charset=euc-kr");
	xmlhttp.send();

	window.location.href="/";
}

function enablePageTimeout()
{
	if (typeof(sessionStorage.hPageTimeout) != "undefined")
	{
		clearTimeout(sessionStorage.hPageTimeout);
	}

	if (typeof(sessionStorage.nPageTimeout) != "undefined")
	{
		sessionStorage.nPageTimeout = 60000;
	}

	if (sessoinStorage.nPageTimeout != 0)
	{
		sessionStorage.hPageTimeout = setTimeout(onPageTimeout, sessionStorage.nPageTimeout);
	}
}