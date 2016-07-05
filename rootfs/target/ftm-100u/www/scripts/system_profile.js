var msgPasswordMismatch=0;
var msgPasswodChanged=1;
var msgLocChanged=2;
var msg;

function onInit()
{
	document.getElementById('page_title').innerHTML = "시스템 정보";
	document.getElementById('section1_title').innerHTML = "장치 정보";
	document.getElementById('section2_title').innerHTML = "사용자 정보";
	document.getElementById('title_model').innerHTML = "모델 :";
	document.getElementById('title_sn').innerHTML = "일련번호 :";
	document.getElementById('title_modem_version').innerHTML = "모뎀버전 :";
	document.getElementById('title_hw_version').innerHTML = "HW 버전 :";
//	document.getElementById('title_modem_hw_version').innerHTML = "모뎀 HW 버전 :";
//	document.getElementById('title_loc').innerHTML = "위치: ";
	document.getElementById('title_current_pw').innerHTML = "기존 비밀번호: ";
	document.getElementById('title_new_pw').innerHTML = "새 비밀번호: ";
	document.getElementById('title_confirm_pw').innerHTML = "새 비밀번호 확인: ";
	document.getElementById('btn_apply').value = "적용";
//	document.getElementById('btn_apply_loc').value = "변경";

	msg = new Array();
	msg[msgPasswordMismatch]= "비밀번호가 일치하지 않습니다.\n확인 후 다시 시도해 주십시오."	
	msg[msgPasswodChanged] 	= "비밀번호가 변경되었습니다."	
	msg[msgLocChanged] 			= "장치 위치가 변경되었습니다."	
	
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
	
	var data = "/cgi-bin/system?cmd=profile";
	
	xmlhttp.open( "POST", data, true );
	xmlhttp.setRequestHeader("Content-Type","application/x-www-form-urlencoded;charset=euc-kr");
	xmlhttp.onreadystatechange = function()
	{
		if( (xmlhttp.readyState == 4) && (xmlhttp.status == 200) )
		{
			try
			{
				info = xmlhttp.responseXML.documentElement.getElementsByTagName("PROFILE");
				if (info.length != 0)
				{
					div_model = info[0].getElementsByTagName("MODEL");
					if (div_model.length != 0)
					{
						document.getElementById('model').innerHTML= "FTM-100U";//div_model[0].firstChild.nodeValue;
					}
					div_sn= info[0].getElementsByTagName("SN");
					if (div_sn.length != 0)
					{
						document.getElementById('sn').innerHTML= div_sn[0].firstChild.nodeValue;
					}
					div_hw= info[0].getElementsByTagName("HWVER");
					if (div_hw.length != 0)
					{
						document.getElementById('hw_version').innerHTML= div_hw[0].firstChild.nodeValue;
					}

//					div_location= info[0].getElementsByTagName("LOCATION");
//					if (div_location.length != 0)
//					{
//						document.getElementById('location').innerHTML= div_location[0].firstChild.nodeValue;
//					}
				}
				loadModemVersion();
			}
			catch(e)
			{
			}
		}
	}
	xmlhttp.send();
}

function onApplyChangePasswd()
{
	if(document.f.new_passwd.value != document.f.confirm_passwd.value)
	{
		alert(msg[msgPasswordMismatch]);
		return	false;
	}
	var	data = "/cgi-bin/system?cmd=chg_passwd";
	
	data += "&passwd=" + MD5(document.f.passwd.value);
	data += "&new_passwd=" + MD5(document.f.new_passwd.value);
	
	if(typeof window.ActiveXObject != 'undefined')
	{
		xmlhttp = (new ActiveXObject("Microsoft.XMLHTTP"));
	}
	else
	{
		xmlhttp = (new XMLHttpRequest());
	}
	
  xmlhttp.open( "POST", data, true );
  xmlhttp.setRequestHeader("Content-Type","application/x-www-form-urlencoded;charset=euc-kr");
  xmlhttp.onreadystatechange = function() 
  {
		if( (xmlhttp.readyState == 4) && (xmlhttp.status == 200) )
		{
			try
			{
				ret = xmlhttp.responseXML.documentElement.getElementsByTagName("RET");
				if (ret[0].firstChild.nodeValue == "OK")
				{
					alert(msg[msgPasswodChanged]);
					profile_logout();
	    		}
				if (ret[0].firstChild.nodeValue == "ERROR")
				{
					result = xmlhttp.responseXML.documentElement.getElementsByTagName("MSG");
					if (result[0].firstChild.nodeValue == "Invalid password.")
					{
						alert(msg[msgPasswordMismatch]);
					}
				}
			}
			catch(e)
			{
		    
		    }
		}
	}
	xmlhttp.send();
}

function onApplyLocation()
{
	if(document.f.new_passwd.value != document.f.confirm_passwd.value)
	{
		alert(msg[msgPasswordMismatch]);
		return	false;
	}
	var	data = "/cgi-bin/system?cmd=chg_loc";
	
	data += "&loc=" + document.getElementById('location').value;
	
	if(typeof window.ActiveXObject != 'undefined')
	{
		xmlhttp = (new ActiveXObject("Microsoft.XMLHTTP"));
	}
	else
	{
		xmlhttp = (new XMLHttpRequest());
	}
	
  xmlhttp.open( "POST", data, true );
  xmlhttp.setRequestHeader("Content-Type","application/x-www-form-urlencoded;charset=euc-kr");
  xmlhttp.onreadystatechange = function() 
  {
		if( (xmlhttp.readyState == 4) && (xmlhttp.status == 200) )
		{
			try
			{
				ret = xmlhttp.responseXML.documentElement.getElementsByTagName("RET");
				if (ret[0].firstChild.nodeValue == "OK")
				{
					document.f.passwd.value = "";
					document.f.new_passwd.value = "";
					document.f.confirm_passwd.value = "";
					
					alert(msg[msgLocChanged]);	
	    	}
	    }
	    catch(e)
	    {
		    
	    }
		}
  }
	xmlhttp.send();
}

function loadModemVersion()
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
	
	var data = "/cgi-bin/module?cmd=state";

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
            		var ver_text = result2.firstChild.nodeValue;
					if (ver_text == "done" || ver_text == "URC MESSAGE")
					{
						//alert("Please Refresh..");
						document.getElementById('message').innerHTML='다시 시도해 주십시오..';
						return;
					}
					document.getElementById('message').innerHTML='';
					document.getElementById('modem_version').innerHTML = ver_text;
					//loadModemHwVersion(); // LG
            	} else {
            		// error
            		alert(result.firstChild.nodeValue);
            	}
            }
            catch(e)
            {

            }
		}
	}
	xmlhttp.send();
}

function loadModemHwVersion()
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
	
	var data = "/cgi-bin/module?cmd=hw_state";

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
					if (text == "done" || text == "URC MESSAGE")
					{
						//alert("Please Refresh..");
						document.getElementById('message').innerHTML='다시 시도해 주십시오..';
						return;
					}
					document.getElementById('message').innerHTML='';
					//var trimText = trim(text);
					//alert(text);
					var textArr = text.split(":");
					//var ATCOMMAND = textArr[0].split(":")[0];
					//var ATCOMMAND_RES = textArr[0].split(":")[1];
					//alert(ATCOMMAND_RES);
					document.getElementById('modem_hw_version').innerHTML = textArr[1];
					
            	} else {
            		// error
            		alert(result.firstChild.nodeValue);
            	}
            }
            catch(e)
            {

            }
		}
	}
	xmlhttp.send();
}

function profile_logout()
{
	//var ret = confirm("로그아웃 하시겠습니까?");
	//if (ret == true)
	//{
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
	//}
}
