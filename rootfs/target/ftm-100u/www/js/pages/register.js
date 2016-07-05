/**
 * Created by kindmong on 2015-10-27.
 */
var sensors = [];
var sensorNodes = [];
var interval;
var intervalCount = 0;

function init() {
    $.li18n.currentLocale = 'kr';
    document.getElementById("menu_register").innerHTML = _t('register');
    document.getElementById("menu_list").innerHTML = _t("list");
    document.getElementById("search_label").innerHTML = _t("mac") + " :";
    document.getElementById("btn_search").innerHTML = _t("search");
    document.getElementById("menu_dashboard").innerHTML = _t('dashboard');
    document.getElementById("menu_sensors").innerHTML = _t('sensors');
    document.getElementById("menu_clouds").innerHTML = _t('clouds');
    document.getElementById("menu_network").innerHTML = _t('network');
    document.getElementById("menu_system").innerHTML = _t('system');
    document.getElementById("btn_register").innerHTML = _t('register');
}

$(document).ready(function(){
    init();

    // 검색 버튼
    $("#btn_search").click(function(){

        for (var i=0; i<sensors.length; i++) {
            var cb = document.getElementById(sensors[i]);
            if (cb != null) {
                cb.checked = false;    
            }
        }
        sensors = [];
        sensorNodes = [];

        var mac = document.getElementById("inputMac").value;
        mac = mac.replace(/ /gi, '');
        if (mac != '') {
            
            if (document.getElementById("row_" + mac)) {
                alert("Already loaded");
            } else {
                //loadData(mac);
                $("#btn_search").button('loading');
                startDiscovery(false);
                //$("#btn_search").attr('disabled',true);
            }

        } else {
            //alert("All Search Mac");

            if (document.getElementById("row_" + mac)) {
                alert("Already loaded");
            } else {
                //loadData(mac);
                $("#btn_search").button('loading');
                startDiscovery(true);
                //$("#btn_search").attr('disabled',true);
            }
        }
    });
});

function startDiscovery(_isAll) {
    $.ajax ({
        type:"get",
        url:"/cgi-bin/discovery?cmd=start&ip=192.168.1.255",
        async:false,
        dataType:"json",
        success:function(json) {
            var result = json.result;
            console.log(result);
            if (result == "success") {
                interval = setInterval( function() { getDiscoveryResult(_isAll); }, 1000);
                //getEpsList(_isAll);
            } else {
                $("#btn_search").button('reset');
                alert("discovery failed");
            }
        }
    });
}

function getDiscoveryResult(_isAll) {
    $.ajax ({
        type:"get",
        url:"/cgi-bin/discovery?cmd=get",
        async:false,
        dataType:"json",
        success:function(json) {
            var result = json.result;
            if (result == "success") {
                var finished = json.finished;
                if (finished == "true") {
                    // 노드 리스트가져오기   
                    console.log("ready");
                    intervalCount = 0;
                    getEpsList(_isAll);
                    clearInterval(interval);
                    $("#btn_search").button('reset');
                } else {
                    console.log("discovery ing..");
                    intervalCount++;
                    console.log(intervalCount);
                    if (intervalCount > 10) {
                        intervalCount = 0;
                        clearInterval(interval);
                        alert("retry search..");
                        $("#btn_search").button('reset');
                    }
                }
            } else {
                alert("discovery failed");
                $("#btn_search").button('reset');
            }
        }
    });
}

function getEpsList(_isAll) {
    $.ajax ({
        type:"get",
        url:"/cgi-bin/ep?cmd=list",
        async:false,
        dataType:"json",
        success:function(json) {
            var result = json.result;
            console.log("getEpsList =", result);
            if (result == "success") {
                var registed_eps = json.eps;
                var eps = [];
                $.each(registed_eps, function(key){
                    var registed_epid = registed_eps[key].epid;
                    console.log("getEpsList epid = ", registed_epid);
                    eps.push(registed_epid);
                });
                getEps(eps, _isAll);
            } else {
                alert("discovery failed");
            }
        }
    });
}

function getEps(_eps, _isAll) {
    var mac = document.getElementById("inputMac").value;
    mac = mac.replace(/ /gi, '');
    console.log("getEps() mac = ", mac);

    $.ajax ({
        type:"get",
        url:"/cgi-bin/discovery?cmd=eps",
        async:false,
        dataType:"json",
        success:function(json) {
            var result = json.result;
            console.log(result);
            if (result == "success") {
                var count = json.count;
                var eps = json.eps;
                console.log("count = ", count);
                for (var i = 0; i<count; i++) {
                    var ep = eps[i].ep;
                    var did = ep.did;
                    var epid = ep.epid;
                    console.log("getEps() did =", did);

                    //console.log("getEps() mac == did", mac.toLowerCase(), did.toLowerCase(), _isAll);
                    console.log("getEps() epid.toLowerCase()", _eps, epid.toLowerCase());
                    if (_isAll == false) {
                        if (mac.toLowerCase() == did.toLowerCase()) {
                            if(_eps.indexOf(epid.toLowerCase()) == -1) {
                                
                                if (ep.type != "MULTI-FUNCTION") {
                                    var tbody = makePanel(did);
                                    makeBody(tbody, ep);
                                }
                            }
                        } else {
                            console.log("맥으로 검색되는 센서가 없습니다.");
                        }
                    } else {
                        console.log(_eps.indexOf(epid.toLowerCase()));
                        if(_eps.indexOf(epid.toLowerCase()) == -1) {
                            
                            if (ep.type != "MULTI-FUNCTION") {
                                var tbody = makePanel(did);
                                makeBody(tbody, ep);
                            }
                        }
                    }
                }
            } else {
                alert("failed");
            }
        }
    });   
}

// 패널별 등록 이거나 전체 패널에서 선택된 센서를 같이 등록 하도록 수정해야함.
$('#btn_register').click(function addSensorList() {
    console.log("센서 등록");
    for (var i=0; i<sensorNodes.length; i++) {
        //var did = this.id.substr(9);
        var did = sensorNodes[i];
        console.log("getIsNode(did)", getIsNode(did), did);
        //return;
        if (!getIsNode(did)) {
            //console.log("!!!!!!!");
            //http://10.0.1.18/cgi-bin/node?cmd=add&type=snmp&version=1&url=10.0.1.148&community=futuretek&mib=fte.mib
            // 센서노드가 등록이 안되어 있으면 최초 한번 등록
            $.ajax ({
                type:"get",
                url:"/cgi-bin/discovery?cmd=nodes",
                async:false,
                dataType:"json",
                success:function(json) {
                    var result = json.result;
                    
                    if (result == "success") {
                        var nodes = json.nodes;
                        $.each(nodes, function(index, node) {
                            if (did.toLowerCase() == node.did.toLowerCase()) {
                                $.ajax ({
                                    type:"get",
                                    url:"/cgi-bin/node?cmd=add&did=" + did + "&type=" + node.type + "&version=" + node.snmp.version + "&url=" + node.snmp.url + "&community=" + node.snmp.community + "&mib=" + node.snmp.mib,
                                    async:false,
                                    dataType:"json",
                                    success:function(json) {
                                        var result = json.result;
                                        console.log("/cgi-bin/node?cmd=add", result);
                                        if (result == "success") {

                                        } else {
                                            console.log("failed");
                                        }
                                    }
                                });
                            }
                        });
                    } else {
                        console.log("failed");
                    }
                }
            });
        }
    }

    // 센서노드 여부 확인 후 센서 등록.
    $.each (sensors, function (index, value){

        var epid = value.substr(3).toLowerCase();
        //==================================================
        var tr = document.getElementById("tr_" + value.substr(3));
        console.log("test = ", tr);
        var tr_parent = tr.parentNode;
        var did = tr_parent.id.substr(6);
        //==================================================
        var type = document.getElementById("tr_" + value.substr(3)).cells[2].innerHTML;
        var name = document.getElementById("name_" + value.substr(3)).value;
        var interval = document.getElementById("interval_" + value.substr(3)).value;
        var unit = document.getElementById("unit_" + value.substr(3)).value;
        console.log(did, type, epid, name, unit, interval);
        
        if (type == "DIGITAL INPUT") { type = "di"; }
        if (type == "DIGITAL OUTPUT") { type = "do"; }

        $.ajax ({
            type:"get",
            url:"/cgi-bin/ep?cmd=add&epid=" + epid + "&type=" + type + "&did=" + did + "&name=" + name + "&unit=" + escape(unit) + "&interval=" + interval,
            async:false,
            dataType:"json",
            success:function(json) {
                var result = json.result;
                console.log(result);
                if (result == "success") {
                    //interval = setInterval("getDiscoveryResult()", 1000);
                    console.log("success added");

                    var state;
                    if (document.getElementById("select_" + value.substr(3)).selectedIndex == 0) {
                        state = true;
                    } else {
                        state = false;
                    }

                    $.ajax ({
                        type:"get",
                        url:"/cgi-bin/ep?cmd=set&epid=" + json.ep.epid + "&enable=" + state,
                        async:false,
                        dataType:"json",
                        success: function (json) {
                            console.log(json.result);
                            if (json.result == "success") {
                                console.log("success");
                                //window.location.reload();
                            } else {
                                alert("failed");
                            }
                        }
                    });

                    removeList(value.substr(3));
                } else {
                    alert("failed");
                }
            }
        });

        console.log(index, epid);
    });

    sensors = [];
});

function getIsNode(_did) {
    var isnode;
    $.ajax ({
        type:"get",
        url:"/cgi-bin/node?cmd=list",
        async:false,
        dataType:"json",
        success:function(json) {
            var result = json.result;
            console.log(result);
            if (result == "success") {
                var savedNodes = json.nodes;
                if (savedNodes.length > 0) {
                    for (var i=0; i<savedNodes.length; i++) {
                        var node = savedNodes[i].did;
                        if (node.toLowerCase() == _did.toLowerCase()) {
                            isnode = true;
                            break;
                        } else {
                            isnode = false;
                        }
                    }
                } else {
                    isnode = false;
                }
            } else {
                
            }
        }
    });

    console.log(isnode);
    return isnode;
}

function onCheckboxClicked() {
    // 체크가 된 센서들을 배열에 넣는다.
    console.log(this.id, this.checked);
    if (this.checked == true) {
        sensors.push(this.id);
    } else {
        if (sensors.indexOf(this.id) != -1) {
            sensors.splice(sensors.indexOf(this.id), 1);
        }
    }
    console.log(sensors);
}

function makePanel(_mac) {

    if (document.getElementById("row_" + _mac)) {
        //console.log("있음");
        return document.getElementById("tbody_" + _mac);
    }

    sensorNodes.push(_mac);
    console.log("sensorNodes = ", sensorNodes);

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

    //패널 푸터
    var panel_footer = document.createElement("div");
    panel_footer.setAttribute("class", "panel-footer");

    //패널 등록 버튼
    // var btn_register = document.createElement("button");
    // btn_register.setAttribute("class", "btn btn-success");
    // btn_register.setAttribute("type", "button");
    // btn_register.setAttribute("id", "register_" + _mac);
    // btn_register.addEventListener("click", addSensorList);
    // btn_register.appendChild(document.createTextNode(_t("register")));

    //패널 닫기 버튼
    var btn_close = document.createElement("button");
    btn_close.setAttribute("class", "btn btn-danger");
    btn_close.setAttribute("type", "button");
    btn_close.setAttribute("id", "close_" + _mac);
    btn_close.addEventListener("click", removePanel);
    btn_close.appendChild(document.createTextNode(_t("close")));

    //패널 안에 센서 리스트들 테이블로 구성
    var table = document.createElement("table");
    table.setAttribute("class", "table table-bordered");

    var thead = document.createElement("thead");
    var thead_tr = document.createElement("tr");
    thead.appendChild(thead_tr);

    //var input = document.createElement("input");
    //input.setAttribute("type", "checkbox");
    //input.value = "";

    var thNames = ["", _t("epid"), _t("type"), _t("name"), _t("unit"), _t("state"), _t("interval")];
    var className = ["col-xs-0", "col-xs-2", "col-xs-2", "col-xs-3", "col-xs-1", "col-xs-2", "col-xs-2"];

    for (var i=0; i<thNames.length; i++) {
        var th = document.createElement("th");
        th.setAttribute("class", className[i]);
        thead_tr.appendChild(th).innerHTML = thNames[i];
    }

    table.appendChild(thead);

    var tbody = document.createElement("tbody");
    tbody.setAttribute("id", "tbody_" + _mac);
    table.appendChild(tbody);

    //panel_footer.appendChild(btn_register);
    panel_footer.appendChild(btn_close);
    row.appendChild(col_lg_12);
    col_lg_12.appendChild(panel);
    panel.appendChild(panel_header);
    panel.appendChild(table);
    panel.appendChild(panel_footer);

    document.getElementById("page-wrapper").appendChild(row);

    return tbody;
}

function makeBody(_tbody, _ep) {
    //console.log("_ep.epid =", _ep.epid);
    if (document.getElementById("tr_" + _ep.epid)) {
        //console.log("있음");
        return;
    }

    if (_ep.type == "MULTI-FUNCTION") { return; }

    var tbody_tr = document.createElement("tr");
    _tbody.appendChild(tbody_tr);

    var input = document.createElement("input");
    input.type = "checkbox";
    input.value = "";
    input.setAttribute("id", "cb_" + _ep.epid);// + "_" + _index);
    input.addEventListener("change", onCheckboxClicked);
    tbody_tr.appendChild(document.createElement("th")).appendChild(input);
    tbody_tr.appendChild(document.createElement("th")).innerHTML = _ep.epid;
    tbody_tr.setAttribute("id", "tr_" + _ep.epid);

	tbody_tr.appendChild(document.createElement("td")).innerHTML = _ep.type;
    //=================== NAME ==============================================
    var td = document.createElement("td");
    var input_tf = document.createElement("input");
    input_tf.setAttribute("id", "name_" + _ep.epid);
    input_tf.setAttribute("type", "text");
    input_tf.setAttribute("class", "form-control");
    input_tf.setAttribute("style", "width: 100%; height: 100%; border:0");
    input_tf.value = _ep.name;
    td.appendChild(input_tf);
    tbody_tr.appendChild(td);
    //========================================================================
    //tbody_tr.appendChild(document.createElement("td")).innerHTML = _ep.name;
    //=================== UNIT ==============================================
    var td = document.createElement("td");
    var input_tf = document.createElement("input");
    input_tf.setAttribute("id", "unit_" + _ep.epid);
    input_tf.setAttribute("type", "text");
    input_tf.setAttribute("class", "form-control");
    input_tf.setAttribute("style", "width: 100%; height: 100%; border:0");
    input_tf.value = _ep.unit;
    td.appendChild(input_tf);
    tbody_tr.appendChild(td);
    //========================================================================
    //tbody_tr.appendChild(document.createElement("td")).innerHTML = _ep.unit;
    //=================== STATE ==============================================
    var td = document.createElement("td");
    var s = document.createElement("select");
    s.setAttribute("id", "select_" + _ep.epid);
    s.setAttribute("style", "border:0; width:100%; height:100%");
    s.appendChild(document.createElement("option")).innerHTML = "RUN";
    s.appendChild(document.createElement("option")).innerHTML = "STOP";
    td.appendChild(s);
    tbody_tr.appendChild(td);
    //========================================================================
    //tbody_tr.appendChild(document.createElement("td")).innerHTML = _ep.state;
    //=================== INTERVAL ==============================================
    var td = document.createElement("td");
    var input_tf = document.createElement("input");
    input_tf.setAttribute("id", "interval_" + _ep.epid);
    input_tf.setAttribute("type", "number");
    input_tf.setAttribute("class", "form-control");
    input_tf.setAttribute("style", "width: 100%; height: 100%; border:0");
    input_tf.value = _ep.interval;
    td.appendChild(input_tf);
    tbody_tr.appendChild(td);
    //========================================================================
    //tbody_tr.appendChild(document.createElement("td")).innerHTML = _ep.interval;

    $('#btn_register').prop('disabled', false);
}

function removeList(_epid) {

    // 리스트에서 삭제
    var tr = document.getElementById("tr_" + _epid);
    console.log("test = ", tr);
    var tr_parent = tr.parentNode;
    tr_parent.removeChild(tr);
    //console.log("tr_parent = ", tr_parent.childNodes, tr_parent.childNodes.length);
    // console.log("tr_parent.id = ", tr_parent.id);
    tr = null;

    // 패널에 목록이 전부 등록이 되면 패널도 삭제.
    if (tr_parent.childNodes.length == 0) {
        var panel_id = tr_parent.id.substr(6);
        // console.log(panel_id);
        var row_id = "row_" + panel_id;
        var row = document.getElementById(row_id);
        var row_parent = row.parentNode;
        row_parent.removeChild(row);
        row = null;
    }

    $('#btn_register').prop('disabled', true);
    for (var i=0; i<sensorNodes.length; i++) {
        var hasRow = document.getElementById("row_" + sensorNodes[i]);
        if (hasRow != null) {
            $('#btn_register').prop('disabled', false);
        }
    }
}

function removePanel() {

    var mac = this.id.substr(6);
    var row_id = "row_" + mac;
    var row = document.getElementById(row_id);

    var row_parent = row.parentNode;
    row_parent.removeChild(row);
    row = null;
   // console.log(mac);

    $('#btn_register').prop('disabled', true);
    for (var i=0; i<sensorNodes.length; i++) {
        var hasRow = document.getElementById("row_" + sensorNodes[i]);
        if (hasRow != null) {
            $('#btn_register').prop('disabled', false);
        }
    }
}
