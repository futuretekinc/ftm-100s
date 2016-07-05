/**
 * Created by kindmong on 2015-11-05.
 */

// Syslog Status
var total_count = 0;
var page_count = 0;

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

    var table = document.getElementById("syslog");
    try
    {
        for(i = 0 ; i < 20 ; i++)
        {
            var row = table.insertRow(-1);

            row.setAttribute('height', '40px');
            cell = row.insertCell(0);
            cell.innerHTML = "<td></td>";
            cell.setAttribute('class','index center');
            cell = row.insertCell(1);
            cell.innerHTML = "<td></td>";
            cell.setAttribute('class','center');
            cell = row.insertCell(2);
            cell.innerHTML = "<td></td>";
            cell.setAttribute('class','center');
            cell = row.insertCell(3);
            cell.innerHTML = "<td></td>";
            cell.setAttribute('class','left');
        }
    }
    catch(e)
    {
    }

    if(typeof window.ActiveXObject != 'undefined')
    {
        xmlhttp = (new ActiveXObject("Microsoft.XMLHTTP"));
    }
    else
    {
        xmlhttp = (new XMLHttpRequest());
    }

    var data = "/cgi-bin/syslog?cmd=status";

    xmlhttp.open( "POST", data, true );
    xmlhttp.setRequestHeader("Content-Type","application/x-www-form-urlencoded;charset=euc-kr");
    xmlhttp.onreadystatechange = function()
    {
        if( (xmlhttp.readyState == 4) && (xmlhttp.status == 200) )
        {
            try
            {
                log_info = xmlhttp.responseXML.documentElement.getElementsByTagName("INFO");
                if (log_info.length != 0)
                {
                    total_count = log_info[0].getElementsByTagName('COUNT')[0].firstChild.nodeValue;
                    page_count 	= parseInt((Number(total_count) + 9) / 10);

                    onGetLog(1);
                }
            }
            catch(e)
            {
            }
        }
    };
    xmlhttp.send();
}

function onGetLog(index)
{
    if(typeof window.ActiveXObject != 'undefined')
    {
        xmlhttp = (new ActiveXObject("Microsoft.XMLHTTP"));
    }
    else
    {
        xmlhttp = (new XMLHttpRequest());
    }

    var data = "/cgi-bin/syslog?cmd=get";
    data 		+= "&index=" + (index-1)*10;
    data 		+= "&count=" + 10;

    xmlhttp.open( "POST", data, true );
    xmlhttp.setRequestHeader("Content-Type","application/x-www-form-urlencoded;charset=euc-kr");
    xmlhttp.onreadystatechange = function()
    {
        if( (xmlhttp.readyState == 4) && (xmlhttp.status == 200) )
        {
            var table = document.getElementById("syslog");
            try
            {
                var	i = 0;

                while(table.rows.length > 1)
                {
                    table.deleteRow(-1);
                }

                log_info = xmlhttp.responseXML.documentElement.getElementsByTagName("INFO");
                if (log_info.length != 0)
                {
                    total_count = log_info[0].getElementsByTagName('COUNT')[0].firstChild.nodeValue;
                    page_count 	= parseInt((Number(total_count) + 9) / 10);
                }

                entities = xmlhttp.responseXML.documentElement.getElementsByTagName("ENTITY");
                for(i = 0 ; i < entities.length ; i++)
                {
                    var row = table.insertRow(1);

                    time 		= entities[i].getElementsByTagName("TIME")[0].firstChild.nodeValue;
                    process = entities[i].getElementsByTagName("PROCESS")[0].firstChild.nodeValue;
                    if (entities[i].getElementsByTagName("LOG")[0].childNodes[0] != undefined)
                    {
                        log 		= entities[i].getElementsByTagName("LOG")[0].childNodes[0].nodeValue;
                    } else {
                        log = "";
                    }


                    cell = row.insertCell(0);
                    cell.innerHTML = "<td>" + ((index - 1)*20 + entities.length - i) + "</td>";
                    cell.setAttribute('class','index center');
                    cell = row.insertCell(1);
                    cell.innerHTML = "<td>" + time + "</td>";
                    cell.setAttribute('class','center');
                    cell = row.insertCell(2);
                    cell.innerHTML = "<td>" + process + "</td>";
                    cell.setAttribute('class','center');
                    cell = row.insertCell(3);
                    cell.innerHTML = "<td>" + log + "</td>";
                    cell.setAttribute('class','left');
                }

                onCreateNavi(page_count, index);
            }
            catch(e)
            {
            }
        }
    };
    xmlhttp.send();
}

function onCreateNavi(pages, selected)
{
	console.log(pages);
	console.log(selected);
    if (selected > pages)
    {
        selected = pages;
    }

    if (selected - 4 < 1)
    {
        start_page = 1;
        last_page = start_page+9;
    }
    else if (selected + 5 > pages)
    {
        last_page = pages;
        start_page = last_page - 9;
    }
    else
    {
        start_page = selected - 4;
        last_page = selected + 5;
    }

    if (start_page < 1)
    {
        start_page = 1;
    }

    if (last_page > pages)
    {
        last_page = pages;
    }

/*
    div_nav = document.getElementById("nav");
    div_nav.innerHTML = "";

    var newElement = document.createElement('a');
    newElement.setAttribute('style', 'cursor:pointer');
    newElement.setAttribute('onclick', 'onGetLog(1);');
    newElement.innerHTML = "  <<  ";
    div_nav.appendChild(newElement);

    for(i = 0 ; (start_page + i)  <= pages && i < 10 ; i++)
    {
        newElement = document.createElement('a');
        newElement.innerHTML = "  " + (start_page + i) + "  ";
        div_nav.appendChild(newElement);

        if ((start_page + i) != selected)
        {
            newElement.setAttribute('style', 'cursor:pointer');
            newElement.setAttribute('onclick', 'onGetLog(' + (start_page + i) +');');
        }
        else
        {
            newElement.setAttribute('style', 'font-weight:bold');
        }
    }

    newElement = document.createElement('a');
    newElement.setAttribute('style', 'cursor:pointer');
    newElement.setAttribute('onclick', 'onGetLog(' + pages + ');');
    newElement.innerHTML = "  >>  ";
    div_nav.appendChild(newElement);

*/

	div_nav = document.getElementById("nav");
	div_nav.innerHTML = "";

	var li = document.createElement('li');
	var a = document.createElement("a");
	a.setAttribute("href", "#");
	a.setAttribute("onclick", "onGetLog(1);");
	a.setAttribute("aria-label", "Previous");
	li.appendChild(a);
	var span = document.createElement("span");
	span.setAttribute("aria-hidden", "true");
	span.innerHTML = "&laquo;";
	a.appendChild(span);
    div_nav.appendChild(li);

	for(i = 0 ; (start_page + i)  <= pages && i < 10 ; i++)
    {
        var li_2 = document.createElement('li');
		var a_2 = document.createElement("a");
		a_2.setAttribute("href", "#");
        a_2.innerHTML = start_page + i;
        li_2.appendChild(a_2);
		div_nav.appendChild(li_2);

        if ((start_page + i) != selected)
        {
            a_2.setAttribute('onclick', 'onGetLog(' + (start_page + i) +');');
        }
        else
        {
            //newElement.setAttribute('style', 'font-weight:bold');
        }
    }

	var li_3 = document.createElement('li');
	var a_3 = document.createElement("a");
	a_3.setAttribute("href", "#");
	a_3.setAttribute("onclick", "onGetLog(1);");
	a_3.setAttribute("aria-label", "Next");
	li_3.appendChild(a_3);
	var span = document.createElement("span");
	span.setAttribute("aria-hidden", "true");
	span.innerHTML = "&raquo;";
	a_3.appendChild(span);
    div_nav.appendChild(li_3);
}