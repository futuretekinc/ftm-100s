/**
 * Created by kindmong on 2015-10-27.
 */
function init() {
    $.li18n.currentLocale = 'kr';
    document.getElementById("menu_register").innerHTML = _t('register');
    document.getElementById("menu_list").innerHTML = _t("list");
    document.getElementById("menu_dashboard").innerHTML = _t('dashboard');
    document.getElementById("menu_sensors").innerHTML = _t('sensors');
    document.getElementById("menu_clouds").innerHTML = _t('clouds');
    document.getElementById("menu_network").innerHTML = _t('network');
    document.getElementById("menu_system").innerHTML = _t('system');

    document.getElementById("label_type").innerHTML = _t('type');
    document.getElementById("label_location").innerHTML = _t('location');
    document.getElementById("label_interval").innerHTML = _t('interval');
    document.getElementById("label_node_interval").innerHTML = _t('interval');
    document.getElementById("label_timeout").innerHTML = _t('timeout');
    document.getElementById("label_url").innerHTML = _t('url');

    document.getElementById("label_name").innerHTML = _t('name');
    document.getElementById("label_node_name").innerHTML = _t('name');
    document.getElementById("label_state").innerHTML = _t('state');
    document.getElementById("label_unit").innerHTML = _t('unit');

}

$(document).ready(function(){
    init();
    loadData();
});
function loadData () {
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
    panel_header.setAttribute("style", "font-size:120%; font-weight: bold");

    $.ajax ({
        type:"get",
        url:"/cgi-bin/node?cmd=get&did=" + _mac,
        async:false,
        dataType:"json",
        success:function (json) {
            panel_header.innerHTML = json.name + " ";
        }
    });

    // 헤더에 수정 버튼 생성
    var btn_modify = document.createElement("button");
    btn_modify.setAttribute("class", "btn btn-default btn-xs");
    btn_modify.setAttribute("type", "button");
    btn_modify.setAttribute("id", "btn_" + _mac);

    // 버튼의 설정 아이콘 생성.
    var span = document.createElement("span");
    span.setAttribute("class", "glyphicon glyphicon-cog");

    btn_modify.appendChild(span);
    btn_modify.addEventListener("click", function(){

        $.ajax ({
            type:"get",
            url:"/cgi-bin/node?cmd=get&did=" + _mac,
            async:false,
            dataType:"json",
            success:response_node_info
        });
        console.log(this.id);
    });
    panel_header.appendChild(btn_modify);


    //패널 안에 센서 리스트들 테이블로 구성
    var table = document.createElement("table");
    table.setAttribute("class", "table table-bordered");

    var thead = document.createElement("thead");
    var thead_tr = document.createElement("tr");
    thead.appendChild(thead_tr);

    var thNames = [_t("name"), _t("state"), _t("type"), _t("interval"), _t("epid"), _t("modify")];
    var className = ["col-xs-3", "col-xs-1", "col-xs-3", "col-xs-2", "col-xs-2", "col-xs-1"];

    for (var i=0; i<thNames.length; i++) {
        var th = document.createElement("th");
        th.setAttribute("class", className[i]);
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

function response_node_info(json) {
    document.getElementById("modal_node_title").innerHTML = json.did;
    document.getElementById("node_name").value = json.name;
    document.getElementById("node_location").value = json.location;
    document.getElementById("node_interval").value = json.report_interval;
    document.getElementById("node_type").value = json.type;
    document.getElementById("node_timeout").value = json.timeout;
    document.getElementById("node_url").value = json.snmp.url;
    $("#modal_node_config").modal();
}

function makeBody(_tbody, _eps) {

    var tbody_tr = document.createElement("tr");
    tbody_tr.setAttribute("id", "tr_" + _eps.epid);
    _tbody.appendChild(tbody_tr);

    tbody_tr.appendChild(document.createElement("td")).innerHTML = _eps.name;


    var state_icon = document.createElement("span");
    state_icon.setAttribute("aria-hidden", "true");
    if (_eps.state == "run") {
        state_icon.setAttribute("style", "color:green; font-size:150%");
        state_icon.setAttribute("class", "glyphicon glyphicon-ok-sign");
    } else {
        state_icon.setAttribute("style", "color:red; font-size:150%");
        state_icon.setAttribute("class", "glyphicon glyphicon-remove-sign");
    }
    tbody_tr.appendChild(document.createElement("td")).appendChild(state_icon);
    //tbody_tr.appendChild(document.createElement("td")).innerHTML = _eps.state;
    

    tbody_tr.appendChild(document.createElement("td")).innerHTML = _eps.type;
    //tbody_tr.appendChild(document.createElement("td")).innerHTML = _eps.unit;
    tbody_tr.appendChild(document.createElement("td")).innerHTML = _eps.interval;
    tbody_tr.appendChild(document.createElement("td")).innerHTML = _eps.epid;

    var btn_modify = document.createElement("button");
    btn_modify.setAttribute("class", "btn btn-danger btn-xs");
    btn_modify.setAttribute("type", "button");
    btn_modify.setAttribute("id", "btn_" + _eps.epid);
    btn_modify.appendChild(document.createTextNode(_t("modify")));
    btn_modify.addEventListener("click", function(){
        console.log(this.id);
        document.getElementById("modal_sensor_title").innerHTML = _eps.did + " - " + _eps.epid;
        document.getElementById("sensor_name").value = _eps.name;
        if (_eps.state == "stop") {
            document.getElementById("state").options[0].selected = true;
        } else {
            document.getElementById("state").options[1].selected = true;
        }
        document.getElementById("sensor_interval").value = _eps.interval;
        document.getElementById("sensor_unit").value = _eps.unit;
        $("#modal_sensor_config").modal();
    });
    tbody_tr.appendChild(document.createElement("td")).appendChild(btn_modify);
}

$("#modal_btn_sensor_delete").click(function(){
    removeSensor();
    $("#modal_sensor_config").modal("hide");
});

$("#modal_btn_sensor_modify").click(function(){
    modifySensor();
    $("#modal_sensor_config").modal("hide");
});

function modifySensor() {
    
    // 센서의 이름을 수정할 수 있다.
    var epid = document.getElementById("modal_sensor_title").innerHTML.substr(15);
    console.log("epid =", epid);

    var tr = document.getElementById("tr_" + epid);
    console.log(tr);
    var name_td = tr.childNodes.item(0);
    var state_td = tr.childNodes.item(1);
    var interval_td = tr.childNodes.item(3);
    //console.log(name_td);
    name_td.innerHTML = document.getElementById("sensor_name").value;
    state_td.innerHTML = document.getElementById("state").value;
    interval_td.innerHTML = document.getElementById("sensor_interval").value;
	//console.log("name_td.innerHTML =", name_td.innerHTML, document.getElementById("state").selectedIndex);
    
    var state;
    if (document.getElementById("state").value == "stop") {
        state = false;
    } else {
        state = true;
    }

    $.ajax ({
        type:"get",
        url:"/cgi-bin/ep?cmd=set&epid=" + epid + "&name=" + name_td.innerHTML + "&enable=" + state + "&interval=" + interval_td.innerHTML + "&unit=" + escape(document.getElementById("sensor_unit").value),
        async:false,
        dataType:"json",
        success: function (json) {
            console.log(json.result);
            if (json.result == "success") {
                console.log("success");
                window.location.reload();
            } else {
                console.log("failed");
                window.location.reload();
            }
        }
    });
}

function removeSensor() {
    
    // 센서의 삭제할 수 있다.
    var epid = document.getElementById("modal_sensor_title").innerHTML.substr(15);
    console.log("epid =", epid);

    $.ajax ({
        type:"get",
        url:"/cgi-bin/ep?cmd=del&epid=" + epid,
        async:false,
        dataType:"json",
        success: function (json) {
            console.log(json.result);
            if (json.result == "success") {
                console.log("success");
                window.location.reload();
            } else {
                alert("failed");
            }
        }
    });

    // 리스트에서 삭제
    var tr = document.getElementById("tr_" + epid);
    console.log(tr);
    var tr_parent = tr.parentNode;
    tr_parent.removeChild(tr);
    tr = null;
}

function removeSensorNode() {
    // db에서 삭제
}

$("#modal_btn_node_delete").click(function(){
    removeNode();
    $("#modal_node_config").modal("hide");
});

$("#modal_btn_node_modify").click(function(){
    modifyNode();
    $("#modal_node_config").modal("hide");
});

function removeNode() {
    var did = document.getElementById("modal_node_title").innerHTML;
    var location = document.getElementById("node_location").value;
    var interval = document.getElementById("node_interval").value;
    console.log(did);

    $.ajax ({
        type:"get",
        url:"/cgi-bin/node?cmd=del&did=" + did,
        async:false,
        dataType:"json",
        success: function (json) {
            console.log(json.result);
            if (json.result == "success") {
                window.location.reload();
            } else {
                alert("failed");
            }
        }
    });
}

function modifyNode() {
    var did = document.getElementById("modal_node_title").innerHTML;
    var location = document.getElementById("node_location").value;
    var interval = document.getElementById("node_interval").value;
    var name = document.getElementById("node_name").value;
    console.log(did);

    $.ajax ({
        type:"get",
        url:"/cgi-bin/node?cmd=set&did=" + did + "&location=" + location + "&interval=" + interval + "&name=" + name,
        async:false,
        dataType:"json",
        success: function (json) {
            console.log(json.result);
            if (json.result == "success") {
                window.location.reload();
            } else {
                alert("failed");
            }
        }
    });
}