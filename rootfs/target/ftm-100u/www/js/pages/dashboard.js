/**
 * Created by kindmong on 2015-10-27.
 */

function init() {
    $.li18n.currentLocale = 'kr';
    document.getElementById("menu_dashboard").innerHTML = _t('dashboard');
    document.getElementById("menu_sensors").innerHTML = _t('sensors');
    document.getElementById("menu_clouds").innerHTML = _t('clouds');
    document.getElementById("menu_network").innerHTML = _t('network');
    document.getElementById("menu_system").innerHTML = _t('system');
    document.getElementById("menu_sensornodes").innerHTML = _t('sensornodes');
    document.getElementById("menu_rule").innerHTML = _t('rule');
}

$(document).ready(function(){
    init();
    loadSensorList();
    asyncEps();
    setInterval("asyncEps()", 5000);
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

function makePanel(_did) {

    if (document.getElementById("row_" + _did)) {
        //console.log("있음");
        return document.getElementById("tbody_" + _did);
    }

    // 패널을 추가할 row 생성
    var row = document.createElement("div");
    row.setAttribute("id", "row_" + _did);
    row.setAttribute("class", "row");

    var col_lg_12 = document.createElement("div");
    //col_lg_12.setAttribute("class", "col-lg-12");

    // 패널 생성
    var panel = document.createElement("div");
    panel.setAttribute("class", "panel panel-green");

    // 패널 헤더
    var panel_header = document.createElement("div");
    panel_header.setAttribute("class", "panel-heading");
    panel_header.setAttribute("style", "font-size:120%; font-weight: bold");
    panel_header.innerHTML = _did;

    $.ajax ({
        type:"get",
        url:"/cgi-bin/node?cmd=get&did=" + _did,
        async:false,
        dataType:"json",
        success:function (json){
            panel_header.innerHTML = json.name;
        }
    });

    //패널 안에 센서 리스트들 테이블로 구성
    var table = document.createElement("table");
    table.setAttribute("class", "table table-bordered");
    table.setAttribute("id", "table_" + _did);

    var thead = document.createElement("thead");
    var thead_tr = document.createElement("tr");
    thead.appendChild(thead_tr);

    //var thNames = ["<span class='glyphicon glyphicon-star' aria-hidden='true'></span>", "epid", "type", "name", "unit", "interval"];
    var thNames = [ _t("name"), _t("type"), _t("value"), _t("state"), _t("graph")];
    var className = ["col-xs-3", "col-xs-3", "col-xs-3", "col-xs-1", "col-xs-2"];

    for (var i=0; i<thNames.length; i++) {
        var th = document.createElement("th");
        th.setAttribute("class", className[i]);
        thead_tr.appendChild(th).innerHTML = thNames[i];
    }

    table.appendChild(thead);

    var tbody = document.createElement("tbody");
    tbody.setAttribute("id", "tbody_" + _did);
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

    //tbody_tr.appendChild(document.createElement("td")).innerHTML = _eps.epid;
    tbody_tr.setAttribute("id", "tr_" + _eps.epid);
    if (_eps.state == "stop") {
        tbody_tr.setAttribute("class", "danger");
    }
    tbody_tr.appendChild(document.createElement("td")).innerHTML = _eps.name;
    tbody_tr.appendChild(document.createElement("td")).innerHTML = _eps.type;
    //tbody_tr.appendChild(document.createElement("td")).innerHTML = _eps.interval;
    tbody_tr.appendChild(document.createElement("td")).innerHTML = " " + _eps.unit;
    //tbody_tr.appendChild(document.createElement("td")).innerHTML = " " + _eps.unit;
    //tbody_tr.appendChild(document.createElement("td")).innerHTML = _eps.unit;
    
    var state_icon = document.createElement("span");
    state_icon.setAttribute("aria-hidden", "true");
    if (_eps.state == "run") {
        state_icon.setAttribute("style", "color:green; font-size:150%");
        state_icon.setAttribute("class", "glyphicon glyphicon-ok-sign");
        //tbody_tr.appendChild(document.createElement("td")).innerHTML = '<span class="glyphicon glyphicon-ok-sign" aria-hidden="true"></span>'//_eps.state;_
    } else {
        state_icon.setAttribute("style", "color:red; font-size:150%");
        state_icon.setAttribute("class", "glyphicon glyphicon-remove-sign");
        //tbody_tr.appendChild(document.createElement("td")).innerHTML = '<span class="glyphicon glyphicon-remove-sign" aria-hidden="true"></span>'//_eps.state;_
    }
    tbody_tr.appendChild(document.createElement("td")).appendChild(state_icon);
    
    /*var btn_list = document.createElement("button");
    btn_list.setAttribute("class", "btn btn-info btn-xs");
    btn_list.setAttribute("type", "button");
    btn_list.setAttribute("id", "btn_" + _eps.epid);
    btn_list.appendChild(document.createTextNode(_t("view")));
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
                    //modal_tr.appendChild(document.createElement("td")).innerHTML = _eps.type;
                    //modal_tr.appendChild(document.createElement("td")).innerHTML = _eps.name;
                    modal_tr.appendChild(document.createElement("td")).innerHTML = timeConverter(values[i].time);
                    modal_tr.appendChild(document.createElement("td")).innerHTML = values[i].value + " " + _eps.unit;
                    modal_tbody.appendChild(modal_tr);
                }
            }
        });

        document.getElementById("modal_title").innerHTML = _eps.name;
        $("#myModal").modal();
    });
    tbody_tr.appendChild(document.createElement("td")).appendChild(btn_list);*/

    // 그래프 버튼
    var btn_graph = document.createElement("button");
    btn_graph.setAttribute("class", "btn btn-info btn-xs");
    btn_graph.setAttribute("type", "button");
    btn_graph.setAttribute("id", "graphbtn_" + _eps.epid);
    btn_graph.appendChild(document.createTextNode(_t("view")));
    btn_graph.addEventListener("click", function() {
        
        // 이전 데이터를 삭제하여 테이블을 비운다.
        $( "#myfirstchart" ).empty();
        $("#modal_table tr:not(:first)").remove();
        var modal_tbody = document.getElementById("modal_tbody");
        datas = [];

        var begin = Math.round(new Date().getTime()/1000);
        var end = begin - 3600;

        console.log(timeConverter(begin), timeConverter(end));

        $.ajax ({
            type:"get",
            url:"/cgi-bin/data?cmd=get&epid=" + _eps.epid + "&begin=" + begin + "&end=" + end,//"&index=0&count=60",
            async:false,
            dataType:"json",
            success:function(json) {
                console.log("json=", json);
                var values = json.data;
                for (var i=1; i<=values.length; i++) {
                    var value = values[values.length - i].value;
                    var json = {time: timeConverter(values[values.length - i].time), value: value};
                    datas.push(json);
                }
            }
        });
        
        //console.log(datas);
        document.getElementById("modalgraph_title").innerHTML = _eps.name;
        $("#myModalGraph").modal();
    });
    tbody_tr.appendChild(document.createElement("th")).appendChild(btn_graph);
}

function asyncEps() {
    $.ajax ({
        type:"get",
        //url:"/cgi-bin/ep?cmd=list&field1=all",
        url:"/cgi-bin/data?cmd=last",
        async:false,
        dataType:"json",
        //success:getAsyncEps
        success:function(json) {
            var result = json.result;
            if (result == "success") {
                var eps = json.datas;
                // console.log(eps);
                $.each(eps, function(key) {
                    if (eps[key].state != "stop") {
                        var epid = eps[key].epid;
                        var time = eps[key].time;
                        var value = eps[key].value;
                        //console.log(epid, value, time);

                        var tr = document.getElementById("tr_" + epid);
                        //var time_td = tr.cells[3];
                        var value_td = tr.cells[2];
                        //console.log(value_td.innerHTML.split(' ')[1]);
                        //time_td.innerHTML = timeConverter(time);
                        value_td.innerHTML = value + " " + value_td.innerHTML.split(' ')[1];
                    }
                });
            } else {
                console.log("load fail");
            }
        }
    });
}

function timeConverter(UNIX_timestamp) {
    var a = new Date(UNIX_timestamp * 1000);
    var months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    var year = a.getFullYear();
    var month = months[a.getMonth()];
    var date = a.getDate();
    var hour = a.getHours();
    var min = a.getMinutes();
    var sec = a.getSeconds();
    var time = year + '/' + a.getMonth() + '/' + date + ' ' + hour + ':' + min + ':' + sec ;
    return time;
}

$('#myModalGraph').on('shown.bs.modal', function () {
    
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
        labels: [_t('value')]
    });
});