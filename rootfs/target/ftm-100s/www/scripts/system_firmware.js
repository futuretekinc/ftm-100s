var msgTheFileIsBeingTransferred=0;
var msgTransferComplete=1;
var msgDoYouWantToContinueUpgrade=2;
var msgTheUpgardeCanceled=3;
var msgTheUpgradeCompleted=4;
var msgPleaseSelectTheFirmware=5;
var msgTheFirmwareIsUpdating=6;
var msgTheFirmwareUpdateCompleted=7;
var msgIncorrectFirmware;
var msg;

/*
var opts = {
  lines: 11, // The number of lines to draw
  length: 5, // The length of each line
  width: 10, // The line thickness
  radius: 20, // The radius of the inner circle
  corners: 1, // Corner roundness (0..1)
  rotate: 0, // The rotation offset
  direction: 1, // 1: clockwise, -1: counterclockwise
  color: '#000', // #rgb or #rrggbb or array of colors
  speed: 1, // Rounds per second
  trail: 60, // Afterglow percentage
  shadow: false, // Whether to render a shadow
  hwaccel: false, // Whether to use hardware acceleration
  className: 'spinner', // The CSS class to assign to the spinner
  zIndex: 2e9, // The z-index (defaults to 2000000000)
  top: '50%', // Top position relative to parent
  left: '50%' // Left position relative to parent
};
*/
var spinner;

function onInit()
{
	msg = new Array();
	msg[msgTheFileIsBeingTransferred]	= "파일 전송중 입니다.";
	msg[msgTransferComplete]			= "파일 전송을 완료 하였습니다.";
	msg[msgDoYouWantToContinueUpgrade]	= "파일 전송을 완료 하였습니다.\n펌웨어 업그레이드를 진행하시겠습니까?";
	msg[msgIncorrectFirmware]			= " 전송된 펌웨어가 올바르지 않습니다.\n확인 후 재전송해 주시기 바랍니다.";
	msg[msgTheUpgardeCanceled] 			= "펌웨어 업그레이드가 취소되었습니다.";
	msg[msgTheUpgradeCompleted] 		= "파일 업그레이드를 완료 하였습니다.\n정상적인 동작을 위해서 시스템 재시작이 필요합니다.\n재시작 하겠습니까?";
	msg[msgPleaseSelectTheFirmware]		= "업그레이드용 펌웨어를 선택해 주십시오.";
	msg[msgTheFirmwareIsUpdating]	= "펌웨어 업데이트 중 입니다.";
	msg[msgTheFirmwareUpdateCompleted]	= "펌웨어 업데이트가 입니다.";
	
	document.getElementById('page_title').innerHTML="시스템/펌웨어 관리";
	document.getElementById('section1_title').innerHTML="펌웨어 정보";
	document.getElementById('section2_title').innerHTML="펌웨어 업그레이드";
	document.getElementById('firm_index').innerHTML="순번";
	document.getElementById('firm_type').innerHTML="종류";
	//document.getElementById('firm_time').innerHTML="빌드 시간";
	//document.getElementById('firm_size').innerHTML="크기";
	document.getElementById('firm_ver').innerHTML="버전";
	
	document.getElementById('msg').innerHTML = msg[msgPleaseSelectTheFirmware];
	document.getElementById('apply').value = "업그레이드 시작";

	document.getElementById('body').hidden = false;
}

function addInfo(type, time, size, desc)
{
	table = document.getElementById('info');

	row = table.insertRow(-1);
	cell = row.insertCell(0);
	cell.setAttribute('class', 'center');
	cell.innerHTML = table.rows.length - 1;
	cell = row.insertCell(1);
	cell.setAttribute('class', 'center');
	cell.innerHTML = type;
	cell = row.insertCell(2);
	cell.setAttribute('class', 'center');
	
	/*
	var	d = new Date();
	d.setTime(time * 1000);
	cell.innerHTML = d.toGMTString();
	cell = row.insertCell(3);
	cell.setAttribute('class', 'center');
	cell.innerHTML = size;
	cell = row.insertCell(4);
	*/
	cell.setAttribute('class', 'right');
	cell.innerHTML = desc;
}

function onLoad()
{
	spinner = new Spinner();
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
	
	var data = "/cgi-bin/system?cmd=fw_info";
	
	xmlhttp.open( "POST", data, true );
	xmlhttp.setRequestHeader("Content-Type","application/x-www-form-urlencoded;charset=euc-kr");
	xmlhttp.onreadystatechange = function()
	{
		if( (xmlhttp.readyState == 4) && (xmlhttp.status == 200) )
		{
			try
			{
				//kernel = xmlhttp.responseXML.documentElement.getElementsByTagName("kernel")[0].firstChild.nodeValue;
				rootfs = xmlhttp.responseXML.documentElement.getElementsByTagName("rootfs")[0].firstChild.nodeValue;

				//addInfo("KERNEL", 0, 0, kernel);
				addInfo("ROOTFS", 0, 0, rootfs);
			}
			catch(e)
			{
			}
		}
	}
	xmlhttp.send();
}

function onSystemReboot()
{
	if(typeof window.ActiveXObject != 'undefined')
	{
		xmlhttp = (new ActiveXObject("Microsoft.XMLHTTP"));
	}
	else
	{
		xmlhttp = (new XMLHttpRequest());
	}

	var data = "/cgi-bin/system?cmd=reboot";

	xmlhttp.open( "POST", data, true );
	xmlhttp.setRequestHeader("Content-Type","application/x-www-form-urlencoded;charset=euc-kr");
	xmlhttp.onreadystatechange = function()
	{
		if( (xmlhttp.readyState == 4) && (xmlhttp.status == 200) )
		{
			try
			{
				ret  = xmlhttp.responseXML.documentElement.getElementsByTagName("RET");
				if (ret[0].firstChild.nodeValue == 'OK')
				{
					alert(msg[msgResetaring]);
				}
				else
				{
					alert(msg[msgRestartFailed]);
				}
			}
			catch(e)
			{
				window.location.href = '/';
			}
		}
	}
	xmlhttp.send();
}

/*
function onProgress()
{
	if(typeof window.ActiveXObject != 'undefined')
	{
		xmlhttp = (new ActiveXObject("Microsoft.XMLHTTP"));
	}
	else
	{
		xmlhttp = (new XMLHttpRequest());
	}
	
	var data = "/cgi-bin/system?cmd=fw_progress";
	
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
					progress= xmlhttp.responseXML.documentElement.getElementsByTagName("PROGRESS")[0].firstChild.nodeValue;
					if (progress == '100')
					{
						document.getElementById('msg').innerHTML = msg[msgTheFileUpdateCompleted] + 
												+ "[ 100 % ]"; 		
						alert(msg[msgTheUpgradeCompleted]);
					}
					else
					{
						document.getElementById('msg').innerHTML = msg[msgTheFileIsUpdating] + 
												+ "[ " + progress + "% ]"; 		
						setTimeout(onProgress, 1000);
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
*/

function onApplyUpgrade(filename)
{
	if(typeof window.ActiveXObject != 'undefined')
	{
		xmlhttp = (new ActiveXObject("Microsoft.XMLHTTP"));
	}
	else
	{
		xmlhttp = (new XMLHttpRequest());
	}
	
	var data = "/cgi-bin/system?cmd=fw_upgrade&fn=" + filename;
	
	xmlhttp.open( "POST", data, true );
	xmlhttp.setRequestHeader("Content-Type","application/x-www-form-urlencoded;charset=euc-kr");
	xmlhttp.onreadystatechange = function()
	{
		if( (xmlhttp.readyState == 4) && (xmlhttp.status == 200) )
		{
			try
			{
				//setTimeout(onProgress, 1000);
				result = xmlhttp.responseXML.documentElement.getElementsByTagName("RET")[0];
            	if (result.firstChild.nodeValue == 'OK') {
					spinner.stop();
					alert(msg[msgTheUpgradeCompleted]);
					onSystemReboot();
				}
			}
			catch(e)
			{
			}
		}
	}
	xmlhttp.send();
}

function onUpdateProgress(evt)
{
	if (evt.loaded != evt.total)
	{
		document.getElementById('msg').innerHTML = msg[msgTheFileIsBeingTransferred] 
												+ "[" + evt.loaded + "/" + evt.total + "]"; 		
	}
	else
	{
		document.getElementById('msg').innerHTML = msg[msgTransferComplete] 
												+ "[" + evt.loaded + "/" + evt.total + "]"; 		
	}
}

				
function onApplyUpload()
{
	/*
	if(typeof window.ActiveXObject != 'undefined')
	{
		xmlhttp = (new ActiveXObject("Microsoft.XMLHTTP"));
	}
	else
	{
		xmlhttp = (new XMLHttpRequest());
	}
	*/
	xmlhttp = (new XMLHttpRequest());
	//xmlhttp.upload.addEventListener("progress", onUpdateProgress, false);
	xmlhttp.upload.onprogress = onUpdateProgress;
	
	xmlhttp.onload=function()
	{
		ret = xmlhttp.responseXML.documentElement.getElementsByTagName("RET");
		if (ret.length != 0)
		{
			if (ret[0].firstChild.nodeValue == 'OK')
			{
				/*
				var	fw_info = "";

				info = xmlhttp.responseXML.documentElement.getElementsByTagName("IMG_INFO")[0];
						
				fw_info = "\n<Information>\n" 
						+ "\nType: " + info.getElementsByTagName('TYPE')[0].firstChild.nodeValue 
						+ "\nTime: " + info.getElementsByTagName('TIME')[0].firstChild.nodeValue 
						+ "\nSize: " + info.getElementsByTagName('SIZE')[0].firstChild.nodeValue 
						+ "\nDesc: " + info.getElementsByTagName('DESC')[0].firstChild.nodeValue ;

				*/
				if (confirm(msg[msgDoYouWantToContinueUpgrade]))
				{
					var target = document.getElementById('body');
					spinner.spin(target);
					onApplyUpgrade(document.f.file.files[0].name);	
				}
				else
				{
					alert(msg[msgTheUpgardeCanceled])
				}
			} else {
				alert(msg[msgIncorrectFirmware]);
			}
		}
		else
		{
			alert(msg[msgIncorrectFirmware]);
		}
	}

	var fd = new FormData();
		
	var data = "/cgi-bin/system?cmd=fw_upload";
	
	xmlhttp.open( "POST", data, true );
	xmlhttp.onreadystatechange = function()
	{
		if( (xmlhttp.readyState == 4) && (xmlhttp.status == 200) )
		{
		}
	}
	fd.append('file', document.f.file.files[0]);
	xmlhttp.send(fd);
}
