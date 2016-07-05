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

    $.ajax({
        type:"get",
        url:"/cgi-bin/system?cmd=profile",
        dataType:"xml",
        contentType:"text/xml",
        success : function(xml) {
            // 통신이 성공적으로 이루어졌을 때 이 함수를 타게 된다.
            // TODO
            $(xml).find("PROFILE").each(function(){

                document.getElementById("model").innerHTML = $(this).find("MODEL").text();
                document.getElementById("sn").innerHTML = $(this).find("SN").text();
                document.getElementById("hw_version").innerHTML = $(this).find("HWVER").text();

                loadModemVersion();
            });
        },
        error : function(xhr, status, error) {
            //alert("에러발생");
            window.location.href="/";
        }
    });
}

function onApplyChangePasswd()
{
    if(document.getElementById("new_passwd").value != document.getElementById("confirm_passwd").value)
    {
        alert(msg[msgPasswordMismatch]);
        return	false;
    }
    var	data = "/cgi-bin/system?cmd=chg_passwd";

    data += "&passwd=" + MD5(document.getElementById("passwd").value);
    data += "&new_passwd=" + MD5(document.getElementById("new_passwd").value);

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

function loadModemVersion()
{
    $.ajax({
        type:"get",
        url:"/cgi-bin/module?cmd=state",
        dataType:"xml",
        success : function(xml) {
            // 통신이 성공적으로 이루어졌을 때 이 함수를 타게 된다.
            // TODO
            $(xml).find("data").each(function(){
                document.getElementById("modem_version").innerHTML = $(this).find("text").text();
            });
        },
        error : function(xhr, status, error) {
            //alert("에러발생");
            window.location.href="/";
        }
    });
    /*
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
                        alert("Please Refresh..");
                        return;
                    }
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
    };
    xmlhttp.send();
    */
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
    };
    xmlhttp.send();
}

function profile_logout()
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
    };
    xmlhttp.send();
}