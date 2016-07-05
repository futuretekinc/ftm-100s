var	msgInvalidIDorPasswd=0;
var msg;

function onInit()
{
	msg = new Array();

	document.getElementById('title_userid').innerHTML = "아이디: ";
	document.getElementById('title_passwd').innerHTML = "비밀번호: ";
	msg[msgInvalidIDorPasswd]="입력하신 아이디나 패스워드가 잘못 되었습니다.\n확인 후 재시도해 주시기 바랍니다."
}

function onLoad()
{
	onInit();

	deleteCookie('ssid');
	document.getElementById('body').hidden = false;
	//onResize();	
/*
	if(typeof window.ActiveXObject != 'undefined')
	{
		xmlhttp = (new ActiveXObject("Microsoft.XMLHTTP"));
	}
	else
	{
		xmlhttp = (new XMLHttpRequest());
	}
	
	xmlhttp.open( "GET", "/cgi-bin/public?cmd=get_dev_info", true );
	xmlhttp.setRequestHeader("Content-Type","application/x-www-form-urlencoded;charset=euc-kr");
	xmlhttp.onreadystatechange = function()
	{
		if( (xmlhttp.readyState == 4) && (xmlhttp.status == 200) )
		{
			try
			{
				model = xmlhttp.responseXML.documentElement.getElementsByTagName("MODEL");
				document.getElementById("model").innerHTML = model[0].firstChild.nodeValue;
			}
			catch(e)
			{
			}
		}
	}
	xmlhttp.send();
	*/
}

function onResize()
{
	box = document.getElementById('box');
	
	if (document.width > box.clientWidth)
	{
		box.style.left = parseInt((document.width - box.clientWidth) / 2) + 'px';
	}
	else
	{
		box.style.left = '0';
	}
	
	if (document.height > box.clientHeight)
	{
		box.style.top = parseInt((document.height - box.clientHeight) / 2) + 'px';
	}
	else
	{
		box.style.top = '0';
	}
}

function onKeyDown(obj, callback)
{	
	var x;
	if(window.event) // IE8 and earlier
	{
		x=event.keyCode;
	}
	else if(event.which) // IE9/Firefox/Chrome/Opera/Safari
	{
		x=event.which;
	}
	
	if (x == 13)
	{
		if (obj.value.length > 0)
		{
			if (typeof(callback) != undefined)
			{
				callback();
			}
		}
	}
}

function onClickLoginButton()
{
	if(typeof window.ActiveXObject != 'undefined')
	{
		xmlhttp = (new ActiveXObject("Microsoft.XMLHTTP"));
	}
	else
	{
		xmlhttp = (new XMLHttpRequest());
	}
	
	var f = document.login;
	//var data = "/cgi-bin/public?cmd=get_ssid&id=" + f.userid.value + "&pw=" + MD5(f.passwd.value) + "&seed=" + Math.random();
	var data = "/cgi-bin/public?cmd=get_ssid&id=" + f.userid.value + "&pw=" + MD5(f.passwd.value) + "&seed=" + Math.random();

	xmlhttp.open( "POST", data, true );
	xmlhttp.setRequestHeader("Content-Type","application/x-www-form-urlencoded;charset=euc-kr");
	xmlhttp.onreadystatechange = function()
	{
		if( (xmlhttp.readyState == 4) && (xmlhttp.status == 200) )
		{
			try
			{
					var ssid = xmlhttp.responseXML.documentElement.getElementsByTagName("SSID")[0].firstChild.nodeValue;
					setCookie('ssid', ssid, 1);
					
					//setTimeout(function(){window.location.href = "/cgi-bin/page?cmd=status_network";}, 1000);
					setTimeout(function(){window.location.href = "pages/dashboard.html";}, 1000);
			}
			catch(e)
			{
				alert(msg[msgInvalidIDorPasswd]);
			}
		}
	}
	xmlhttp.send();
}

