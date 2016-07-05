/**
 * Created by kindmong on 2015-11-05.
 */
function init() {
    $.li18n.currentLocale = 'kr';
    document.getElementById("menu_dashboard").innerHTML = _t('dashboard');
    document.getElementById("menu_sensors").innerHTML = _t('sensors');
    document.getElementById("menu_clouds").innerHTML = _t('clouds');
    document.getElementById("menu_network").innerHTML = _t('network');
    document.getElementById("menu_system").innerHTML = _t('system');

	document.getElementById("th_port").innerHTML = _t('port');
    document.getElementById("th_ip").innerHTML = _t('ip');
    document.getElementById("th_subnet").innerHTML = _t('subnet');
    document.getElementById("th_mac").innerHTML = _t('mac');
}

$(document).ready(function(){
    init();
    usim_socket_status();
});

function usim_socket_status() {
    $.ajax({
        type:"get",
        url:"/cgi-bin/usim?cmd=usim_socket_status",
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
				
                if (result == 0) {
                    // 유심 미장착
                    alert("USIM이 장착되어있지 않습니다.\nUSIM을 장착하신 후 전원을 껐다 켜주십시오.");
                    //document.getElementById("usim_status").innerHTML = "SIM NOT INSERT";
                    return;
                } else {
                    // 유심장착
                    usim_different_status();
                }
            });
        },
        error : function(xhr, status, error) {
            //alert("에러발생");
            window.location.href="/";
        }
    });
}

function usim_different_status(){
    $.ajax({
        type:"get",
        url:"/cgi-bin/usim?cmd=usim_different_status",
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
                if (result == 3) {
                    // 기기인증 실패 (타단말 유심 의심)
                    alert("타 이통사 USIM 입니다.\n새로운 USIM을 장착한 후 전원을 껏다 켜주십시오.");
                    //document.getElementById("usim_status").innerHTML = "타 이통사 USIM";
                    return;
                }
                usim_open_status();
            });
        },
        error : function(xhr, status, error) {
            //alert("에러발생");
            window.location.href="/";
        }
    });
}
function usim_open_status(){
    $.ajax({
        type:"get",
        url:"/cgi-bin/usim?cmd=usim_open_status",
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
                if (result == 1) {
                    // 미개통 유심
                    alert("미개통 USIM입니다.\n개통후 전원을 껏다 켜 주십시오.");
                    //document.getElementById("usim_status").innerHTML = "미개통 USIM";
                    return;
                }
                usim_cnum();
            });
        },
        error : function(xhr, status, error) {
            //alert("에러발생");
            window.location.href="/";
        }
    });
}
function usim_cnum() {
    $.ajax({
        type:"get",
        url:"/cgi-bin/usim?cmd=cnum",
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
                var resultArr = result.split(",");
                var tbody = document.getElementById("static_body");
                tr = document.createElement("tr");
                tbody.appendChild(tr);
                tr.appendChild(document.createElement("th")).innerHTML = "MSISDN";
                tr.appendChild(document.createElement("td")).innerHTML = resultArr[1].substring(1, 13);
                is_limited();
            });
        },
        error : function(xhr, status, error) {
            //alert("에러발생");
            window.location.href="/";
        }
    });
}
function is_limited() {
    $.ajax({
        type:"get",
        url:"/cgi-bin/usim?cmd=is_limited",
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
                var tbody = document.getElementById("static_body");
				
                if (result == "N") {
                    tr = document.createElement("tr");
                    tbody.appendChild(tr);
                    tr.appendChild(document.createElement("th")).innerHTML = "USIM Status";
                    tr.appendChild(document.createElement("td")).innerHTML = "No Service";
                    return;
                } else {
                    tr = document.createElement("tr");
                    tbody.appendChild(tr);
                    tr.appendChild(document.createElement("th")).innerHTML = "USIM Status";
                    tr.appendChild(document.createElement("td")).innerHTML = "Ready";
                    get_pppData();
                }
            });
        },
        error : function(xhr, status, error) {
            //alert("에러발생");
            window.location.href="/";
        }
    });
}
function get_pppData() {
    $.ajax({
        type:"get",
        url:"/cgi-bin/getdata?cmd=state",
        dataType:"xml",
        success : function(xml) {
            // 통신이 성공적으로 이루어졌을 때 이 함수를 타게 된다.
            // TODO
            $(xml).find("data").each(function(){
                console.log($(this).find("text").text());
                result = $(this).find("text").text();
                //var resultArr = result.split(" ");
                //var rx_data = resultArr[0];
                //var tx_data = resultArr[1];
                //var rx = document.getElementById("rx_data");
                //var tx = document.getElementById("tx_data");
                //rx.innerHTML = bytesToSize(rx_data);
                //tx.innerHTML = bytesToSize(tx_data);
                networkState();
            });
        },
        error : function(xhr, status, error) {
            //alert("에러발생");
            window.location.href="/";
        }
    });
}
function networkState() {
    var keys = ["TIME", "DL EARFCN", "RX Power", "TX Adjust",
        "TX Power", "Pilot PN Offset", "Ec/lo", "System Identification",
        "Network Identification", "Registration Zone", "Registration Zone", "Base Station Identification"];

    $.ajax({
        type:"get",
        url:"/cgi-bin/network_state?cmd=state",
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
                var tbody = document.createElement("tbody");
                document.getElementById("info").appendChild(tbody);
                var textArr = result.split(",");
                console.log(tbody);
                for (var i=0; i<textArr.length; i++)
                {
                    var rowlen;
                    var row;

                    var key = keys[i];
                    var value;
                    var special_value;

                    if (i < 9) {
                        value = textArr[i];
                        console.log(value);

                        tr = document.createElement("tr");
                        tbody.appendChild(tr);
                        tr.appendChild(document.createElement("th")).innerHTML = key;
                        tr.appendChild(document.createElement("td")).innerHTML = value;

                    } else if (i == 9)
                    {
                        special_value = textArr[i];
                    } else if (i == 10)
                    {
                        special_value += ", " + textArr[i];
                        console.log(special_value);

                        tr = document.createElement("tr");
                        tbody.appendChild(tr);
                        tr.appendChild(document.createElement("th")).innerHTML = key;
                        tr.appendChild(document.createElement("td")).innerHTML = special_value;
                    } else {
                        value = textArr[i];
                        console.log(value);
                        tr = document.createElement("tr");
                        tbody.appendChild(tr);
                        tr.appendChild(document.createElement("th")).innerHTML = key;
                        tr.appendChild(document.createElement("td")).innerHTML = value;
                    }
                }
            });
        },
        error : function(xhr, status, error) {
            //alert("에러발생");
            window.location.href="/";
        }
    });
}
function loadpppIP() {

}

function usim_sending_stop_status()
{
	if(typeof window.ActiveXObject != 'undefined')
	{
		xmlhttp = (new ActiveXObject("Microsoft.XMLHTTP"));
	}
	else
	{
		xmlhttp = (new XMLHttpRequest());
	}
	
	var data = "/cgi-bin/usim?cmd=usim_sending_stop_status";

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
					var result = resultNode.firstChild.nodeValue;

					if (result == "done" || result == "URC MESSAGE")
					{
						document.getElementById('message').innerHTML='다시 시도해 주십시오..';
						return;
					}

					//result = "Barred";
					if (result == "OK")
					{
						// 정상 서비스 상태
						document.getElementById("usim_status").innerHTML = "READY";
					}
					if (result == "Barred")
					{
						// 발신정지 상태
						alert("단말이 발신정지 상태입니다.\n고객센터에 연락하여 발신정지 해지를 요청하십시오.\n발신정지가 해지되면 단말을 재부팅 해주십시오.");
						document.getElementById("usim_status").innerHTML = "발신정지";
						//return;
					}

					new_pppData();

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