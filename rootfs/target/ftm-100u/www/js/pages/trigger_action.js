/**
 * Created by kindmong on 2015-10-27.
 */
$(document).ready(function(){
    loadRuleList();
});
function loadRuleList () {
    $.ajax ({
        type:"get",
        url:"/cgi-bin/rule?cmd=list&field1=all",
        async:false,
        dataType:"json",
        success:response_list
    });
}

function response_list(json) {
    console.log(json);
    var rules = json.rules;
    console.log(rules);
    $.each(rules, function(key){
        console.log("id :", rules[key].id, "name :", rules[key].name, "state :", rules[key].state, "trigger :", rules[key].params.triggers[0], "action :", rules[key].params.actions[0]);
        var tbody = makePanel(rules[key].id);
        makeBody(tbody, rules[key]);
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
    panel_header.innerHTML = _mac +  " ";

    // 헤더에 수정 버튼 생성
    var btn_modify = document.createElement("button");
    btn_modify.setAttribute("class", "btn btn-default btn-xs");
    btn_modify.setAttribute("type", "button");
    btn_modify.setAttribute("id", "btn_" + _mac);

    // 버튼의 설정 아이콘 생성.
    var span = document.createElement("span");
    span.setAttribute("class", "glyphicon glyphicon-cog");

    /*btn_modify.appendChild(span);
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
    panel_header.appendChild(btn_modify);*/


    //패널 안에 센서 리스트들 테이블로 구성
    var table = document.createElement("table");
    table.setAttribute("class", "table table-bordered");

    var thead = document.createElement("thead");
    var thead_tr = document.createElement("tr");
    thead.appendChild(thead_tr);

    var thNames = ["name", "trigger", "action", "state", "modify"];

    for (var i=0; i<thNames.length; i++) {
        var th = document.createElement("th");
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

function makeBody(_tbody, _rules) {

    var tbody_tr = document.createElement("tr");
    _tbody.appendChild(tbody_tr);

    //tbody_tr.appendChild(document.createElement("td")).innerHTML = _rules.id;
    tbody_tr.setAttribute("id", "tr_" + _rules.id);
    tbody_tr.appendChild(document.createElement("td")).innerHTML = _rules.name;
    tbody_tr.appendChild(document.createElement("td")).innerHTML = _rules.params.triggers[0];
    tbody_tr.appendChild(document.createElement("td")).innerHTML = _rules.params.actions[0];
    tbody_tr.appendChild(document.createElement("td")).innerHTML = _rules.state;

    var btn_modify = document.createElement("button");
    btn_modify.setAttribute("class", "btn btn-danger btn-xs");
    btn_modify.setAttribute("type", "button");
    btn_modify.setAttribute("id", "btn_" + _rules.id);
    btn_modify.appendChild(document.createTextNode("Modify"));
    btn_modify.addEventListener("click", function(){
        console.log(this.id);
        var id = this.id.substr(4);
        $.ajax ({
            type:"get",
            url:"/cgi-bin/rule?cmd=get&id=" + id,
            async:false,
            dataType:"json",
            success:function(json){
                var rule = json.rule;
                console.log(rule);
                document.getElementById("modal_rule_title").innerHTML = rule.id;
                document.getElementById("rule_name").value = rule.name;
            }
        });

        $("#modal_rule_config").modal();
    });
    tbody_tr.appendChild(document.createElement("th")).appendChild(btn_modify);
}

$("#modal_btn_rule_delete").click(function(){
    removeRule();
    $("#modal_rule_config").modal("hide");
});

$("#modal_btn_rule_modify").click(function(){
    modifyRule();
    $("#modal_rule_config").modal("hide");
});

function modifyRule() {
    
    // 센서의 이름을 수정할 수 있다.
    var id = document.getElementById("modal_rule_title").innerHTML;
    console.log("id =", id);

    var tr = document.getElementById("tr_" + id);
    //console.log(tr);
    var name_td = tr.childNodes.item(0);

    name_td.innerHTML = document.getElementById("rule_name").value;
    console.log("name_td.innerHTML =", name_td.innerHTML);

    var url = "/cgi-bin/rule?cmd=set&id=" + id + "&name=" + name_td.innerHTML;

    // value 값은 액션의 타입이 SET인 경우에만 적용됨.

    // if (type_td.innerHTML == "SET") {
    //    url += "&value=" + document.getElementById("rule_value").value;
    // }

    $.ajax ({
        type:"get",
        url:url,
        async:false,
        dataType:"json",
        success: function (json) {
            console.log(json.result);
            if (json.result == "success") {
                alert("success");
            } else {
                alert("failed");
            }
        }
    });
}

function removeRule() {
    
    // 센서의 삭제할 수 있다.
    var id = document.getElementById("modal_rule_title").innerHTML;
    console.log("id =", id);

    $.ajax ({
        type:"get",
        url:"/cgi-bin/rule?cmd=del&id=" + id,
        async:false,
        dataType:"json",
        success: function (json) {
            console.log(json.result);
            if (json.result == "success") {
                alert("success");
                window.location.reload();
            } else {
                alert("failed");
            }
        }
    });

    // 리스트에서 삭제
    var tr = document.getElementById("tr_" + id);
    console.log(tr);
    var tr_parent = tr.parentNode;
    tr_parent.removeChild(tr);
    tr = null;

    // 리스트 체크하여 패널을 삭제해야함.
}

$("#btn_rule_add").click(function(){
    
    // 모달에 쓰인 자료를 초기화 해준다.
    var triggers_select = document.getElementById("add_trigger");
    var actions_select = document.getElementById("add_action");
    triggers_select.options.length = actions_select.options.length = 0;

    document.getElementById("add_trigger").value = "";
    document.getElementById("add_action").value = "";
    
    // 현재 관리중인 trigger 를 불러와서 select에 넣어준다.
    $.ajax ({
        type:"get",
        url:"/cgi-bin/trigger?cmd=list",
        async:false,
        dataType:"json",
        success: function (json) {
            // console.log(json.eps);
            var triggers = json.triggers;
            var triggers_select = document.getElementById("add_trigger");
            if (json.result == "success") {
                $.each(triggers, function(key){
                    var trigger = triggers[key].id;
                    console.log(trigger);
                    var option = document.createElement("option");
                    triggers_select.appendChild(option);
                    option.innerHTML = trigger;
                });
            } else {
                alert("load fail");
            }
        }
    });

    // 현재 관리중인 action 를 불러와서 select에 넣어준다.
    $.ajax ({
        type:"get",
        url:"/cgi-bin/action?cmd=list",
        async:false,
        dataType:"json",
        success: function (json) {
            // console.log(json.eps);
            var actions = json.actions;
            var actions_select = document.getElementById("add_action");
            if (json.result == "success") {
                $.each(actions, function(key){
                    var action = actions[key].id;
                    console.log(action);
                    var option = document.createElement("option");
                    actions_select.appendChild(option);
                    option.innerHTML = action;
                });
            } else {
                alert("load fail");
            }
        }
    });

    $("#modal_rule_add").modal();
});

$('#add_type').on('change', function () {
    
    var value_tf = document.getElementById("add_value");
    var epid_select = document.getElementById("add_epid");

    if (this.value != "set") {
        value_tf.disabled = epid_select.disabled = true;
        value_tf.value = epid_select.value = "";
    } else {
        value_tf.disabled = epid_select.disabled = false;
    }
});

$('#modal_btn_rule_add').click(function(){

    var trigger = document.getElementById("add_trigger").value;
    var action = document.getElementById("add_action").value;

    console.log(trigger, action);

    var url = "/cgi-bin/rule?cmd=add&trigger1=" + trigger + "&action1=" + action;
    console.log(url);
    
    $.ajax ({
        type:"get",
        url:url,
        async:false,
        dataType:"json",
        success: function (json) {
            
            if (json.result == "success") {
                alert("success");
                window.location.reload();
            } else {
                alert("fail");
            }
        }
    });
    $("#modal_rule_add").modal("hide");
});