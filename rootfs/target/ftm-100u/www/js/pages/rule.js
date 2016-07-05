/**
 * Created by kindmong on 2015-10-27.
 */

$(document).ready(function(){
    loadSensorList();
});

function loadSensorList () {

    $.ajax ({
        type:"get",
        url:"/cgi-bin/ep?cmd=list&field1=all",
        async:false,
        dataType:"json",
        success:response_list
    });
}

function response_list(json) {
    console.log(json);
    var eps = json.eps;
    var eps_count = json.length;

    $.each(eps, function(key){
        console.log("epid :", eps[key].epid, "type :", eps[key].type, "name :", eps[key].name, "unit :", eps[key].unit, "interval :", eps[key].interval, "did :", eps[key].did, "limit_type :", eps[key].limit.type, "limit_count :", eps[key].limit.count);
        var tbody = makePanel(eps[key].did);
        makeBody(tbody, eps[key]);
    });
}

function loadData (_mac, _id, _favorite) {

    $.ajax({
        //async:false,
        type:"get",
        url:"/cgi-bin/sensor?cmd=dashboard&mac=" + _mac + "&id=" + _id,
        //url:"../js/pages/network.xml",
        dataType:"xml",
        success : function(xml) {
            // 통신이 성공적으로 이루어졌을 때 이 함수를 타게 된다.
            // TODO
            $(xml).find("SENSOR").each(function(){
                //console.log($(this).find("MAC").text());
                //arr.push($(this));
                //console.log("Asdfasdfasdf");
                var tbody = makePanel($(this).find("MAC").text());
                //tbody.remove();
                makeBody(tbody, $(this), $(this).find("MAC").text(), _favorite);
            });
        },
        error : function(xhr, status, error) {
            //alert("에러발생");
            window.location.href="/";
        }
    });
}

function makePanel(_mac) {

    if (document.getElementById("row_" + _mac)) {
        //console.log("있음");
        return document.getElementById("tbody_" + _mac);
    }

    // 패널을 추가할 row 생성
    var row = document.createElement("div");
    row.setAttribute("id", "row_" + _mac);
    row.setAttribute("class", "row");

    var col_lg_12 = document.createElement("div");
    //col_lg_12.setAttribute("class", "col-lg-12");

    // 패널 생성
    var panel = document.createElement("div");
    panel.setAttribute("class", "panel panel-green");

    // 패널 헤더
    var panel_header = document.createElement("div");
    panel_header.setAttribute("class", "panel-heading");
    panel_header.innerHTML = _mac;

    //패널 안에 센서 리스트들 테이블로 구성
    var table = document.createElement("table");
    table.setAttribute("class", "table table-bordered");
    table.setAttribute("id", "table_" + _mac);

    var thead = document.createElement("thead");
    var thead_tr = document.createElement("tr");
    thead.appendChild(thead_tr);

    //var thNames = ["<span class='glyphicon glyphicon-star' aria-hidden='true'></span>", "epid", "type", "name", "unit", "interval"];
    var thNames = ["epid", "type", "name", "unit", "interval", "time", "value", "list"];
    //var className = ["col-md-1", "col-md-1", "col-md-2", "col-md-2", "col-md-1", "col-md-3", "col-md-2", "col-md-2"];

    for (var i=0; i<thNames.length; i++) {
        var th = document.createElement("th");
        //th.setAttribute("class", className[i]);
        thead_tr.appendChild(th).innerHTML = thNames[i];
    }
    table.appendChild(thead);

    var tbody = document.createElement("tbody");
    tbody.setAttribute("id", "tbody_" + _mac);
    table.appendChild(tbody);

    row.appendChild(col_lg_12);
    col_lg_12.appendChild(panel);
    panel.appendChild(panel_header);
    panel.appendChild(table);

    document.getElementById("page-wrapper").appendChild(row);

    return tbody;
}

function makeBody(_tbody, _eps) {

    var tbody_tr = document.createElement("tr");
    _tbody.appendChild(tbody_tr);

    tbody_tr.appendChild(document.createElement("td")).innerHTML = _eps.epid;
    tbody_tr.setAttribute("id", "tr_" + _eps.epid);

    tbody_tr.appendChild(document.createElement("td")).innerHTML = _eps.type;
    tbody_tr.appendChild(document.createElement("td")).innerHTML = _eps.name;
    tbody_tr.appendChild(document.createElement("td")).innerHTML = _eps.unit;
    tbody_tr.appendChild(document.createElement("td")).innerHTML = _eps.interval;
    tbody_tr.appendChild(document.createElement("td")).innerHTML = "";
    tbody_tr.appendChild(document.createElement("td")).innerHTML = "";
    
    var btn_list = document.createElement("button");
    btn_list.setAttribute("class", "btn btn-info btn-xs");
    btn_list.setAttribute("type", "button");
    btn_list.setAttribute("id", "btn_" + _eps.epid);
    btn_list.appendChild(document.createTextNode("list"));
    btn_list.addEventListener("click", function() {
        
        // 이전 데이터를 삭제하여 테이블을 비운다.
        $("#modal_table tr:not(:first)").remove();
        var modal_tbody = document.getElementById("modal_tbody");
        
        console.log(_eps.epid);
        $.ajax ({
            type:"get",
            url:"/cgi-bin/data?cmd=get&epid=" + _eps.epid + "&index=0&count=10",
            async:false,
            dataType:"json",
            success:function(json) {
                var values = json.data;

                for (var i=0; i<values.length; i++) {
                    var modal_tr = document.createElement("tr");
                    modal_tr.appendChild(document.createElement("td")).innerHTML = i + 1;
                    modal_tr.appendChild(document.createElement("td")).innerHTML = _eps.type;
                    modal_tr.appendChild(document.createElement("td")).innerHTML = _eps.name;
                    modal_tr.appendChild(document.createElement("td")).innerHTML = values[i].time;
                    modal_tr.appendChild(document.createElement("td")).innerHTML = values[i].value;
                    modal_tbody.appendChild(modal_tr);
                }
            }
        });

        document.getElementById("modal_title").innerHTML = _eps.epid;
        $("#myModal").modal();
    });
    tbody_tr.appendChild(document.createElement("td")).appendChild(btn_list);

    // 그래프 버튼
    /*var btn_graph = document.createElement("button");
    btn_graph.setAttribute("class", "btn btn-info btn-xs");
    btn_graph.setAttribute("type", "button");
    btn_graph.setAttribute("id", "graphbtn_" + _eps.epid);
    btn_graph.appendChild(document.createTextNode("GRAPH"));
    btn_graph.addEventListener("click", function() {
        
        // 이전 데이터를 삭제하여 테이블을 비운다.
        $("#modal_table tr:not(:first)").remove();
        datas = [];
        var modal_tbody = document.getElementById("modal_tbody");
        for (var i=1; i<=values.length; i++) {
            var value;
			if (values[values.length - i] == "N/A")
			{
				value = 0;
			} else {
				value = values[values.length - i];
			}
			var json = {time: times[values.length - i], value: value};
			console.log(json);
			datas.push(json);
        }
        //console.log(datas);
        document.getElementById("modalgraph_title").innerHTML = _item.find("MAC").text() + " - " + _item.find("ID").text();
        $("#myModalGraph").modal();
    });
    tbody_tr.appendChild(document.createElement("th")).appendChild(btn_graph);*/
}

function asyncEps() {
    $.ajax ({
        type:"get",
        url:"/cgi-bin/ep?cmd=list",
        async:false,
        dataType:"json",
        success:getAsyncEps
    });
}

function getAsyncEps(json) {
    var eps = json.eps;
    $.each(eps, function(key){
        console.log(eps[key].epid);
        loadAsyncEps(eps[key].epid);
    });
}

function loadAsyncEps(epid) {
    $.ajax ({
        type:"get",
        url:"/cgi-bin/data?cmd=get&epid=" + epid + "&index=0&count=1",
        async:false,
        dataType:"json",
        success:function(json) {
            var result = json.result;
            if (result == "success") {
                var data = json.data;
                var epid = json.epid;
                var time = data[0].time;
                var value = data[0].value;
                console.log(epid, value, time);
                
                var tr = document.getElementById("tr_" + epid);
                var time_td = tr.cells[5];
                var value_td = tr.cells[6];

                time_td.innerHTML = time;
                value_td.innerHTML = value;
            } else {
                console.log("load fail");
            }
        }
    });
}

function onCheckboxClicked() {
    // 체크의 여부에 따라 Favorite에 등록 및 제거를 한다.
    //console.log(this.id, this.checked);
    var mac = this.id.substr(3, 17);
    var id = this.id.substr(21);
    var checked = Number(this.checked);
    //console.log(mac, id, checked);

    $.ajax({
        //async:false,
        type:"get",
        url:"/cgi-bin/sensor?cmd=modifylist&mac=" + mac + "&id=" + id + "&checked=" + checked,
        dataType:"xml",
        success : function(xml) {
            // 통신이 성공적으로 이루어졌을 때 이 함수를 타게 된다.
            // TODO
            //$(xml).find("SENSOR_MODIFY").each(function(){
            //    //console.log($(this).find("RET").text());
            //
            //    if ($(this).find("RET").text() == "OK") {
            //        if (checked == 0) {
            //            alert("remove favorite list");
            //        } else {
            //            alert("add favorite list");
            //        }
            //    }
            //});
        },
        error : function(xhr, status, error) {
            //alert("에러발생");
            window.location.href="/";
        }
    });
}

function modifySensor() {
    // db 수정

    // 리스트에서 수정
    var id = document.getElementById("modal_title").innerHTML;
    var tr = document.getElementById("tr_" + id);
    console.log(tr);
    var td = tr.childNodes.item(1);
    console.log(td);
    td.innerHTML = document.getElementById("sensor_name").value;
}

function delSensorList() {

    console.log("센서 삭제");

    $.each (sensors, function (index, value){
        var mac = value.substr(3, 17);
        var id = value.substr(21);
        console.log(index, mac, id);

        $.ajax({
            async:false,
            type:"post",
            url:"/cgi-bin/sensor?cmd=set&mac=" + mac + "&id=" + id,
            //url:"../js/pages/network.xml",
            dataType:"xml",
            success : function(xml) {
                // 통신이 성공적으로 이루어졌을 때 이 함수를 타게 된다.
                // TODO
                $(xml).find("SENSOR_ADDED").each(function(){
                    console.log($(this).find("RET").text());
                    removeList(mac, id);
                    if (sensors.length == index + 1) {
                        alert("SAVE SENSOR");
                    }
                });
            },
            error : function(xhr, status, error) {
                //alert("에러발생");
                window.location.href="/";
            }
        });
    });
    sensors = [];
}

function removeSensor() {
    // db에서 삭제
    var mac = document.getElementById("modal_title").innerHTML.substr(0, 17);
    var id = document.getElementById("modal_title").innerHTML.substr(20);

    $.ajax({
        async:false,
        type:"post",
        url:"/cgi-bin/sensor?cmd=delete&mac=" + mac + "&id=" + id,
        dataType:"xml",
        success : function(xml) {
            // 통신이 성공적으로 이루어졌을 때 이 함수를 타게 된다.
            // TODO
            $(xml).find("SENSOR_ADDED").each(function(){
                console.log($(this).find("RET").text());

                if ($(this).find("RET").text() == "OK") {
                    alert("DELETE SENSOR");
                }
            });
        },
        error : function(xhr, status, error) {
            //alert("에러발생");
            window.location.href="/";
        }
    });

    // 리스트에서 삭제
    var tr = document.getElementById("tr_" + mac + "_" + id);
    console.log(tr);
    var tr_parent = tr.parentNode;
    tr_parent.removeChild(tr);
    tr = null;
}

$('#myModalGraph').on('shown.bs.modal', function () {
    $( "#myfirstchart" ).empty();
    new Morris.Line({
        // ID of the element in which to draw the chart.
        element: 'myfirstchart',
        // Chart data records -- each entry in this array corresponds to a point on
        // the chart.
        data: datas,
        // The name of the data record attribute that contains x-values.
        xkey: 'time',
        // A list of names of data record attributes that contain y-values.
        ykeys: ['value'],
		parseTime: false,
        // Labels for the ykeys -- will be displayed when you hover over the
        // chart.
        labels: ['Value']
    });
});