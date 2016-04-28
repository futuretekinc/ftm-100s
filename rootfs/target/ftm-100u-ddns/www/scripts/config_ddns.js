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

	document.getElementById('page_title').innerHTML='DDNS 설정';
	//document.getElementById('section1_title').innerHTML='DDNS 설정';
	document.getElementById('apply').value='적용';
	document.getElementById('body').hidden = false;
	
}

function onLoad()
{
	onInit();
	loadState();
}

function loadState()
{
	//document.getElementById('message').innerHTML='잠시만 기다려 주십시오..';
	if(typeof window.ActiveXObject != 'undefined')
	{
		xmlhttp = (new ActiveXObject("Microsoft.XMLHTTP"));
	}
	else
	{
		xmlhttp = (new XMLHttpRequest());
	}
	
	var data = "/cgi-bin/lgddns?cmd=state";

	xmlhttp.open( "POST", data, true );
	xmlhttp.setRequestHeader("Content-Type","application/x-www-form-urlencoded;charset=euc-kr");
	xmlhttp.onreadystatechange = function()
	{
		if( (xmlhttp.readyState == 4) && (xmlhttp.status == 200) )
		{
			try
            {
				dns = xmlhttp.responseXML.documentElement.getElementsByTagName("DNS")[0].firstChild.nodeValue;
				domain = xmlhttp.responseXML.documentElement.getElementsByTagName("DOMAIN")[0].firstChild.nodeValue;
				ip = xmlhttp.responseXML.documentElement.getElementsByTagName("IP")[0].firstChild.nodeValue;
				console.log(dns, domain, ip);
				dns_tf = document.getElementById("dns_server_ip");
				domain_tf = document.getElementById("domain_name");
				ip_tf = document.getElementById("ip");
				dns_tf.value = dns;
				domain_tf.value = domain.slice(0, -1);
				ip_tf.value = ip;

				loadIMSI();
            }
            catch(e)
            {

            }
		}
	}
	xmlhttp.send();
}

function setDDNS()
{	
	if(typeof window.ActiveXObject != 'undefined') {
		xmlhttp = (new ActiveXObject("Microsoft.XMLHTTP"));
	} else {
		xmlhttp = (new XMLHttpRequest());
	}
	
	var data = "/cgi-bin/lgddns?cmd=set"
	dns_tf = document.getElementById("dns_server_ip");
	domain_tf = document.getElementById("domain_name");
	ip_tf = document.getElementById("ip");
	imsi = document.getElementById("imsi");
	console.log(imsi.innerHTML);

	data += "&dns=" + dns_tf.value;
	data += "&domain=" + domain_tf.value;
	data += "&ip=" + ip_tf.value;
	data += "&imsi=" + imsi.innerHTML;
	
	xmlhttp.open( "POST", data, true );
	xmlhttp.setRequestHeader("Content-Type","application/x-www-form-urlencoded;charset=euc-kr");
	xmlhttp.onreadystatechange = function()
	{
		if( (xmlhttp.readyState == 4) && (xmlhttp.status == 200) )
		{
			try
			{
				result = xmlhttp.responseXML.documentElement.getElementsByTagName("RET")[0];
            	if (result.firstChild.nodeValue == 'OK') {
					alert("save");
				} else {
					alert("error");
				}
			}
			catch(e)
			{

			}
		}
	}
	xmlhttp.send();
}

function loadIMSI()
{
	if(typeof window.ActiveXObject != 'undefined')
	{
		xmlhttp = (new ActiveXObject("Microsoft.XMLHTTP"));
	}
	else
	{
		xmlhttp = (new XMLHttpRequest());
	}
	
	var data = "/cgi-bin/imsi?cmd=state";

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
            		var resultNode = xmlhttp.responseXML.documentElement.getElementsByTagName("num")[0];

					if (resultNode.firstChild != null)
					{
						imsi_tf = document.getElementById("imsi");
						lteip_tf = document.getElementById("lte_ip");

						if (resultNode.firstChild.nodeValue == "done" || resultNode.firstChild.nodeValue == "URC MESSAGE")
						{
							imsi_tf.innerHTML = 'please refresh..';
							lteip_tf.innerHTML = 'please refresh..';
							return;
						}
						var imsi = resultNode.firstChild.nodeValue;	
						imsi_tf.innerHTML = imsi;

						loadpppIP();
					}
            	} else {
            	}
            }
            catch(e)
            {

            }
		}
	}
	xmlhttp.send();
}

function loadpppIP()
{
	if(typeof window.ActiveXObject != 'undefined')
	{
		xmlhttp = (new ActiveXObject("Microsoft.XMLHTTP"));
	}
	else
	{
		xmlhttp = (new XMLHttpRequest());
	}
	
	var data = "/cgi-bin/pppip?cmd=state";

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
            		var resultNode = xmlhttp.responseXML.documentElement.getElementsByTagName("text")[0];
					if (resultNode.firstChild != null)
					{
						var ip = resultNode.firstChild.nodeValue;
						lteip_tf = document.getElementById("lte_ip");
						lteip_tf.innerHTML = ip;
					}
            	} else {
            	}
            }
            catch(e)
            {

            }
		}
	}
	xmlhttp.send();
}