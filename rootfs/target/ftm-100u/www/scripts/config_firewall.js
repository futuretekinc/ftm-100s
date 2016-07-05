var msgBtnRemove=0;
var	msgUpdateSuccess=1;
var	msgUpdateFailed=2;
var msg;

function onInit()
{
	document.getElementById('page_title').innerHTML = '방화벽 설정';
	document.getElementById('section1_title').innerHTML='접근 제어 설정';
	document.getElementById('title_index').innerHTML='번호';
	document.getElementById('title_type').innerHTML='구분';
	document.getElementById('title_sip').innerHTML='주소';
	document.getElementById('title_protocol').innerHTML='프로토콜';
	document.getElementById('title_dport').innerHTML='포트';
	document.getElementById('btn_apply').value='적용';
	document.getElementById('btn_add').value='추가';
	document.getElementById('enable').innerHTML="<input type='checkbox' name='enable'>사용";
	
	msg = new Array();
	
	msg[msgBtnRemove]='제거';
	msg[msgUpdateSuccess]='제어 규칙이 정상적으로 적용되었습니다.\n';
	msg[msgUpdateFailed]='제어 규칙이 적용에 문제가 발생하였습니다.\n';
	
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
	
	var data = "/cgi-bin/firewall?cmd=status";
	
	xmlhttp.open( "POST", data, true );
	xmlhttp.setRequestHeader("Content-Type","application/x-www-form-urlencoded;charset=euc-kr");
	xmlhttp.onreadystatechange = function()
	{
		if( (xmlhttp.readyState == 4) && (xmlhttp.status == 200) )
		{
			try
			{
				state = xmlhttp.responseXML.documentElement.getElementsByTagName("STATE");
				if (state .length != 0)
				{
					if (state[0].firstChild.nodeValue == 'enabled')
					{
						document.f.enable.checked = true;
					}
					else
					{
						document.f.enable.checked = false;
					}
				}

				rules = xmlhttp.responseXML.documentElement.getElementsByTagName("RULE");
				for (i = 0 ; i < rules.length ; i++)
				{
					dir = rules[i].getElementsByTagName('DIR')[0].firstChild.nodeValue;
					sip = rules[i].getElementsByTagName('SIP')[0].firstChild.nodeValue;
					proto = rules[i].getElementsByTagName('PROTO')[0].firstChild.nodeValue;
					dport = rules[i].getElementsByTagName('DPORT')[0].firstChild.nodeValue;
					
					if (dir == 'IN')
					{
						addHost(sip, proto, dport);
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

function createOption(value, txt)
{
	var item = document.createElement('option');
	item.value=value;
	item.innerHTML=txt;
	
	return	item;
}

function createAddressType(_type, _callback)
{
	var item = document.createElement('select');
	item.appendChild(createOption(0, 'Single'));
	item.appendChild(createOption(1, 'Any'));
	item.id = 'type';
	item.value = _type;
	item.onchange=function()
	{
		if (item.value == 0)
		{
			_callback(false);
		}
		else
		{
			_callback(true);
		}
	}
	
	return	item;
}

function createProtocolType(type)
{
	var item = document.createElement('select');
	//item.appendChild(createOption('all', 'ALL'));
	item.appendChild(createOption('tcp', 'TCP'));
	item.appendChild(createOption('udp', 'UDP'));
	item.appendChild(createOption('icmp', 'ICMP'));
	item.id = 'type';
	item.value = type;
	
	return	item;
}

function createInput(value, _class, _readonly)
{
	var item = document.createElement('input');
	item.type = 'text';
	item.value = value;
	item.setAttribute('class', _class);
	item.readOnly = _readonly;
	
	return	item;
}

function createBtn(value, _class, _onclick)
{
	var item = document.createElement('input');
	item.type = 'button';
	item.value = value;
	item.onclick = _onclick;
	item.setAttribute('onclick', _onclick);
	item.setAttribute('class', _class);
	
	return	item;
}

function addHost(sip, proto, dport)
{
	table = document.getElementById('control_table');
	index = table.rows.length - 1;
	row = table.insertRow(index);
	
	if (sip == '0.0.0.0')
	{
		var input_sip 	= createInput(sip, 'ipaddr', true);
		var select_type	= createAddressType(1, function(_readonly) {input_sip.value='0.0.0.0'; input_sip.readOnly=_readonly;});
	}
	else
	{
		var input_sip = createInput(sip, 'ipaddr', false);
		var select_type	= createAddressType(0, function(_readonly) {input_sip.readOnly=_readonly;});
	}
	
	cell = row.insertCell(0);
	cell.setAttribute('class','center');
	cell.innerHTML = index;
	cell = row.insertCell(1);
	cell.setAttribute('class','center');
	cell.appendChild(select_type);
	cell = row.insertCell(2);
	cell.setAttribute('class','center');
	cell.appendChild(input_sip);	
	cell = row.insertCell(3);
	cell.setAttribute('class','center');
	cell.appendChild(createProtocolType(proto));
	cell = row.insertCell(4);
	cell.setAttribute('class','center');
	cell.appendChild(createInput(dport, "port"));
		cell = row.insertCell(5);
	cell.setAttribute('class','center');
	cell.appendChild(createBtn(msg[msgBtnRemove], "", "onRemoveHost(" + (index) + ");"));
}

function onAddHost()
{
	addHost('0.0.0.0', 'all', '0');
}

function onRemoveHost(index)
{
	table = document.getElementById('control_table');
	if (0 < index && index < table.rows.length - 1)
	{
		table.deleteRow(index);
		for( ; index < table.rows.length - 1; index++)
		{
			table.rows[index].cells[0].innerHTML = index;
			table.rows[index].cells[5].firstChild.setAttribute("onclick", "onRemoveHost(" + (index) + ");");
		}
	}
}

function onApply()
{
	if(typeof window.ActiveXObject != 'undefined')
	{
		xmlhttp = (new ActiveXObject("Microsoft.XMLHTTP"));
	}
	else
	{
		xmlhttp = (new XMLHttpRequest());
	}

	var data = "/cgi-bin/firewall?cmd=set";

	if (document.f.enable.checked == true)
	{
		data += "&state=enabled" ;
	}
	else
	{
		data += "&state=disabled" ;
	}
	
	table = document.getElementById('control_table');
	for(i = 1 ; i < table.rows.length - 1; i++)
	{
		data += '&sip' + (i-1) + '=' + table.rows[i].cells[2].firstChild.value;
		data += '&proto' + (i-1) + '=' + table.rows[i].cells[3].firstChild.value;
		data += '&dport' + (i-1) + '=' + table.rows[i].cells[4].firstChild.value;
	}
	
	xmlhttp.open( "POST", data, true );
	xmlhttp.setRequestHeader("Content-Type","application/x-www-form-urlencoded;charset=euc-kr");
	xmlhttp.onreadystatechange = function()
	{
		if( (xmlhttp.readyState == 4) && (xmlhttp.status == 200) )
		{
			try
			{
				ret = xmlhttp.responseXML.documentElement.getElementsByTagName("RET")[0].firstChild.nodeValue;
				if (ret == 'OK')
				{
					alert(msg[msgUpdateSuccess]);
				}
				else
				{
					alert(msg[msgUpdateFailed]);
				}
			}
			catch(e)
			{
			}
		}
	}
	xmlhttp.send();
}
