/**----------------------------**/
/** Last Modified: 2025-Nov-30 **/
/**----------------------------**/

var timeoutsenabled = true;

var clockinterval;
var bootinterval;
let logFileInfoListInterval = null;
let isInitialLoading = false;

var logRotate_InfoListArray = [];

function showclock()
{
	JS_timeObj.setTime(systime_millsec);
	systime_millsec += 1000;
	JS_timeObj2 = JS_timeObj.toString();
	JS_timeObj2 = JS_timeObj2.substring(0,3)+',' +
	JS_timeObj2.substring(4,10)+' ' +
	checkTime(JS_timeObj.getHours())+':' +
	checkTime(JS_timeObj.getMinutes())+':' +
	checkTime(JS_timeObj.getSeconds())+' ' +
	/*JS_timeObj.getFullYear()+' GMT' +
	timezone;*/ // Viz remove GMT timezone 2011.08
	JS_timeObj.getFullYear();
	document.getElementById('system_time').value = JS_timeObj2;
	if(navigator.appName.indexOf('Microsoft') >= 0)
	document.getElementById('log_messages').style.width = '99%';
}

function showbootTime()
{
	Days = Math.floor(boottime / (60*60*24));
	Hours = Math.floor((boottime / 3600) % 24);
	Minutes = Math.floor(boottime % 3600 / 60);
	Seconds = Math.floor(boottime % 60);
	document.getElementById('boot_days').innerHTML = Days;
	document.getElementById('boot_hours').innerHTML = Hours;
	document.getElementById('boot_minutes').innerHTML = Minutes;
	document.getElementById('boot_seconds').innerHTML = Seconds;
	boottime += 1;
}

function capitalise(string)
{
	return string.charAt(0).toUpperCase()+string.slice(1);
}

function GetCookie(cookiename,returntype)
{
	if (cookie.get('uiscribe_'+cookiename) != null)
	{
		return cookie.get('uiscribe_'+cookiename);
	}
	else
	{
		if (returntype == 'string'){
			return '';
		}
		else if (returntype == 'number'){
			return 0;
		}
	}
}

function SetCookie(cookiename,cookievalue)
{
	cookie.set('uiscribe_'+cookiename,cookievalue,10*365);
}

$.fn.serializeObject = function(){
	var o = custom_settings;
	
	var logsenabled = [];
	$.each($('input[name="uiscribe_log_enabled"]:checked'),function(){
		logsenabled.push(this.value);
	});
	var logsenabledstring = logsenabled.join(',');
	o['uiscribe_logs_enabled'] = logsenabledstring;
	return o;
};

function SetCurrentPage()
{
	document.config_form.next_page.value = window.location.pathname.substring(1);
	document.config_form.current_page.value = window.location.pathname.substring(1);
}

/**----------------------------------------**/
/** Modified by Martinski W. [2025-Nov-28] **/
/**----------------------------------------**/
function initial()
{
	isInitialLoading = true;
	SetCurrentPage();
	LoadCustomSettings();
	ScriptUpdateLayout();
	GetLogRotateInfoList();
	setTimeout(GetLogFileInfoList, 7000);
	show_menu();
	showclock();
	showbootTime();
	clockinterval = setInterval(showclock,1000);
	bootinterval = setInterval(showbootTime,1000);
	showDST();
	GetLogsUserTable();
	logFileInfoListInterval = setInterval(GetLogFileInfoList,180000);
}

function ScriptUpdateLayout()
{
	var localver = GetVersionNumber('local');
	var serverver = GetVersionNumber('server');
	$('#uiscribe_version_local').text(localver);
	
	if (localver != serverver && serverver != 'N/A')
	{
		$('#uiscribe_version_server').text('Updated version available: '+serverver);
		showhide('btnChkUpdate',false);
		showhide('uiscribe_version_server',true);
		showhide('btnDoUpdate',true);
	}
}

function reload()
{
	location.reload(true);
}

/**----------------------------------------**/
/** Modified by Martinski W. [2025-Nov-30] **/
/**----------------------------------------**/
function get_logfile(fileName)
{
	let fileNameShort = fileName.replace('.log','');

	$.ajax({
		url: '/ext/uiScribe/'+fileName+'.htm',
		dataType: 'text',
		timeout: 3000,
		error: function(xhr)
		{
			if (timeoutsenabled == true && window['timeoutenabled_'+fileNameShort] == true)
			{
				window['timeout_'+fileNameShort] = setTimeout(get_logfile,2000,fileName);
			}
		},
		success: function(data)
		{
			let logFileDataElem = document.getElementById('log_'+fileNameShort);

			if (timeoutsenabled == true && window['timeoutenabled_'+fileNameShort] == true)
			{
				if (data.length === 0)
				{
					logFileDataElem.innerHTML = '*** The log file is either empty or does not yet exist ***';
				}
				if (fileName != 'messages')
				{
					if (data.length > 0)
					{
						logFileDataElem.innerHTML = data;
						if (document.getElementById('auto_scroll').checked)
						{
							$('#log_'+fileNameShort).scrollTop(9999999);
						}
					}
				}
				else
				{
					if (data.length > 0)
					{
						logFileDataElem.innerHTML = data;
						if (document.getElementById('auto_scroll').checked)
						{
							$('#log_'+fileName).scrollTop(9999999);
						}
					}
				}
				window['timeout_'+fileNameShort] = setTimeout(get_logfile,3000,fileName);
			}
		}
	});
}

/**----------------------------------------**/
/** Modified by Martinski W. [2025-Nov-28] **/
/**----------------------------------------**/
function GetLogsUserTable()
{
	$.ajax({
		url: '/ext/uiScribe/logs_user.htm',
		timeout: 2000,
		dataType: 'text',
		error: function(xhr)
		{
			setTimeout(GetLogsUserTable,2000);
		},
		success: function(data)
		{
			var logFiles = data.split('\n');
			logFiles.sort();
			logFiles = logFiles.filter(Boolean);

			var logconfigtablehtml='<tr id="rowenabledlogs"><th width="40%">Logs to display in WebUI</th><td class="settingvalue">';

			for (var i = 0; i < logFiles.length; i++)
			{
				var fileName = logFiles[i].substring(logFiles[i].lastIndexOf('/')+1);
				if (fileName.indexOf('#') != -1)
				{
					fileName = fileName.substring(0,fileName.indexOf('#')).replace('.log','').replace('.htm','').trim();
					logconfigtablehtml += '<input type="checkbox" name="uiscribe_log_enabled" id="uiscribe_log_enabled_'+ fileName +'" class="input settingvalue" value="'+fileName+'">';
					logconfigtablehtml += '<label for="uiscribe_log_enabled_'+ fileName +'" class="settingvalue">'+fileName+'</label>';
				}
				else
				{
					fileName = fileName.replace(".log","").replace(".htm","").trim();
					logconfigtablehtml += '<input type="checkbox" name="uiscribe_log_enabled" id="uiscribe_log_enabled_'+ fileName +'" class="input settingvalue" value="'+fileName+'" checked>';
					logconfigtablehtml += '<label for="uiscribe_log_enabled_'+ fileName +'" class="settingvalue">'+fileName+'</label>';
				}
				if ((i+1) % 4 == 0)
				{
					logconfigtablehtml += '<br />';
				}
			}

			logconfigtablehtml += '</td></tr>';
			logconfigtablehtml += '<tr class="apply_gen" valign="top" height="35px" id="rowsaveconfig">';
			logconfigtablehtml += '<td colspan="2" style="background-color:rgb(77,89,93);">';
			logconfigtablehtml += '<input type="button" onclick="SaveConfig();" value="Save" class="button_gen" name="button">';
			logconfigtablehtml += '</td></tr>';
			$('#table_config').append(logconfigtablehtml);
			logFiles.reverse();

			for (var i = 0; i < logFiles.length; i++)
			{
				var commentstart = logFiles[i].indexOf('#');
				if (commentstart != -1) { continue; }
				fileName = logFiles[i].substring(logFiles[i].lastIndexOf('/')+1);
				$('#table_messages').after(BuildLogTable(fileName));
			}

			let logFileInfoStr = GetLogFileSizeInfo('messages');
			document.getElementById('fileTitle_messages').innerHTML = logFileInfoStr + '&nbsp;&nbsp;&nbsp(click to show/hide)'
			AddEventHandlers();
			isInitialLoading = false;
		}
	});
}

function DownloadAllLogFiles()
{
	$('.btndownload').each(function(index){$(this).trigger('click');});
}

/**----------------------------------------**/
/** Modified by Martinski W. [2025-Nov-28] **/
/**----------------------------------------**/
function DownloadLogFile(btnLog)
{
	$(btnLog).prop('disabled',true);
	$(btnLog).addClass('btndisabled');
	var filepath = '';
	if (btnLog.name === 'btnDownload_messages')
	{
		filepath='/ext/uiScribe/messages.htm';
	}
	else
	{
		filepath='/ext/uiScribe/'+btnLog.name.replace('btnDownload_','')+'.log.htm';
	}
	fetch(filepath).then(resp => resp.blob()).then(blob => {
		const url = window.URL.createObjectURL(blob);
		const a = document.createElement('a');
		a.style.display = 'none';
		a.href = url;
		a.download = btnLog.name.replace('btnDownload_','')+'.log';
		document.body.appendChild(a);
		a.click();
		window.URL.revokeObjectURL(url);
		$(btnLog).prop('disabled',false);
		$(btnLog).removeClass('btndisabled');
	})
	.catch(() => {
		console.log('File download failed!');
		$(btnLog).prop('disabled',false);
		$(btnLog).removeClass('btndisabled');
	});
}

function update_status()
{
	$.ajax({
		url: '/ext/uiScribe/detect_update.js',
		dataType: 'script',
		timeout: 3000,
		error: function(xhr){
			setTimeout(update_status,1000);
		},
		success: function()
		{
			if (updatestatus == 'InProgress')
			{
				setTimeout(update_status,1000);
			}
			else
			{
				document.getElementById('imgChkUpdate').style.display = 'none';
				showhide('uiscribe_version_server',true);
				if (updatestatus != 'None')
				{
					$('#uiscribe_version_server').text('Updated version available: '+updatestatus);
					showhide('btnChkUpdate',false);
					showhide('btnDoUpdate',true);
				}
				else
				{
					$('#uiscribe_version_server').text('No update available');
					showhide('btnChkUpdate',true);
					showhide('btnDoUpdate',false);
				}
			}
		}
	});
}

var logRotateStatus = '';

/**-------------------------------------**/
/** Added by Martinski W. [2025-Nov-28] **/
/**-------------------------------------**/
function Update_LogRotate_Status(logObj)
{
	$.ajax({
		url: '/ext/uiScribe/logRotateStatus.js',
		dataType: 'script',
		timeout: 3000,
		error: function(xhr){
			setTimeout(Update_LogRotate_Status,1000,logObj);
		},
		success: function()
		{
			let theStatus = '';
			if (logRotateStatus === 'InProgress')
			{
				setTimeout(Update_LogRotate_Status,2000,logObj);
			}
			else if (logRotateStatus === 'ERROR')
			{
				theStatus = logRotateStatus;
			}
			else if (logRotateStatus === 'DONE')
			{
				theStatus = logRotateStatus;
			}
			$(logObj).prop('disabled',false);
			$(logObj).removeClass('btndisabled');
			document.getElementById(logObj.id).style.display = '';
			document.getElementById('imgChkUpdate').style.display = 'none';
		}
	});
}

/**-------------------------------------**/
/** Added by Martinski W. [2025-Nov-28] **/
/**-------------------------------------**/
function RotateLogFile(logObj, logFileName)
{
	if (typeof logFileInfoListInterval !== 'undefined' && logFileInfoListInterval !== null)
	{
		clearInterval(logFileInfoListInterval);
		logFileInfoListInterval = null;
	}

	$(logObj).prop('disabled',true);
	$(logObj).addClass('btndisabled');

	let waitValue = 30;
	if (logFileName === 'ALL')
	{
		if (logRotate_InfoListArray.length > 5)
		{ waitValue = 60; }
		else
		{ waitValue = 45; }
	}
	let actionScriptVal = 'start_uiScribeRotateLog_' + logFileName;
	document.config_form.action_script.value = actionScriptVal;
	document.config_form.action_wait.value = waitValue;
	showLoading();
	document.config_form.submit();
}

/**-------------------------------------**/
/** Added by Martinski W. [2025-Nov-28] **/
/**-------------------------------------**/
function ClearLogFile(logObj, logFileName)
{
	if (typeof logFileInfoListInterval !== 'undefined' && logFileInfoListInterval !== null)
	{
		clearInterval(logFileInfoListInterval);
		logFileInfoListInterval = null;
	}

	$(logObj).prop('disabled',true);
	$(logObj).addClass('btndisabled');

	let waitValue = 30;
	if (logFileName === 'ALL')
	{
		if (logRotate_InfoListArray.length > 5)
		{ waitValue = 60; }
		else
		{ waitValue = 45; }
	}
	let actionScriptVal = 'start_uiScribeClearLog_' + logFileName;
	document.config_form.action_script.value = actionScriptVal;
	document.config_form.action_wait.value = waitValue;
	showLoading();
	document.config_form.submit();
}

function CheckUpdate()
{
	showhide('btnChkUpdate',false);
	document.formScriptActions.action_script.value='start_uiScribecheckupdate';
	document.formScriptActions.submit();
	document.getElementById('imgChkUpdate').style.display = '';
	setTimeout(update_status,2000);
}

function DoUpdate()
{
	document.config_form.action_script.value = 'start_uiScribedoupdate';
	document.config_form.action_wait.value = 10;
	showLoading();
	document.config_form.submit();
}

/**----------------------------------------**/
/** Modified by Martinski W. [2025-Nov-28] **/
/**----------------------------------------**/
function SaveConfig()
{
	if (typeof logFileInfoListInterval !== 'undefined' && logFileInfoListInterval !== null)
	{
		clearInterval(logFileInfoListInterval);
		logFileInfoListInterval = null;
	}

	document.getElementById('amng_custom').value = JSON.stringify($('config_form').serializeObject());
	document.config_form.action_script.value = 'start_uiScribeconfig';
	document.config_form.action_wait.value = 5;
	showLoading();
	document.config_form.submit();
}

function GetVersionNumber(versiontype)
{
	var versionprop;
	if (versiontype == 'local'){
		versionprop = custom_settings.uiscribe_version_local;
	}
	else if (versiontype == 'server'){
		versionprop = custom_settings.uiscribe_version_server;
	}
	
	if (typeof versionprop == 'undefined' || versionprop == null){
		return 'N/A';
	}
	else{
		return versionprop;
	}
}

/**-------------------------------------**/
/** Added by Martinski W. [2025-Nov-28] **/
/**-------------------------------------**/
function GetLogRotateInfoList()
{
	$.ajax({
		url: '/ext/uiScribe/logRotateInfoList.js',
		dataType: 'script',
		timeout: 1000,
		error: function(xhr){
			setTimeout(GetLogRotateInfoList, 1000);
		},
		success: function()
		{
			if (logRotate_InfoListArray.length === 0)
			{ return false; }
			if (isInitialLoading) { return true; }
			SetLogFileSizeInfo();
		}
	});
}

/**-------------------------------------**/
/** Added by Martinski W. [2025-Nov-28] **/
/**-------------------------------------**/
function GetLogFileInfoList()
{
	document.formScriptActions.action_script.value='start_uiScribeLogFileInfoList';
	document.formScriptActions.submit();
	setTimeout(GetLogRotateInfoList,3000);
}

/**-------------------------------------**/
/** Added by Martinski W. [2025-Nov-28] **/
/**-------------------------------------**/
function SetLogFileSizeInfo()
{
	$.ajax({
		url: '/ext/uiScribe/logs_user.htm',
		timeout: 2000,
		dataType: 'text',
		error: function(xhr)
		{
			setTimeout(SetLogFileSizeInfo,2000);
		},
		success: function(data)
		{
			let logFileName, fileNameShort, logFileTitleElem, logFileInfoStr;
			let logFiles = data.split('\n');
			logFiles.sort();
			logFiles = logFiles.filter(Boolean);

			for (var indx = 0; indx < logFiles.length; indx++)
			{
				var commentstart = logFiles[indx].indexOf('#');
				if (commentstart != -1) { continue; }
				logFileName = logFiles[indx].substring(logFiles[indx].lastIndexOf('/')+1);
				fileNameShort = logFileName.replace('.log','');

				logFileTitleElem = document.getElementById('fileTitle_' + fileNameShort);
				if (typeof logFileTitleElem !== 'undefined' && logFileTitleElem !== null)
				{
					logFileInfoStr = GetLogFileSizeInfo(logFileName);
					logFileTitleElem.innerHTML = logFileInfoStr + '&nbsp;&nbsp;&nbsp(click to show/hide)'
				}
			}

			logFileTitleElem = document.getElementById('fileTitle_messages');
			if (typeof logFileTitleElem !== 'undefined' && logFileTitleElem !== null)
			{
				logFileInfoStr = GetLogFileSizeInfo('messages');
				logFileTitleElem.innerHTML = logFileInfoStr + '&nbsp;&nbsp;&nbsp(click to show/hide)'
			}
		}
	});
}

/**-------------------------------------**/
/** Added by Martinski W. [2025-Nov-28] **/
/**-------------------------------------**/
function GetLogFileSizeInfo(theFileName)
{
	let logFilePath, logFileSize, logFileName, logFileInfoStr;
	let fileSizeOK = false;

	for (var indx = 0; indx < logRotate_InfoListArray.length; indx++)
	{
		logFilePath = logRotate_InfoListArray[indx].LOG_PATH0;
		logFileSize = logRotate_InfoListArray[indx].LOG_SIZE0;
		logFileName = logFilePath.replace('/opt/var/log/','');
		if (logFileName === theFileName)
		{ fileSizeOK = true; break; }
	}

	if (logFileSize === '' || !fileSizeOK)
	{ logFileInfoStr = theFileName; }
	else
	{ logFileInfoStr = theFileName + ' [' + logFileSize + ']';  }

	return logFileInfoStr;
}

/**----------------------------------------**/
/** Modified by Martinski W. [2025-Nov-28] **/
/**----------------------------------------**/
function BuildLogTable(logFileName)
{
	let logFileInfoStr = GetLogFileSizeInfo(logFileName);
	let fileNameShort = logFileName.substring(0,logFileName.indexOf('.'));

	var loghtml = '<div style="line-height:10px;">&nbsp;</div>';
	loghtml += '<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#4D595D" class="FormTable" id="table_'+fileNameShort+'">';
	loghtml += '<thead class="collapsible-jquery" id="thead_'+fileNameShort+'"><tr><td id="fileTitle_'+fileNameShort+'" colspan="2">'+logFileInfoStr+'&nbsp;&nbsp;&nbsp(click to show/hide)</td></tr></thead>';

	loghtml += '<tr><td style="padding: 0px;">';
	loghtml += '<textarea cols="63" rows="27" wrap="off" readonly="readonly" id="log_'+fileNameShort+'" class="textarea_log_table" style="font-family:\'Courier New\',Courier,mono; font-size:11px;">The log file will be displayed here. If you are seeing this message, it means the log file cannot be loaded.\r\nPlease double-check your USB drive to see if the \"/opt/var/log\" directory and the log file exists.\r\nAlso, note that if the log file size is too big (greater than 4.0MB), it may not load at all.</textarea>';
	loghtml += '</td></tr>';

	loghtml += '<tr class="apply_gen" valign="top" height="35px"><td style="background-color:rgb(77,89,93);border:0px;">';
	loghtml += '<input type="button" onclick="DownloadLogFile(this);" value="Download Log" class="button_gen btndownload" name="btnDownload_'+fileNameShort+'" id="btnDownload_'+fileNameShort+'">';
	loghtml += '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;';
	loghtml += '<input type="button" onclick="RotateLogFile(this,\''+logFileName+'\');" value="Rotate Log" class="button_gen btnRotateLog" name="btnRotateLog_'+fileNameShort+'" id="btnRotateLog_'+fileNameShort+'">';
	loghtml += '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;';
	loghtml += '<input type="button" onclick="ClearLogFile(this,\''+logFileName+'\');" value="Clear Log" class="button_gen btnClearLog" name="btnClearLog_'+fileNameShort+'" id="btnClearLog_'+fileNameShort+'">';

	loghtml += '</td></tr>';
	loghtml += '</table>';

	return loghtml;
}

function AddEventHandlers()
{
	$('.collapsible-jquery').off('click').on('click',function(){
		var filename = $(this).prop('id').replace('thead_','');
		if (filename != 'messages')
		{
			filename += '.log';
		}
		var fileNameShort = filename.replace('.log','');
		if ($(this).siblings().is(':hidden') == true)
		{
			window['timeoutenabled_'+fileNameShort] = true;
			get_logfile(filename);
		}
		else
		{
			clearTimeout(window['timeout_'+fileNameShort]);
			window['timeoutenabled_'+fileNameShort] = false;
		}
		$(this).siblings().toggle('fast');
	});
	
	ResizeAll('hide');
	
	$('#thead_messages').trigger('click');
	
	$('.collapsible-jquery-config').off('click').on('click',function(){
		$(this).siblings().toggle('fast',function(){
			if ($(this).css('display') == 'none')
			{
				SetCookie($(this).siblings()[0].id,'collapsed');
			}
			else
			{
				SetCookie($(this).siblings()[0].id,'expanded');
			}
		})
	});
	
	$('.collapsible-jquery-config').each(function(index,element){
		if (GetCookie($(this)[0].id,'string') == 'collapsed')
		{
			$(this).siblings().toggle(false);
		}
		else
		{
			$(this).siblings().toggle(true);
		}
	});
}

function ToggleRefresh()
{
	if ($('#auto_refresh').prop('checked') == true)
	{
		$('#auto_scroll').prop('disabled',false)
		timeoutsenabled = true;
		
		$('.collapsible-jquery').each(function(index,element){
			var filename = $(this).prop('id').replace('thead_','');
			if (filename != 'messages')
			{
				filename += '.log';
			}
			if ($(this).siblings().is(':hidden') == false)
			{
				get_logfile(filename);
			}
		});
	}
	else
	{
		$('#auto_scroll').prop('disabled',true)
		timeoutsenabled = false;
	}
}

function ResizeAll(action)
{
	$('.collapsible-jquery').each(function(index,element){
		if (action == 'show')
		{
			$(this).siblings().toggle(true);
			var filename = $(this).prop('id').replace('thead_','');
			window['timeoutenabled_'+filename] = true;
			if (filename != 'messages')
			{
				filename += '.log';
			}
			get_logfile(filename);
		}
		else
		{
			$(this).siblings().toggle(false);
			var filename = $(this).prop('id').replace('thead_','');
			window['timeoutenabled_'+filename] = false;
			clearTimeout(window['timeout_'+filename]);
		}
	});
}
