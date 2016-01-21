<!-- Syslog Status -->
var total_count = 0;
var page_count = 0;

function onInit()
{
	document.getElementById('page_title').innerHTML='로그';
	document.getElementById('section1_title').innerHTML='시스템 로그 (최대 200kbyte까지 기록)';
	document.getElementById('index').innerHTML='번호';
	document.getElementById('time').innerHTML='발생시각';
	document.getElementById('process').innerHTML='프로세스';
	document.getElementById('log').innerHTML='내용';
	document.getElementById('body').hidden = false;
}

function onLoad()
{
	onInit();

	enablePageTimeout();
	
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
						page_count 	= parseInt((Number(total_count) + 19) / 20);
						
						onGetLog(1);
				}
			}
			catch(e)
			{
			}
		}
	}
	xmlhttp.send();
}

function	onGetLog(index)
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
	data 		+= "&index=" + (index-1)*20;
	data 		+= "&count=" + 20;
	
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
						page_count 	= parseInt((Number(total_count) + 19) / 20);
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
						cell.innerHTML = "<td class='center'><p>" + ((index - 1)*20 + entities.length - i) + "</p></td>";
						cell.setAttribute('class','index center');
						cell = row.insertCell(1);
						cell.innerHTML = "<td class='center'><p class='time'>" + time + "</p></td>";
						cell.setAttribute('class','center');
						cell = row.insertCell(2);
						cell.innerHTML = "<td class='center'><p>" + process + "</p></td>";
						cell.setAttribute('class','center');
						cell = row.insertCell(3);
						cell.innerHTML = "<td class='center'><p>" + log + "</p></td>";
						cell.setAttribute('class','left');
				}
				
				onCreateNavi(page_count, index);
			}
			catch(e)
			{
			}
		}
	}
	xmlhttp.send();
}

function	onCreateNavi(pages, selected)
{
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
}
