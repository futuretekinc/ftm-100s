function reload()
{
   setTimeout('reloadImg("refresh")',1000/6000)
}

function reloadImg(id) 
{ 
   var obj = document.getElementById(id); 
   var date = new Date(); 
   obj.src = "http://10.0.1.43:88/cgi-bin/CGIProxy.fcgi?cmd=snapPicture2&usr=futuretek&pwd=futuretek&t=" + Math.floor(date.getTime()/1000); 
}