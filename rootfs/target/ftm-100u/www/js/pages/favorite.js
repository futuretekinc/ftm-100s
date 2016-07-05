/**
 * Created by kindmong on 2015-10-27.
 */

var datas;

$(document).ready(function(){
    loadSensorList();
    setInterval("loadSensorList()", 5000);
    //loadSensorList();
});

function loadSensorList () {

    arr = [];

    $.ajax({
        //async:false,
        type:"get",
        url:"/cgi-bin/sensor?cmd=sensinglist",
        //url:"../js/pages/network.xml",
        dataType:"xml",
        success : function(xml) {
            // 통신이 성공적으로 이루어졌을 때 이 함수를 타게 된다.
            // TODO
            $(xml).find("SENSOR").each(function(){
                //console.log($(this).find("MAC").text(), $(this).find("ID").text());
                loadData($(this).find("MAC").text(), $(this).find("ID").text(), $(this).find("FAVORITE").text());
                //var tbody = makePanel($(this).find("MAC").text());
                //makeBody(tbody, $(this), $(this).find("MAC").text());
            });
        },
        error : function(xhr, status, error) {
            //alert("에러발생");
            window.location.href="/";
        }
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
                //tbody.remove();
                if (_favorite == true) {
                    var tbody = makePanel($(this).find("MAC").text());
                    makeBody(tbody, $(this), $(this).find("MAC").text(), _favorite);
                }
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
    col_lg_12.setAttribute("class", "col-lg-12");

    // 패널 생성
    var panel = document.createElement("div");
    panel.setAttribute("class", "panel panel-green");

    // 패널 헤더
    var panel_header = document.createElement("div");
    panel_header.setAttribute("class", "panel-heading");
    panel_header.innerHTML = _mac;

    //var panel_close_div = document.createElement("div");
    //panel_close_div.setAttribute("class", "pull-right");
    //var panel_close_btn = document.createElement("button");
    //panel_close_btn.setAttribute("class", "btn btn-danger btn-xs");
    //panel_close_btn.setAttribute("type", "button");
    //panel_close_btn.appendChild(document.createTextNode("X"));
    //panel_close_btn.addEventListener("click", function(){
    //    var parent_row = row.parentNode;
    //    parent_row.removeChild(row);
    //    row = null;
    //    removeSensorNode();
    //});

    //panel_close_div.appendChild(panel_close_btn);
    //panel_header.appendChild(panel_close_div);

    //패널 안에 센서 리스트들 테이블로 구성
    var table = document.createElement("table");
    table.setAttribute("class", "table table-bordered");
    table.setAttribute("id", "table_" + _mac);

    var thead = document.createElement("thead");
    var thead_tr = document.createElement("tr");
    thead.appendChild(thead_tr);

    var thNames = ["<span class='glyphicon glyphicon-star' aria-hidden='true'></span>", "ID", "Name", "Type", "Value", "Time", "State", "List", "Graph"];
    var className = ["col-md-1", "col-md-1", "col-md-2", "col-md-2", "col-md-1", "col-md-3", "col-md-2", "col-md-2", "col-md-2"];

    for (var i=0; i<thNames.length; i++) {
        var th = document.createElement("th");
        th.setAttribute("class", className[i]);
        thead_tr.appendChild(th).innerHTML = thNames[i];
    }
    table.appendChild(thead);

    //thead_tr.appendChild(document.createElement("th")).innerHTML = "ID";
    //thead_tr.appendChild(document.createElement("th")).innerHTML = "Name";
    //thead_tr.appendChild(document.createElement("th")).innerHTML = "Type";
    //thead_tr.appendChild(document.createElement("th")).innerHTML = "Value";
    //thead_tr.appendChild(document.createElement("th")).innerHTML = "Time";
    //thead_tr.appendChild(document.createElement("th")).innerHTML = "State";
    //thead_tr.appendChild(document.createElement("th")).innerHTML = "List";

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

function makeBody(_tbody, _item, _mac, _favorite) {

    var indexs = [];
    var values = [];
    var times = [];
    var states = [];

    $(_item).find("INDEX").each(function(){
        //console.log($(this).find("VALUE").text());
        indexs.push($(this).find("NUMBER").text());
        values.push($(this).find("VALUE").text());
        times.push($(this).find("TIME").text());
        states.push($(this).find("STATE").text());
    });

    if (document.getElementById("tr_" + _mac.replace(/"/g, "") + "_" + _item.find("ID").text().replace(/"/g, ""))) {
        //console.log("있음");
        // 있으면 이미 만들어진 칼럼을 갱신한다.
        var tr = document.getElementById("tr_" + _mac.replace(/"/g, "") + "_" + _item.find("ID").text().replace(/"/g, ""));
        //console.log(Number(true), Number(false));

        var cb_input = document.getElementById("cb_" + _mac.replace(/"/g, "") + "_" + _item.find("ID").text().replace(/"/g, ""));
        cb_input.checked = Number(_favorite);
        tr.cells[1].innerHTML = _item.find("ID").text();
        tr.cells[2].innerHTML = _item.find("NAME").text();
        tr.cells[3].innerHTML = _item.find("TYPE").text();
        tr.cells[4].innerHTML = values[0];
        tr.cells[5].innerHTML = times[0];
        tr.cells[6].innerHTML = states[0];

        var listBtn = document.getElementById("btn_" + _mac + "_" + _item.find("ID").text());
        listBtn.removeEventListener("click");

        listBtn.addEventListener("click", function() {
            //console.log("test ", this.id);

            // 이전 데이터를 삭제하여 테이블을 비운다.
            $("#modal_table tr:not(:first)").remove();

            var modal_tbody = document.getElementById("modal_tbody");
            for (var i=0; i<values.length; i++) {
                var modal_tr = document.createElement("tr");
                modal_tr.appendChild(document.createElement("td")).innerHTML = indexs[i];
                modal_tr.appendChild(document.createElement("td")).innerHTML = _item.find("ID").text();
                modal_tr.appendChild(document.createElement("td")).innerHTML = _item.find("NAME").text();
                modal_tr.appendChild(document.createElement("td")).innerHTML = _item.find("TYPE").text();
                modal_tr.appendChild(document.createElement("td")).innerHTML = values[i];
                modal_tr.appendChild(document.createElement("td")).innerHTML = times[i];
                modal_tr.appendChild(document.createElement("td")).innerHTML = states[i];
                modal_tbody.appendChild(modal_tr);
            }

            document.getElementById("modal_title").innerHTML = _item.find("MAC").text();// + " - " + _item.find("ID").text();
            $("#myModal").modal();
        });

        var graphBtn = document.getElementById("graphbtn_" + _mac + "_" + _item.find("ID").text());
        graphBtn.removeEventListener("click");
        graphBtn.addEventListener("click", function() {
            // 이전 데이터를 삭제하여 테이블을 비운다.
            $("#modal_table tr:not(:first)").remove();
            datas = [];
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
            document.getElementById("modalgraph_title").innerHTML = _item.find("MAC").text() + " - " + _item.find("ID").text();
            $("#myModalGraph").modal();
        });

        return;
    }

    // 처음 들어왔을때 리스트 만들기.
    var tbody_tr = document.createElement("tr");
    _tbody.appendChild(tbody_tr);

    var cb_input = document.createElement("input");
    cb_input.type = "checkbox";
    cb_input.value = "";
    cb_input.setAttribute("id", "cb_" + _mac.replace(/"/g, "") + "_" + _item.find("ID").text().replace(/"/g, ""));// + "_" + _index);
    cb_input.addEventListener("change", onCheckboxClicked);
    tbody_tr.appendChild(document.createElement("th")).appendChild(cb_input);
    cb_input.checked = Number(_favorite);

    tbody_tr.appendChild(document.createElement("td")).innerHTML = _item.find("ID").text();
    tbody_tr.setAttribute("id", "tr_" + _mac.replace(/"/g, "") + "_" + _item.find("ID").text().replace(/"/g, ""));

    tbody_tr.appendChild(document.createElement("td")).innerHTML = _item.find("NAME").text();
    tbody_tr.appendChild(document.createElement("td")).innerHTML = _item.find("TYPE").text();
    tbody_tr.appendChild(document.createElement("td")).innerHTML = values[0];
    tbody_tr.appendChild(document.createElement("td")).innerHTML = times[0];
    tbody_tr.appendChild(document.createElement("td")).innerHTML = states[0];

    var btn_list = document.createElement("button");
    btn_list.setAttribute("class", "btn btn-info btn-xs");
    btn_list.setAttribute("type", "button");
    btn_list.setAttribute("id", "btn_" + _mac + "_" + _item.find("ID").text());
    btn_list.appendChild(document.createTextNode("LIST"));
    btn_list.addEventListener("click", function() {
        // 이전 데이터를 삭제하여 테이블을 비운다.
        $("#modal_table tr:not(:first)").remove();

        var modal_tbody = document.getElementById("modal_tbody");
        for (var i=0; i<values.length; i++) {
            var modal_tr = document.createElement("tr");
            modal_tr.appendChild(document.createElement("td")).innerHTML = indexs[i];
            modal_tr.appendChild(document.createElement("td")).innerHTML = _item.find("ID").text();
            modal_tr.appendChild(document.createElement("td")).innerHTML = _item.find("NAME").text();
            modal_tr.appendChild(document.createElement("td")).innerHTML = _item.find("TYPE").text();
            modal_tr.appendChild(document.createElement("td")).innerHTML = values[i];
            modal_tr.appendChild(document.createElement("td")).innerHTML = times[i];
            modal_tr.appendChild(document.createElement("td")).innerHTML = states[i];
            modal_tbody.appendChild(modal_tr);
        }

        document.getElementById("modal_title").innerHTML = _item.find("MAC").text();// + " - " + _item.find("ID").text();
        //document.getElementById("sensor_name").value = _item.find("NAME").text();
        $("#myModal").modal();
    });
    tbody_tr.appendChild(document.createElement("th")).appendChild(btn_list);

    // 그래프 버튼
    var btn_graph = document.createElement("button");
    btn_graph.setAttribute("class", "btn btn-info btn-xs");
    btn_graph.setAttribute("type", "button");
    btn_graph.setAttribute("id", "graphbtn_" + _mac + "_" + _item.find("ID").text());
    btn_graph.appendChild(document.createTextNode("GRAPH"));
    btn_graph.addEventListener("click", function() {
        //console.log("test ", this.id);

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

        document.getElementById("modalgraph_title").innerHTML = _item.find("MAC").text() + " - " + _item.find("ID").text();
        //document.getElementById("sensor_name").value = _item.find("NAME").text();
        $("#myModalGraph").modal();
    });
    tbody_tr.appendChild(document.createElement("th")).appendChild(btn_graph);
}

function onCheckboxClicked() {
    // 체크의 여부에 따라 Favorite에 등록 및 제거를 한다.
    console.log(this.id, this.checked);
    var mac = this.id.substr(3, 17);
    var id = this.id.substr(21);
    var checked = Number(this.checked);
    console.log(mac, id, checked);

    $.ajax({
        //async:false,
        type:"get",
        url:"/cgi-bin/sensor?cmd=modifylist&mac=" + mac + "&id=" + id + "&checked=" + checked,
        dataType:"xml",
        success : function(xml) {
            // 통신이 성공적으로 이루어졌을 때 이 함수를 타게 된다.
            // TODO
            $(xml).find("SENSOR_MODIFY").each(function(){
                console.log($(this).find("RET").text());

                if ($(this).find("RET").text() == "OK") {
                    if (checked == 0) {
                        //alert("remove favorite list");
                        // 리스트에서 삭제
                        var tr = document.getElementById("tr_" + mac + "_" + id);
                        console.log("test = ", tr);
                        var tr_parent = tr.parentNode;
                        tr_parent.removeChild(tr);
                        tr = null;

                        // 패널에 센서 리스트가 남아있는지 확인하여 패널도 UI에서 제거한다.


                    } else {
                        alert("add favorite list");
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