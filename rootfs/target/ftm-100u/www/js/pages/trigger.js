/**
 * Created by kindmong on 2015-10-27.
 */

 var makeTriggers = [];

function init() {
    $.li18n.currentLocale = 'kr';
    document.getElementById("menu_dashboard").innerHTML = _t('dashboard');
    document.getElementById("menu_sensors").innerHTML = _t('sensors');
    document.getElementById("menu_clouds").innerHTML = _t('clouds');
    document.getElementById("menu_network").innerHTML = _t('network');
    document.getElementById("menu_system").innerHTML = _t('system');
    document.getElementById("menu_sensornodes").innerHTML = _t('sensornodes');
    document.getElementById("menu_rule").innerHTML = _t('rule');
    document.getElementById("modal_btn_trigger_add").innerHTML = _t('trigger_add');
    document.getElementById("modal_btn_action_add").innerHTML = _t('action_add');
    document.getElementById("modal_trigger_add_title").innerHTML = _t('trigger_title');
    document.getElementById("btn_trigger_add").innerHTML = _t('trigger_title');

    document.getElementById("add_label_name").innerHTML = _t('name');
    document.getElementById("add_label_epid").innerHTML = _t('sensors');
    document.getElementById("add_label_type").innerHTML = _t('trigger_type');
    document.getElementById("add_label_value").innerHTML = _t('value');

    document.getElementById("add_action_label_name").innerHTML = _t('name');
    document.getElementById("add_action_label_epid").innerHTML = _t('epid');
    document.getElementById("add_action_label_type").innerHTML = _t('action_type');
    document.getElementById("add_action_label_value").innerHTML = _t('value');

    document.getElementById("modal_action_add_title").innerHTML = _t('action');

    document.getElementById("trigger_label_name").innerHTML = _t('name');
    document.getElementById("trigger_label_value").innerHTML = _t('value');
    document.getElementById("trigger_label_lower").innerHTML = _t('lower');
    document.getElementById("trigger_label_upper").innerHTML = _t('upper');
    document.getElementById("modify_action_label_name").innerHTML = _t('name');
    document.getElementById("modify_action_label_value").innerHTML = _t('value');

    document.getElementById("add_type").options[0].innerHTML = _t('above');
    document.getElementById("add_type").options[1].innerHTML = _t('below');
    document.getElementById("add_type").options[2].innerHTML = _t('include');
    document.getElementById("add_type").options[3].innerHTML = _t('except');
    document.getElementById("add_type").options[4].innerHTML = _t('change');

    document.getElementById("add_label_upper").innerHTML = _t('upper');
    document.getElementById("add_label_lower").innerHTML = _t('lower');

    document.getElementById("add_action_type").options[0].innerHTML = _t('set');
    document.getElementById("add_action_type").options[1].innerHTML = _t('sms');
    document.getElementById("add_action_type").options[2].innerHTML = _t('push');
    document.getElementById("add_action_type").options[3].innerHTML = _t('mail');

    document.getElementById("rule_label_id").innerHTML = _t('rule_id');
    document.getElementById("rule_label_name").innerHTML = _t('rule_name');
}

$(document).ready(function(){
    init();
    //loadTriggerList();
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
    var tbody = makePanel(_t("rules"));
    $.each(rules, function(key){
        console.log("id :", rules[key].id, "name :", rules[key].name, "state :", rules[key].state, "trigger :", rules[key].params.triggers[0], "action :", rules[key].params.actions[0]);
        // var tbody = makePanel(rules[key].id);
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

    var thNames = [_t("name"), _t("trigger"), _t("action"), _t("state"), _t("modify")];
    var className = ["col-xs-2", "col-xs-5", "col-xs-3", "col-xs-1", "col-xs-1"];

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

function makeBody(_tbody, _rules) {

    var tbody_tr = document.createElement("tr");
    _tbody.appendChild(tbody_tr);

    //tbody_tr.appendChild(document.createElement("td")).innerHTML = _rules.id;
    tbody_tr.setAttribute("id", "tr_" + _rules.id);
    tbody_tr.appendChild(document.createElement("td")).innerHTML = _rules.name;
    var td = document.createElement("td");
    tbody_tr.appendChild(td);
    // ====================== 트리거 수정 버튼 ==============================================
    for (var i=0; i<_rules.params.triggers.length; i++) {
        // if (i > 0) {
        //     td.innerHTML += ", " + _rules.params.triggers[i];
        // } else {
        //     td.innerHTML += _rules.params.triggers[i];
        // }
        var btn_modify_trigger = document.createElement("button");
        btn_modify_trigger.setAttribute("class", "btn btn-info btn-xs");
        btn_modify_trigger.setAttribute("style", "margin-right:5px");
        btn_modify_trigger.setAttribute("type", "button");
        btn_modify_trigger.setAttribute("id", "btn_trigger_" + _rules.params.triggers[i]);
        //btn_modify_trigger.appendChild(document.createTextNode(_rules.params.triggers[i]));
        
        // 트리거 did를 가지고 이름을 가져와서 버튼 이름으로 넣는다.
        $.ajax ({
            type:"get",
            url:"/cgi-bin/trigger?cmd=get&id=" + _rules.params.triggers[i],
            async:false,
            dataType:"json",
            success:function(json){
                var trigger = json.trigger;
                btn_modify_trigger.appendChild(document.createTextNode(trigger.name));
            }
        });

        
        btn_modify_trigger.addEventListener("click", function(){
            console.log(this.id);
            var id = this.id.substr(12);
            $.ajax ({
                type:"get",
                url:"/cgi-bin/trigger?cmd=get&id=" + id,
                async:false,
                dataType:"json",
                success:function(json){
                    var trigger = json.trigger;
                    console.log(trigger);
                    document.getElementById("modal_trigger_title").innerHTML = trigger.id;
                    document.getElementById("trigger_name").value = trigger.name;
                    // document.getElementById("trigger_detect").value = trigger.contidion.detectTime;
                    // document.getElementById("trigger_hold").value = trigger.contidion.holdTime;
                    document.getElementById("trigger_value").value = trigger.contidion.value;
                    //document.getElementById("trigger_lower").value = trigger.name;
                    //document.getElementById("trigger_upper").value = trigger.name;
                }
            });

            $("#modal_trigger_config").modal();
        });
        td.appendChild(btn_modify_trigger);
    }
    // ======================== 액션 수정 버튼 =============================================
    // tbody_tr.appendChild(document.createElement("td")).innerHTML = _rules.params.actions[0];
    var btn_modify_action = document.createElement("button");
    btn_modify_action.setAttribute("class", "btn btn-info btn-xs");
    btn_modify_action.setAttribute("style", "margin-right:5px");
    btn_modify_action.setAttribute("type", "button");
    btn_modify_action.setAttribute("id", "btn_action_" + _rules.params.actions[0]);
    //btn_modify_action.appendChild(document.createTextNode(_rules.params.actions[0]));

    // 액션 did를 가지고 이름을 가져와서 버튼 이름으로 넣는다.
    $.ajax ({
        type:"get",
        url:"/cgi-bin/action?cmd=get&id=" + _rules.params.actions[0],
        async:false,
        dataType:"json",
        success:function(json){
            var action = json.action;
            btn_modify_action.appendChild(document.createTextNode(action.name));
        }
    });

    btn_modify_action.addEventListener("click", function(){
        console.log(this.id);
        var id = this.id.substr(11);
        $.ajax ({
            type:"get",
            url:"/cgi-bin/action?cmd=get&id=" + id,
            async:false,
            dataType:"json",
            success:function(json){
                var action = json.action;
                console.log(action);
                document.getElementById("modal_action_title").innerHTML = action.id;
                document.getElementById("modify_action_name").value = action.name;
                document.getElementById("modify_action_value").value = action.action.value;
            }
        });

        $("#modal_action_config").modal();
    });
    tbody_tr.appendChild(document.createElement("td")).appendChild(btn_modify_action);
    // =====================================================================================

    //tbody_tr.appendChild(document.createElement("td")).innerHTML = _t(_rules.state);
    var state_icon = document.createElement("span");
    state_icon.setAttribute("aria-hidden", "true");
    if (_rules.state == "ACTIVATE") {
        state_icon.setAttribute("style", "color:green; font-size:150%");
        state_icon.setAttribute("class", "glyphicon glyphicon-ok-sign");
    } else {
        state_icon.setAttribute("style", "color:red; font-size:150%");
        state_icon.setAttribute("class", "glyphicon glyphicon-remove-sign");
    }
    tbody_tr.appendChild(document.createElement("td")).appendChild(state_icon);

    var btn_modify = document.createElement("button");
    btn_modify.setAttribute("class", "btn btn-danger btn-xs");
    btn_modify.setAttribute("type", "button");
    btn_modify.setAttribute("id", "btn_" + _rules.id);
    btn_modify.appendChild(document.createTextNode(_t("modify")));
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
                document.getElementById("modal_rule_title").innerHTML = rule.name;
                document.getElementById("rule_name").value = rule.name;
                document.getElementById("rule_id").value = rule.id;
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
    var id = document.getElementById("rule_id").value;
    console.log("id =", id);

    var tr = document.getElementById("tr_" + id);
    //console.log(tr);
    var name_td = tr.childNodes.item(0);

    name_td.innerHTML = document.getElementById("rule_name").value;
    console.log("name_td.innerHTML =", name_td.innerHTML);

    var url = "/cgi-bin/rule?cmd=set&id=" + id + "&name=" + name_td.innerHTML;
    return;
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

$('#add_rule_type').on('change', function () {
    
    var value_tf = document.getElementById("add_rule_value");
    var epid_select = document.getElementById("add_rule_epid");

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

/*function loadTriggerList () {
    $.ajax ({
        type:"get",
        url:"/cgi-bin/trigger?cmd=list&field1=all",
        async:false,
        dataType:"json",
        success:response_trigger_list
    });
}

function response_trigger_list(json) {
    console.log(json);
    var triggers = json.triggers;

    $.each(triggers, function(key){
        console.log("id :", triggers[key].id, "type :", triggers[key].type, "name :", triggers[key].name, "epid :", triggers[key].epid, "contidion_detectTime :", triggers[key].contidion.detectTime, "contidion_holdTime :", triggers[key].contidion.holdTime, "contidion_value :", triggers[key].contidion.value);
        //var tbody = makePanel(triggers[key].id);
        //var tbody = document.getElementById("trigger_list");
        //makeBody(tbody, triggers[key]);
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

    // btn_modify.appendChild(span);
    // btn_modify.addEventListener("click", function(){

    //     $.ajax ({
    //         type:"get",
    //         url:"/cgi-bin/node?cmd=get&did=" + _mac,
    //         async:false,
    //         dataType:"json",
    //         success:response_node_info
    //     });
    //     console.log(this.id);
    // });
    // panel_header.appendChild(btn_modify);


    //패널 안에 센서 리스트들 테이블로 구성
    var table = document.createElement("table");
    table.setAttribute("class", "table table-bordered");

    var thead = document.createElement("thead");
    var thead_tr = document.createElement("tr");
    thead.appendChild(thead_tr);

    var thNames = ["name", "id", "type", "epid", "value", "modify"];
    //var className = ["col-sm-1", "col-sm-2", "col-sm-2", "col-sm-2", "col-sm-1", "col-sm-1"];

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

/*function response_node_info(json) {
    document.getElementById("modal_node_title").innerHTML = json.did;
    document.getElementById("node_location").value = json.location;
    document.getElementById("node_interval").value = json.interval;
    document.getElementById("node_type").value = json.type;
    document.getElementById("node_timeout").value = json.timeout;
    document.getElementById("node_url").value = json.snmp.url;
    $("#modal_node_config").modal();
}

function makeBody(_tbody, _triggers) {

    var tbody_tr = document.createElement("tr");
    _tbody.appendChild(tbody_tr);

    tbody_tr.appendChild(document.createElement("td")).innerHTML = _triggers.name;
    tbody_tr.appendChild(document.createElement("td")).innerHTML = _triggers.id;
    tbody_tr.setAttribute("id", "tr_" + _triggers.id);

    tbody_tr.appendChild(document.createElement("td")).innerHTML = _triggers.type;
    
    tbody_tr.appendChild(document.createElement("td")).innerHTML = _triggers.epid;
    //tbody_tr.appendChild(document.createElement("td")).innerHTML = _triggers.contidion.detectTime;
    //tbody_tr.appendChild(document.createElement("td")).innerHTML = _triggers.contidion.holdTime;
    tbody_tr.appendChild(document.createElement("td")).innerHTML = _triggers.contidion.value;

    var btn_modify = document.createElement("button");
    btn_modify.setAttribute("class", "btn btn-danger btn-xs");
    btn_modify.setAttribute("type", "button");
    btn_modify.setAttribute("data-dismiss", "modal");
    btn_modify.setAttribute("id", "btn_" + _triggers.id);
    btn_modify.appendChild(document.createTextNode("Modify"));
    btn_modify.addEventListener("click", function(){
        console.log(this.id);
        var id = this.id.substr(4);
        $.ajax ({
            type:"get",
            url:"/cgi-bin/trigger?cmd=get&id=" + id,
            async:false,
            dataType:"json",
            success:function(json){
                var trigger = json.trigger;
                console.log(trigger);
                document.getElementById("modal_trigger_title").innerHTML = trigger.id;
                document.getElementById("trigger_name").value = trigger.name;
                // document.getElementById("trigger_detect").value = trigger.contidion.detectTime;
                // document.getElementById("trigger_hold").value = trigger.contidion.holdTime;
                document.getElementById("trigger_value").value = trigger.contidion.value;
                //document.getElementById("trigger_lower").value = trigger.name;
                //document.getElementById("trigger_upper").value = trigger.name;
            }
        });

        $("#modal_trigger_config").modal();
    });
    tbody_tr.appendChild(document.createElement("th")).appendChild(btn_modify);
}

$("#modal_btn_trigger_delete").click(function(){
    removeTrigger();
    $("#modal_trigger_config").modal("hide");
});
*/
$("#modal_btn_trigger_modify").click(function(){
    modifyTrigger();
    $("#modal_trigger_config").modal("hide");
});

function modifyTrigger() {
    
    // 센서의 이름을 수정할 수 있다.

    var id = document.getElementById("modal_trigger_title").innerHTML;
    console.log("id =", id);

    var name = document.getElementById("trigger_name").value;
    console.log("trigger name =", name);

    //var detect = document.getElementById("trigger_detect").value;
    //console.log("trigger detect =", detect);

    //var hold = document.getElementById("trigger_hold").value;
    //console.log("trigger hold =", hold);

    var value = document.getElementById("trigger_value").value;
    console.log("trigger value =", value);

    var lower = document.getElementById("trigger_lower").value;
    console.log("trigger lower =", lower);

    var upper = document.getElementById("trigger_upper").value;
    console.log("trigger upper =", upper);

    $.ajax ({
        type:"get",
        url:"/cgi-bin/trigger?cmd=set&id=" + id + "&name=" + name + "&value=" + value + "&upper=" + upper + "&lower=" + lower, //+ "&detect=" + detect + "&hold=" + hold,
        async:false,
        dataType:"json",
        success: function (json) {
            console.log(json.result);
            if (json.result == "success") {
                console.log("success");
            } else {
                alert("failed");
            }
        }
    });
}

$("#modal_btn_action_modify").click(function(){
    modifyAction();
    $("#modal_action_config").modal("hide");
});

function modifyAction() {
    
    // 센서의 이름을 수정할 수 있다.
    var id = document.getElementById("modal_action_title").innerHTML;
    console.log("id =", id);

    name = document.getElementById("modify_action_name").value;
    console.log("modify_action_name =", name);

    value = document.getElementById("modify_action_value").value;
    console.log("modify_action_value =", value);

    var url = "/cgi-bin/action?cmd=set&id=" + id + "&name=" + name + "&value=" + value;

    // if (type_td.innerHTML == "SET") {
    //     url += "&value=" + value_td.innerHTML;
    // }

    $.ajax ({
        type:"get",
        url:url,
        async:false,
        dataType:"json",
        success: function (json) {
            console.log(json.result);
            if (json.result == "success") {
                console.log("modifyAction success");
            } else {
                alert("failed");
            }
        }
    });
}

function removeTrigger(id) {
    
    // 센서의 삭제할 수 있다.
    //var id = document.getElementById("modal_trigger_title").innerHTML;
    console.log("id =", id);

    $.ajax ({
        type:"get",
        url:"/cgi-bin/trigger?cmd=del&id=" + id,
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

    // 리스트에서 삭제
    // var tr = document.getElementById("tr_" + id);
    // console.log(tr);
    // var tr_parent = tr.parentNode;
    // tr_parent.removeChild(tr);
    // tr = null;

    // 리스트 체크하여 패널을 삭제해야함.
}

$("#btn_trigger_add").click(function(){
    $('#modal_btn_action_add').prop('disabled', true);
    clearTrigger();
    $("#modal_trigger_add").modal();
});

$('#add_type').on('change', function () {
    
    //console.log(this.value); 
    var lower_tf = document.getElementById("add_lower");
    var upper_tf = document.getElementById("add_upper");

    if (this.value == "include" || this.value == "except") {
        lower_tf.disabled = upper_tf.disabled = true;
        lower_tf.value = upper_tf.value = "";
    } else {
        lower_tf.disabled = upper_tf.disabled = false;
    }
});

$('#modal_btn_trigger_add').click(function(){
    addTrigger();
});

$('#modal_trigger_add').on('hidden.bs.modal', function () {
    // do something…
    var triggerGroup = document.getElementById("trigger_group");
    console.log("close modal" ,makeTriggers);
    for (var i=0; i< makeTriggers.length; i++) {
        removeTrigger(makeTriggers[i]);
        document.getElementById("li_" + makeTriggers[i]).remove();
        makeTriggers.splice(makeTriggers.indexOf(makeTriggers[i]), 1);
        console.log("close modal", i);
    }
});

function addTrigger() {
    var type = document.getElementById("add_type").value;
    var epid = document.getElementById("add_epid").value;
    var name = document.getElementById("add_name").value;
    var value = document.getElementById("add_value").value;
    var upper = document.getElementById("add_upper").value;
    var lower = document.getElementById("add_lower").value;
    // var detect = document.getElementById("add_detect").value;
    // var hold = document.getElementById("add_hold").value;

    var url = "/cgi-bin/trigger?cmd=add&type=" + type + "&epid=" + epid + "&value=" + value;

    if (type == _t("include") || type == _t("except")) {
        url += "&upper=" + upper + "&lower=" + lower
    }

    console.log(type, epid, value, name, upper, lower);
    
    if (name != "") { url += "&name=" + name };
    // if (detect != "") { url += "&detect=" + detect };
    // if (hold != "") { url += "&hold=" + hold };

    console.log(url);

    var triggerGroup = document.getElementById("trigger_group");
    $.ajax ({
        type:"get",
        url:url,
        async:false,
        dataType:"json",
        success: function (json) {
            
            if (json.result == "success") {
                console.log("addTrigger success");
                //=============================================================
                var li = document.createElement("li");
                li.setAttribute("class", "list-group-item list-group-item-success");
                li.setAttribute("id", "li_" + json.id);
                li.innerHTML = name;
                var btn = document.createElement("button");
                btn.setAttribute("class", "close")
                btn.setAttribute("id", json.id);
                btn.addEventListener("click", function(){
                    console.log(this.id);
                    makeTriggers.splice(makeTriggers.indexOf(this.id), 1);
                    removeTrigger(this.id);
                    document.getElementById("li_" + this.id).remove();

                    if (makeTriggers.length > 0) {
                        $('#modal_btn_action_add').prop('disabled', false);
                    } else {
                        $('#modal_btn_action_add').prop('disabled', true);
                    }
                });
                var btn_span = document.createElement("span");
                btn_span.setAttribute("aria-hidden", "true");
                btn_span.innerHTML = "&times;";
                btn.appendChild(btn_span);
                li.appendChild(btn);
                triggerGroup.appendChild(li);
                //=============================================================
                makeTriggers.push(json.id);
                clearTrigger();
            } else {
                alert("fail");
            }
        }
    });
    console.log(makeTriggers);
    if (makeTriggers.length > 0) {
        $('#modal_btn_action_add').prop('disabled', false);
    } else {
        $('#modal_btn_action_add').prop('disabled', true);
    }
    //$("#modal_trigger_add").modal("hide");
}

function clearTrigger() {
    // 모달에 쓰인 자료를 초기화 해준다.
    var eps_select = document.getElementById("add_epid");
    eps_select.options.length = 0;

    document.getElementById("add_type").value = "";
    document.getElementById("add_epid").value = "";
    document.getElementById("add_name").value = "";
    document.getElementById("add_value").value = "";
    document.getElementById("add_upper").value = "";
    document.getElementById("add_lower").value = "";
    // document.getElementById("add_detect").value = "";
    // document.getElementById("add_hold").value = "";

    // 현재 관리중인 epid 를 불러와서 select에 넣어준다.
    $.ajax ({
        type:"get",
        url:"/cgi-bin/ep?cmd=list&field1=name",
        async:false,
        dataType:"json",
        success: function (json) {
            // console.log(json.eps);
            var eps = json.eps;
            var eps_select = document.getElementById("add_epid");
            if (json.result == "success") {
                $.each(eps, function(key){
                    var ep = eps[key].epid;
                    var name = eps[key].name;
                    console.log(name, ep);
                    var option = document.createElement("option");
                    eps_select.appendChild(option);
                    option.innerHTML = name;
                    option.setAttribute("value", ep);
                });
            } else {
                alert("load fail");
            }
        }
    });
}

$('#modal_btn_action_add').click(function(){
    // 모달에 쓰인 자료를 초기화 해준다.
    var eps_select = document.getElementById("add_epid");
    eps_select.options.length = 0;

    document.getElementById("add_action_type").value = "";
    document.getElementById("add_action_epid").value = "";
    document.getElementById("add_action_name").value = "";
    document.getElementById("add_action_value").value = "";
    
    // 현재 관리중인 epid 를 불러와서 select에 넣어준다.
    $.ajax ({
        type:"get",
        url:"/cgi-bin/ep?cmd=list&field1=name",
        async:false,
        dataType:"json",
        success: function (json) {
            // console.log(json.eps);
            var eps = json.eps;
            var eps_select = document.getElementById("add_action_epid");
            if (json.result == "success") {
                $.each(eps, function(key){
                    var ep = eps[key].epid;
                    var name = eps[key].name;
                    //console.log(ep);
                    var option = document.createElement("option");
                    eps_select.appendChild(option);
                    option.innerHTML = name;
                    option.setAttribute("value", ep);
                });
            } else {
                alert("load fail");
            }
        }
    });

    $("#modal_action_add").modal();
});

$('#add_action_type').on('change', function () {
    
    var value_tf = document.getElementById("add_action_value");
    var epid_select = document.getElementById("add_action_epid");
    console.log(this.value, _t("set"));
    if (this.value != "set") {
        value_tf.disabled = epid_select.disabled = true;
        value_tf.value = epid_select.value = "";
    } else {
        value_tf.disabled = epid_select.disabled = false;
    }
});

$('#modal_btn_make_action').click(function(){

    var type = document.getElementById("add_action_type").value;
    var epid = document.getElementById("add_action_epid").value;
    var name = document.getElementById("add_action_name").value;
    var value = document.getElementById("add_action_value").value;

    console.log(type, epid, value, name);

    var url = "/cgi-bin/action?cmd=add&type=" + type + "&name=" + name;
    if (type == "set") {
        url += "&epid=" + epid + "&value=" + value;
    }
    console.log(url);
    
    $.ajax ({
        type:"get",
        url:url,
        async:false,
        dataType:"json",
        success: function (json) {
            
            if (json.result == "success") {
                console.log("success");
                console.log("modal_btn_make_action = ", makeTriggers);
                makeRule(json.action.id);
            } else {
                alert("fail");
            }
        }
    });
    $("#modal_action_add").modal("hide");
});

function makeRule(action_id) {
    var url = "/cgi-bin/rule?cmd=add"; //&trigger1=" + trigger + "&action1=" + action_id;
    for (var i=0; i<makeTriggers.length; i++) {
        var triggerCount = i + 1 + "=";
        url += "&trigger" + triggerCount + makeTriggers[i] + "&action" + triggerCount + action_id;
    }

    console.log(url);

    $.ajax ({
        type:"get",
        url:url,
        async:false,
        dataType:"json",
        success: function (json) {
            
            if (json.result == "success") {
                console.log("makeRule success");
                //window.location.reload();
                for (var i=0; i<makeTriggers.length; i++) {
                    document.getElementById("li_" + makeTriggers[i]).remove();
                }
                makeTriggers = [];
                window.location.reload();
            } else {
                alert("fail");
            }
        }
    });
}