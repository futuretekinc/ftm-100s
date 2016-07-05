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

	document.getElementById("h_dhcp_info").innerHTML = _t('dhcp_info');

    $.ajax({
        type:"get",
        url:"/cgi-bin/dhcp?cmd=status",
        dataType:"xml",
        success : function(xml) {
            // 통신이 성공적으로 이루어졌을 때 이 함수를 타게 된다.
            // TODO
            $(xml).find("DHCP_SERVER").each(function(){
                //console.log($(this).find("STATUS").text());
                document.getElementById("status").innerHTML = $(this).find("STATUS").text();
                document.getElementById("interface").innerHTML = $(this).find("INTERFACE").text();
                document.getElementById("start").innerHTML = $(this).find("START").text();
                document.getElementById("end").innerHTML = $(this).find("END").text();
                document.getElementById("router").innerHTML = $(this).find("ROUTER").text();
                document.getElementById("time").innerHTML = $(this).find("TIME").text();
                document.getElementById("dns1").innerHTML = $(this).find("DNS1").text();
                document.getElementById("dns2").innerHTML = $(this).find("DNS2").text();
                var staticip = $(this).find("STATIC").text();
                if (staticip == 1) {
                    document.getElementById("static").innerHTML = "enable";
                } else {
                    document.getElementById("static").innerHTML = "disable";
                }

                var leases = $(this).find("LEASE");
                active_ip(leases);
            });
        },
        error : function(xhr, status, error) {
            //alert("에러발생");
            window.location.href="/";
        }
    });
}

function active_ip(leases) {
    $.ajax({
        type:"get",
        url:"/cgi-bin/dhcp?cmd=real_status",
        dataType:"xml",
        success : function(xml) {
            // 통신이 성공적으로 이루어졌을 때 이 함수를 타게 된다.
            // TODO
            $(xml).find("ACTIVE_IP").each(function(){
                result = $(this).find("IP");
                console.log(result);
                var arr = [];
                for (var k = 0; k < result.length; k++)
                {
                    arr.push(result[k].firstChild.nodeValue);
                }

                ips = arr.reduce(function(a,b){if(a.indexOf(b)<0)a.push(b);return a;},[]);

                list_count=0;
                for(j = 0 ; j < ips.length ; j++)
                {
                    ip = ips[j];
                    ip = ip.replace(/\(/g,''); //특정문자 제거
                    ip = ip.replace(/\)/g,''); //특정문자 제거
                    //alert(ip);

                    if (leases.length != 0)
                    {
                        for(i = 0 ; i < leases.length ; i++)
                        {
                            macaddr = leases[i].getElementsByTagName("MAC")[0].firstChild.nodeValue;
                            ipaddr = leases[i].getElementsByTagName("IP")[0].firstChild.nodeValue;

                            if (hostname = leases[i].getElementsByTagName("HOSTNAME")[0].firstChild == null)
                            {
                                hostname = "";
                            } else {
                                hostname = leases[i].getElementsByTagName("HOSTNAME")[0].firstChild.nodeValue;
                            }

                            expiresin = leases[i].getElementsByTagName("EXPIRESIN")[0].firstChild.nodeValue;
                            //alert(i);
                            var tbody = document.getElementById('dhcp_active_leases');
                            if (ip == ipaddr)
                            {
                                var tbody_tr = document.createElement("tr");
                                tbody.appendChild(tbody_tr);
                                tbody_tr.appendChild(document.createElement("td")).innerHTML = list_count+1;
                                tbody_tr.appendChild(document.createElement("td")).innerHTML = macaddr;
                                tbody_tr.appendChild(document.createElement("td")).innerHTML = ipaddr;
                                tbody_tr.appendChild(document.createElement("td")).innerHTML = hostname;
                                tbody_tr.appendChild(document.createElement("td")).innerHTML = expiresin;
                                list_count++;
                            }


                        }
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