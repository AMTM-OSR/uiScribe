<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="X-UA-Compatible" content="IE=Edge">
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<meta http-equiv="Pragma" content="no-cache">
<meta http-equiv="Expires" content="-1">
<link rel="shortcut icon" href="images/favicon.png">
<link rel="icon" href="images/favicon.png">
<title>System Log - enhanced by Scribe</title>
<link rel="stylesheet" type="text/css" href="index_style.css">
<link rel="stylesheet" type="text/css" href="form_style.css">
<style>
p{font-weight:bolder}thead.collapsible-jquery{color:#fff;padding:0;width:100%;border:none;text-align:left;outline:none;cursor:pointer}thead.collapsible-jquery-config{color:#fff;padding:0;width:100%;border:none;text-align:left;outline:none;cursor:pointer}.btndisabled{border:1px solid #999!important;background-color:#ccc!important;color:#000!important;background:#ccc!important;text-shadow:none!important;cursor:default!important}input.settingvalue{margin-left:3px!important}label.settingvalue{vertical-align:top!important;width:90px!important;display:inline-block!important}
</style>
<script language="JavaScript" type="text/javascript" src="/js/jquery.js"></script>
<script language="JavaScript" type="text/javascript" src="/js/httpApi.js"></script>
<script language="JavaScript" type="text/javascript" src="/state.js"></script>
<script language="JavaScript" type="text/javascript" src="/general.js"></script>
<script language="JavaScript" type="text/javascript" src="/popup.js"></script>
<script language="JavaScript" type="text/javascript" src="/help.js"></script>
<script language="JavaScript" type="text/javascript" src="/ext/shared-jy/detect.js"></script>
<script language="JavaScript" type="text/javascript" src="/validator.js"></script>
<script>

/**----------------------------------------**/
/** Modified by Martinski W. [2024-Sep-09] **/
/**----------------------------------------**/

function showDST(){
	var system_timezone_dut = "<% nvram_get("time_zone"); %>";
	if(system_timezone_dut.search("DST") >= 0 && "<% nvram_get("time_zone_dst"); %>" == "1"){
	document.getElementById('dstzone').style.display = "";
	document.getElementById('dstzone').innerHTML = "* Daylight savings time is enabled in this time zone.";
	}
}

var custom_settings;
function LoadCustomSettings(){
	custom_settings = <% get_custom_settings(); %>;
	for (var prop in custom_settings){
		if(Object.prototype.hasOwnProperty.call(custom_settings, prop)){
			if (prop.indexOf("uiscribe") !== -1 && prop.indexOf("uiscribe_version") === -1){
				eval("delete custom_settings."+prop)
			}
		}
	}
}

var clockinterval,bootinterval,timeoutsenabled=!0;function showclock(){JS_timeObj.setTime(systime_millsec),systime_millsec+=1e3,JS_timeObj2=JS_timeObj.toString(),JS_timeObj2=JS_timeObj2.substring(0,3)+","+JS_timeObj2.substring(4,10)+" "+checkTime(JS_timeObj.getHours())+":"+checkTime(JS_timeObj.getMinutes())+":"+checkTime(JS_timeObj.getSeconds())+" "+JS_timeObj.getFullYear(),document.getElementById("system_time").value=JS_timeObj2,navigator.appName.indexOf("Microsoft")>=0&&(document.getElementById("log_messages").style.width="99%")}function showbootTime(){Days=Math.floor(boottime/86400),Hours=Math.floor(boottime/3600%24),Minutes=Math.floor(boottime%3600/60),Seconds=Math.floor(boottime%60),document.getElementById("boot_days").innerHTML=Days,document.getElementById("boot_hours").innerHTML=Hours,document.getElementById("boot_minutes").innerHTML=Minutes,document.getElementById("boot_seconds").innerHTML=Seconds,boottime+=1}function capitalise(e){return e.charAt(0).toUpperCase()+e.slice(1)}function GetCookie(e,t){return null!=cookie.get("uiscribe_"+e)?cookie.get("uiscribe_"+e):"string"==t?"":"number"==t?0:void 0}function SetCookie(e,t){cookie.set("uiscribe_"+e,t,3650)}function SetCurrentPage(){document.config_form.next_page.value=window.location.pathname.substring(1),document.config_form.current_page.value=window.location.pathname.substring(1)}function initial(){SetCurrentPage(),LoadCustomSettings(),ScriptUpdateLayout(),show_menu(),showclock(),showbootTime(),clockinterval=setInterval(showclock,1e3),bootinterval=setInterval(showbootTime,1e3),showDST(),get_conf_file()}function ScriptUpdateLayout(){var e=GetVersionNumber("local"),t=GetVersionNumber("server");$("#uiscribe_version_local").text(e),e!=t&&"N/A"!=t&&($("#uiscribe_version_server").text("Updated version available: "+t),showhide("btnChkUpdate",!1),showhide("uiscribe_version_server",!0),showhide("btnDoUpdate",!0))}function reload(){location.reload(!0)}function get_logfile(e){var t=e.replace(".log","");$.ajax({url:"/ext/uiScribe/"+e+".htm",dataType:"text",timeout:3e3,error:function(i){1==timeoutsenabled&&1==window["timeoutenabled_"+t]&&(window["timeout_"+t]=setTimeout(get_logfile,2e3,e))},success:function(i){1==timeoutsenabled&&1==window["timeoutenabled_"+t]&&("messages"!=e?i.length>0&&(document.getElementById("log_"+e.substring(0,e.indexOf("."))).innerHTML=i,document.getElementById("auto_scroll").checked&&$("#log_"+e.substring(0,e.indexOf("."))).scrollTop(9999999)):i.length>0&&(document.getElementById("log_"+e).innerHTML=i,document.getElementById("auto_scroll").checked&&$("#log_"+e).scrollTop(9999999)),window["timeout_"+t]=setTimeout(get_logfile,3e3,e))}})}function get_conf_file(){$.ajax({url:"/ext/uiScribe/logs.htm",timeout:2e3,dataType:"text",error:function(e){setTimeout(get_conf_file,1e3)},success:function(e){var t=e.split("\n");t.sort(),t=t.filter(Boolean);for(var i='<tr id="rowenabledlogs"><th width="40%">Logs to display in WebUI</th><td class="settingvalue">',o=0;o<t.length;o++){var n=t[o].substring(t[o].lastIndexOf("/")+1);-1!=n.indexOf("#")?(i+='<input type="checkbox" name="uiscribe_log_enabled" id="uiscribe_log_enabled_'+(n=n.substring(0,n.indexOf("#")).replace(".log","").replace(".htm","").trim())+'" class="input settingvalue" value="'+n+'">',i+='<label for="uiscribe_log_enabled_'+n+'" class="settingvalue">'+n+"</label>"):(i+='<input type="checkbox" name="uiscribe_log_enabled" id="uiscribe_log_enabled_'+(n=n.replace(".log","").replace(".htm","").trim())+'" class="input settingvalue" value="'+n+'" checked>',i+='<label for="uiscribe_log_enabled_'+n+'" class="settingvalue">'+n+"</label>"),(o+1)%4==0&&(i+="<br />")}i+="</td></tr>",i+='<tr class="apply_gen" valign="top" height="35px" id="rowsaveconfig">',i+='<td colspan="2" style="background-color:rgb(77,89,93);">',i+='<input type="button" onclick="SaveConfig();" value="Save" class="button_gen" name="button">',i+="</td></tr>",$("#table_config").append(i),t.reverse();for(o=0;o<t.length;o++){-1==t[o].indexOf("#")&&(n=t[o].substring(t[o].lastIndexOf("/")+1),$("#table_messages").after(BuildLogTable(n)))}AddEventHandlers()}})}function DownloadAllLogFile(){$(".btndownload").each((function(e){$(this).trigger("click")}))}function DownloadLogFile(e){$(e).prop("disabled",!0),$(e).addClass("btndisabled");var t="";t="btnmessages"==e.name?"/ext/uiScribe/messages.htm":"/ext/uiScribe/"+e.name.replace("btn","")+".log.htm",fetch(t).then((e=>e.blob())).then((t=>{const i=window.URL.createObjectURL(t),o=document.createElement("a");o.style.display="none",o.href=i,o.download=e.name.replace("btn","")+".log",document.body.appendChild(o),o.click(),window.URL.revokeObjectURL(i),$(e).prop("disabled",!1),$(e).removeClass("btndisabled")})).catch((()=>{$(e).prop("disabled",!1),$(e).removeClass("btndisabled")}))}function update_status(){$.ajax({url:"/ext/uiScribe/detect_update.js",dataType:"script",timeout:3e3,error:function(e){setTimeout(update_status,1e3)},success:function(){"InProgress"==updatestatus?setTimeout(update_status,1e3):(document.getElementById("imgChkUpdate").style.display="none",showhide("uiscribe_version_server",!0),"None"!=updatestatus?($("#uiscribe_version_server").text("Updated version available: "+updatestatus),showhide("btnChkUpdate",!1),showhide("btnDoUpdate",!0)):($("#uiscribe_version_server").text("No update available"),showhide("btnChkUpdate",!0),showhide("btnDoUpdate",!1)))}})}function CheckUpdate(){showhide("btnChkUpdate",!1),document.formScriptActions.action_script.value="start_uiScribecheckupdate",document.formScriptActions.submit(),document.getElementById("imgChkUpdate").style.display="",setTimeout(update_status,2e3)}function DoUpdate(){document.config_form.action_script.value="start_uiScribedoupdate",document.config_form.action_wait.value=10,showLoading(),document.config_form.submit()}function SaveConfig(){document.getElementById("amng_custom").value=JSON.stringify($("config_form").serializeObject()),document.config_form.action_script.value="start_uiScribeconfig",document.config_form.action_wait.value=5,showLoading(),document.config_form.submit()}function GetVersionNumber(e){var t;return"local"==e?t=custom_settings.uiscribe_version_local:"server"==e&&(t=custom_settings.uiscribe_version_server),void 0===t||null==t?"N/A":t}function BuildLogTable(e){var t='<div style="line-height:10px;">&nbsp;</div>';return t+='<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#4D595D" class="FormTable" id="table_'+e.substring(0,e.indexOf("."))+'">',t+='<thead class="collapsible-jquery" id="thead_'+e.substring(0,e.indexOf("."))+'"><tr><td colspan="2">'+e+" (click to show/hide)</td></tr></thead>",t+='<tr><td style="padding: 0px;">',t+='<textarea cols="63" rows="27" wrap="off" readonly="readonly" id="log_'+e.substring(0,e.indexOf("."))+'" class="textarea_log_table" style="font-family:\'Courier New\',Courier,mono; font-size:11px;">Log file will display here. If you are seeing this message,it means the log file cannot be loaded.\r\nPlease check your USB to check the /opt/var/log directory exists.</textarea>',t+="</td></tr>",t+='<tr class="apply_gen" valign="top" height="35px"><td style="background-color:rgb(77,89,93);border:0px;">',t+='<input type="button" onclick="DownloadLogFile(this);" value="Download log file" class="button_gen btndownload" name="btn'+e.substring(0,e.indexOf("."))+'" id="btn'+e.substring(0,e.indexOf("."))+'">',t+="</td></tr>",t+="</table>"}function AddEventHandlers(){$(".collapsible-jquery").off("click").on("click",(function(){var e=$(this).prop("id").replace("thead_","");"messages"!=e&&(e+=".log");var t=e.replace(".log","");1==$(this).siblings().is(":hidden")?(window["timeoutenabled_"+t]=!0,get_logfile(e)):(clearTimeout(window["timeout_"+t]),window["timeoutenabled_"+t]=!1),$(this).siblings().toggle("fast")})),ResizeAll("hide"),$("#thead_messages").trigger("click"),$(".collapsible-jquery-config").off("click").on("click",(function(){$(this).siblings().toggle("fast",(function(){"none"==$(this).css("display")?SetCookie($(this).siblings()[0].id,"collapsed"):SetCookie($(this).siblings()[0].id,"expanded")}))})),$(".collapsible-jquery-config").each((function(e,t){"collapsed"==GetCookie($(this)[0].id,"string")?$(this).siblings().toggle(!1):$(this).siblings().toggle(!0)}))}function ToggleRefresh(){1==$("#auto_refresh").prop("checked")?($("#auto_scroll").prop("disabled",!1),timeoutsenabled=!0,$(".collapsible-jquery").each((function(e,t){var i=$(this).prop("id").replace("thead_","");"messages"!=i&&(i+=".log"),0==$(this).siblings().is(":hidden")&&get_logfile(i)}))):($("#auto_scroll").prop("disabled",!0),timeoutsenabled=!1)}function ResizeAll(e){$(".collapsible-jquery").each((function(t,i){if("show"==e){$(this).siblings().toggle(!0);var o=$(this).prop("id").replace("thead_","");window["timeoutenabled_"+o]=!0,"messages"!=o&&(o+=".log"),get_logfile(o)}else{$(this).siblings().toggle(!1);o=$(this).prop("id").replace("thead_","");window["timeoutenabled_"+o]=!1,clearTimeout(window["timeout_"+o])}}))}$.fn.serializeObject=function(){var e=custom_settings,t=[];$.each($('input[name="uiscribe_log_enabled"]:checked'),(function(){t.push(this.value)}));var i=t.join(",");return e.uiscribe_logs_enabled=i,e};

</script>
</head>
<body onload="initial();" onunload="return unload_body();">
<div id="TopBanner"></div>
<div id="Loading" class="popup_bg"></div>
<iframe name="hidden_frame" id="hidden_frame" src="about:blank" width="0" height="0" frameborder="0"></iframe>
<form method="post" name="form" action="apply.cgi" target="hidden_frame">
</form>
<table class="content" align="center" cellpadding="0" cellspacing="0">
<tr>
<td width="17">&nbsp;</td>
<td valign="top" width="202">
<div id="mainMenu"></div>
<div id="subMenu"></div>
</td>
<td valign="top">
<div id="tabMenu" class="submenuBlock"></div>
<table width="98%" border="0" align="left" cellpadding="0" cellspacing="0">
<tr>
<td align="left" valign="top">
<table width="760px" border="0" cellpadding="5" cellspacing="0" bordercolor="#6b8fa3" class="FormTitle" id="FormTitle">
<tr>
<td bgcolor="#4D595D" colspan="3" valign="top">
<div>&nbsp;</div>
<div class="formfonttitle">System Log - enhanced by Scribe</div>
<div style="margin:10px 0 10px 5px;" class="splitLine"></div>
<div class="formfontdesc">This page shows the detailed system's activities.</div>
<form method="post" name="config_form" action="/start_apply.htm" target="hidden_frame">
<input type="hidden" name="group_id" value="">
<input type="hidden" name="current_page" value="">
<input type="hidden" name="next_page" value="">
<input type="hidden" name="modified" value="0">
<input type="hidden" name="action_mode" value="apply">
<input type="hidden" name="action_wait" value="15">
<input type="hidden" name="action_script" value="">
<input type="hidden" name="first_time" value="">
<input type="hidden" name="SystemCmd" value="">
<input type="hidden" name="preferred_lang" id="preferred_lang" value="<% nvram_get("preferred_lang"); %>">
<input type="hidden" name="firmver" value="<% nvram_get("firmver"); %>">
<input type="hidden" name="amng_custom" id="amng_custom" value="">
<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable" style="border:0px;" id="table_buttons">
<thead class="collapsible-jquery-config" id="scripttools">
<tr><td colspan="2">Utilities (click to expand/collapse)</td></tr>
</thead>
<tr>
<th width="20%">Version information</th>
<td>
<span id="uiscribe_version_local" style="color:#FFFFFF;"></span>
&nbsp;&nbsp;&nbsp;
<span id="uiscribe_version_server" style="display:none;">Update version</span>
&nbsp;&nbsp;&nbsp;
<input type="button" class="button_gen" onclick="CheckUpdate();" value="Check" id="btnChkUpdate">
<img id="imgChkUpdate" style="display:none;vertical-align:middle;" src="images/InternetScan.gif"/>
<input type="button" class="button_gen" onclick="DoUpdate();" value="Update" id="btnDoUpdate" style="display:none;">
&nbsp;&nbsp;&nbsp;
</td>
</tr>
</table>
<div style="line-height:10px;">&nbsp;</div>
<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
<thead class="collapsible-jquery-config" id="systeminfo">
<tr><td colspan="2">System Info (click to expand/collapse)</td></tr>
</thead>
<tr>
<th width="20%">System Time</th>
<td>
<input type="text" id="system_time" name="system_time" size="40" class="devicepin" value="" readonly="1" style="font-size:12px;" autocorrect="off" autocapitalize="off">
<br><span id="dstzone" style="display:none;margin-left:5px;color:#FFFFFF;"></span>
</td>
</tr>
<tr>
<th>Uptime</th>
<td><span id="boot_days"></span> days <span id="boot_hours"></span> hours <span id="boot_minutes"></span> minute(s) <span id="boot_seconds"></span> seconds</td>
</tr>
<tr style="display:none;">
<td>
<input type="text" maxlength="15" class="input_15_table" name="log_ipaddr" value="<% nvram_get("log_ipaddr"); %>" onkeypress="return validator.isIPAddr(this, event)" autocorrect="off" autocapitalize="off">
<label style="padding-left:15px;">Port:</label><input type="text" class="input_6_table" maxlength="5" name="log_port" onkeypress="return validator.isNumber(this,event);" onblur="validator.numberRange(this, 0, 65535);" value="<% nvram_get('log_port'); %>" autocorrect="off" autocapitalize="off">
</td>
</tr>
<tr style="display:none;">
<th><a class="hintstyle" href="javascript:void(0);" onclick="openHint(50,11);">Default message log level</a></th>
<td>
<select name="message_loglevel" class="input_option">
<option value="0" <% nvram_match("message_loglevel", "0", "selected"); %>>emergency</option>
<option value="1" <% nvram_match("message_loglevel", "1", "selected"); %>>alert</option>
<option value="2" <% nvram_match("message_loglevel", "2", "selected"); %>>critical</option>
<option value="3" <% nvram_match("message_loglevel", "3", "selected"); %>>error</option>
<option value="4" <% nvram_match("message_loglevel", "4", "selected"); %>>warning</option>
<option value="5" <% nvram_match("message_loglevel", "5", "selected"); %>>notice</option>
<option value="6" <% nvram_match("message_loglevel", "6", "selected"); %>>info</option>
<option value="7" <% nvram_match("message_loglevel", "7", "selected"); %>>debug</option>
</select>
</td>
</tr>
<tr style="display:none;">
<th><a class="hintstyle" href="javascript:void(0);" onclick="openHint(50,12);">Log only messages more urgent than</a></th>
<td>
<select name="log_level" class="input_option">
<option value="1" <% nvram_match("log_level", "1", "selected"); %>>alert</option>
<option value="2" <% nvram_match("log_level", "2", "selected"); %>>critical</option>
<option value="3" <% nvram_match("log_level", "3", "selected"); %>>error</option>
<option value="4" <% nvram_match("log_level", "4", "selected"); %>>warning</option>
<option value="5" <% nvram_match("log_level", "5", "selected"); %>>notice</option>
<option value="6" <% nvram_match("log_level", "6", "selected"); %>>info</option>
<option value="7" <% nvram_match("log_level", "7", "selected"); %>>debug</option>
<option value="8" <% nvram_match("log_level", "8", "selected"); %>>all</option>
</select>
</td>
</tr>
<tr class="apply_gen" valign="top" style="display:none;"><td><input class="button_gen" onclick="applySettings();" type="button" value="Apply" /></td></tr>
</table>
<div style="line-height:10px;">&nbsp;</div>
<table width="100%" border="1" align="center" cellpadding="2" cellspacing="0" bordercolor="#6b8fa3" class="FormTable" style="border:0px;" id="table_config">
<thead class="collapsible-jquery-config" id="scriptconfig">
<tr><td colspan="2">General Configuration (click to expand/collapse)</td></tr>
</thead>
</table>
</form>
<div style="line-height:10px;">&nbsp;</div>
<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
<thead class="collapsible-jquery-config" id="tablelogs">
<tr><td colspan="2">Logs (click to expand/collapse)</td></tr>
</thead>
<tr><td style="padding-left:4px;">
<div style="color:#FFCC00;"><input type="checkbox" checked id="auto_refresh" onclick="ToggleRefresh();">Auto refresh&nbsp;&nbsp;&nbsp;<input type="checkbox" checked id="auto_scroll">Scroll to bottom on refresh?</div>
<table class="apply_gen" style="margin-top:0px;">
<form name="formui_buttons">
<tr class="apply_gen" valign="top" align="center">
<td style="border:0px;">
<input style="text-align:center;" id="btn_ShowAll" value="Show All" class="button_gen" onclick="ResizeAll('show');" type="button">
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<input style="text-align:center;" id="btn_HideAll" value="Hide All" class="button_gen" onclick="ResizeAll('hide');" type="button">
</td>
</tr>
<tr class="apply_gen" valign="top" align="center">
<td style="border:0px;">
<input style="text-align:center;" id="btn_DownloadAll" value="Download All" class="button_gen" onclick="DownloadAllLogFile();" type="button">
</td>
</tr>
</form>
</table>
<div style="line-height:10px;">&nbsp;</div>
<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#4D595D" class="FormTable" id="table_messages">
<thead class="collapsible-jquery" id="thead_messages">
<tr><td colspan="2">System Messages (click to show/hide)</td></tr>
</thead>
<tr><td style="padding: 0px;">
<textarea cols="63" rows="27" wrap="off" readonly="readonly" id="log_messages" class="textarea_log_table" style="font-family:'Courier New', Courier, mono; font-size:11px;"><% nvram_dump("syslog.log",""); %></textarea>
</td></tr>
<tr class="apply_gen" valign="top" height="35px"><td style="background-color:rgb(77, 89, 93);border:0px;">
<input type="button" onclick="DownloadLogFile(this);" value="Download log file" class="button_gen btndownload" name="btnmessages" id="btnmessages">
</td>
</tr>
</table>
</tr>
</td>
</table>
<div style="line-height:10px;">&nbsp;</div>
</td>
</tr>
</table>
</td>
</tr>
</table>
</td>
<td width="10" align="center" valign="top"></td>
</tr>
</table>
<form method="post" name="formScriptActions" action="/start_apply.htm" target="hidden_frame">
<input type="hidden" name="productid" value="<% nvram_get("productid"); %>">
<input type="hidden" name="current_page" value="">
<input type="hidden" name="next_page" value="">
<input type="hidden" name="action_mode" value="apply">
<input type="hidden" name="action_script" value="">
<input type="hidden" name="action_wait" value="">
</form>
<div id="footer"></div>
</body>
</html>
