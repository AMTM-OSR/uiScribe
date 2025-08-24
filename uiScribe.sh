#!/bin/sh

########################################################
##                                                    ##
##           _   _____              _  _              ##
##          (_) / ____|            (_)| |             ##
##    _   _  _ | (___    ___  _ __  _ | |__    ___    ##
##   | | | || | \___ \  / __|| '__|| || '_ \  / _ \   ##
##   | |_| || | ____) || (__ | |   | || |_) ||  __/   ##
##    \__,_||_||_____/  \___||_|   |_||_.__/  \___|   ##
##                                                    ##
##        https://github.com/AMTM-OSR/uiScribe        ##
##  Forked from https://github.com/jackyaz/uiScribe   ##
##                                                    ##
########################################################
# Last Modified: 2025-Aug-23
#-------------------------------------------------------

###########        Shellcheck directives      ##########
# shellcheck disable=SC2009
# shellcheck disable=SC2016
# shellcheck disable=SC2018
# shellcheck disable=SC2019
# shellcheck disable=SC2059
# shellcheck disable=SC2155
# shellcheck disable=SC3043
# shellcheck disable=SC3045
########################################################

### Start of script variables ###
readonly SCRIPT_NAME="uiScribe"
readonly SCRIPT_VERSION="v1.4.8"
readonly SCRIPT_VERSTAG="25082322"
SCRIPT_BRANCH="master"
SCRIPT_REPO="https://raw.githubusercontent.com/AMTM-OSR/$SCRIPT_NAME/$SCRIPT_BRANCH"
readonly SCRIPT_DIR="/jffs/addons/$SCRIPT_NAME.d"
readonly SCRIPT_PAGE_DIR="$(readlink -f /www/user)"
readonly SCRIPT_WEB_DIR="$SCRIPT_PAGE_DIR/$SCRIPT_NAME"
readonly SHARED_DIR="/jffs/addons/shared-jy"
readonly SHARED_REPO="https://raw.githubusercontent.com/AMTM-OSR/shared-jy/master"
readonly SHARED_WEB_DIR="$SCRIPT_PAGE_DIR/shared-jy"
[ -z "$(nvram get odmpid)" ] && ROUTER_MODEL="$(nvram get productid)" || ROUTER_MODEL="$(nvram get odmpid)"

##-------------------------------------##
## Added by Martinski W. [2025-Jun-09] ##
##-------------------------------------##
readonly scriptVersRegExp="v[0-9]{1,2}([.][0-9]{1,2})([.][0-9]{1,2})"
readonly webPageLineRegExp="(Scribe|uiScribe|uiscribe_version_server)"
readonly branchxStr_TAG="[Branch: $SCRIPT_BRANCH]"
readonly versionDev_TAG="${SCRIPT_VERSION}_${SCRIPT_VERSTAG}"
readonly versionMod_TAG="$SCRIPT_VERSION on $ROUTER_MODEL"

### End of script variables ###

### Start of output format variables ###
readonly CRIT="\\e[41m"
readonly ERR="\\e[31m"
readonly WARN="\\e[33m"
readonly PASS="\\e[32m"
readonly BOLD="\\e[1m"
readonly SETTING="${BOLD}\\e[36m"
readonly CLEARFORMAT="\\e[0m"
readonly GRNct="\e[1;32m"
readonly MGNTct="\e[1;35m"
readonly CLRct="\e[0m"
### End of output format variables ###

# Give priority to built-in binaries #
export PATH="/bin:/usr/bin:/sbin:/usr/sbin:$PATH"

##----------------------------------------##
## Modified by Martinski W. [2025-Jun-09] ##
##----------------------------------------##
# $1 = print to syslog, $2 = message to print, $3 = log level
Print_Output()
{
	local prioStr  prioNum
	if [ $# -gt 2 ] && [ -n "$3" ]
	then prioStr="$3"
	else prioStr="NOTICE"
	fi
	if [ "$1" = "true" ]
	then
		case "$prioStr" in
		    "$CRIT") prioNum=2 ;;
		     "$ERR") prioNum=3 ;;
		    "$WARN") prioNum=4 ;;
		    "$PASS") prioNum=6 ;; #INFO#
		          *) prioNum=5 ;; #NOTICE#
		esac
		logger -t "$SCRIPT_NAME" -p $prioNum "$2"
	fi
	printf "${BOLD}${3}%s${CLRct}\n" "$2"
	if [ $# -lt 4 ] || [ "$4" != "oneline" ]
	then echo ; fi
}

Firmware_Version_Check()
{
	if nvram get rc_support | grep -qF "am_addons"; then
		return 0
	else
		return 1
	fi
}

### Code for these functions inspired by https://github.com/Adamm00 - credit to @Adamm ###
Check_Lock()
{
	if [ -f "/tmp/$SCRIPT_NAME.lock" ]
	then
		ageoflock=$(($(date +%s) - $(date +%s -r /tmp/$SCRIPT_NAME.lock)))
		if [ "$ageoflock" -gt 600 ]
		then
			Print_Output true "Stale lock file found (>600 seconds old) - purging lock" "$ERR"
			kill "$(sed -n '1p' /tmp/$SCRIPT_NAME.lock)" >/dev/null 2>&1
			Clear_Lock
			echo "$$" > "/tmp/$SCRIPT_NAME.lock"
			return 0
		else
			Print_Output true "Lock file found (age: $ageoflock seconds) - stopping to prevent duplicate runs" "$ERR"
			if [ $# -eq 0 ] || [ -z "$1" ]
			then
				exit 1
			else
				return 1
			fi
		fi
	else
		echo "$$" > "/tmp/$SCRIPT_NAME.lock"
		return 0
	fi
}

Clear_Lock()
{
	rm -f "/tmp/$SCRIPT_NAME.lock" 2>/dev/null
	return 0
}

##----------------------------------------##
## Modified by Martinski W. [2025-Jun-09] ##
##----------------------------------------##
Set_Version_Custom_Settings()
{
	SETTINGSFILE="/jffs/addons/custom_settings.txt"
	case "$1" in
		local)
			if [ -f "$SETTINGSFILE" ]
			then
				if [ "$(grep -c "^uiscribe_version_local" $SETTINGSFILE)" -gt 0 ]
				then
					if [ "$2" != "$(grep "^uiscribe_version_local" "$SETTINGSFILE" | cut -f2 -d' ')" ]
					then
						sed -i "s/^uiscribe_version_local.*/uiscribe_version_local $2/" "$SETTINGSFILE"
					fi
				else
					echo "uiscribe_version_local $2" >> "$SETTINGSFILE"
				fi
			else
				echo "uiscribe_version_local $2" >> "$SETTINGSFILE"
			fi
		;;
		server)
			if [ -f "$SETTINGSFILE" ]
			then
				if [ "$(grep -c "^uiscribe_version_server" $SETTINGSFILE)" -gt 0 ]
				then
					if [ "$2" != "$(grep "^uiscribe_version_server" "$SETTINGSFILE" | cut -f2 -d' ')" ]
					then
						sed -i "s/^uiscribe_version_server.*/uiscribe_version_server $2/" "$SETTINGSFILE"
					fi
				else
					echo "uiscribe_version_server $2" >> "$SETTINGSFILE"
				fi
			else
				echo "uiscribe_version_server $2" >> "$SETTINGSFILE"
			fi
		;;
	esac
}

##----------------------------------------##
## Modified by Martinski W. [2025-Jun-09] ##
##----------------------------------------##
Update_Check()
{
	echo 'var updatestatus = "InProgress";' > "$SCRIPT_WEB_DIR/detect_update.js"
	doupdate="false"
	localver="$(grep "SCRIPT_VERSION=" "/jffs/scripts/$SCRIPT_NAME" | grep -m1 -oE "$scriptVersRegExp")"
	[ -n "$localver" ] && Set_Version_Custom_Settings local "$localver"
	curl -fsL --retry 4 --retry-delay 5 "$SCRIPT_REPO/$SCRIPT_NAME.sh" | grep -qF "jackyaz" || \
	{ Print_Output true "404 error detected - stopping update" "$ERR"; return 1; }
	serverver="$(curl -fsL --retry 4 --retry-delay 5 "$SCRIPT_REPO/$SCRIPT_NAME.sh" | grep "SCRIPT_VERSION=" | grep -m1 -oE "$scriptVersRegExp")"
	if [ "$localver" != "$serverver" ]
	then
		doupdate="version"
		Set_Version_Custom_Settings server "$serverver"
		echo 'var updatestatus = "'"$serverver"'";'  > "$SCRIPT_WEB_DIR/detect_update.js"
	else
		localmd5="$(md5sum "/jffs/scripts/$SCRIPT_NAME" | awk '{print $1}')"
		remotemd5="$(curl -fsL --retry 4 --retry-delay 5 "$SCRIPT_REPO/$SCRIPT_NAME.sh" | md5sum | awk '{print $1}')"
		if [ "$localmd5" != "$remotemd5" ]
		then
			doupdate="md5"
			Set_Version_Custom_Settings server "$serverver-hotfix"
			echo 'var updatestatus = "'"$serverver-hotfix"'";'  > "$SCRIPT_WEB_DIR/detect_update.js"
		fi
	fi
	if [ "$doupdate" = "false" ]; then
		echo 'var updatestatus = "None";'  > "$SCRIPT_WEB_DIR/detect_update.js"
	fi
	echo "$doupdate,$localver,$serverver"
}

##----------------------------------------##
## Modified by Martinski W. [2025-Jun-09] ##
##----------------------------------------##
Update_Version()
{
	if [ $# -eq 0 ] || [ -z "$1" ]
	then
		updatecheckresult="$(Update_Check)"
		isupdate="$(echo "$updatecheckresult" | cut -f1 -d',')"
		localver="$(echo "$updatecheckresult" | cut -f2 -d',')"
		serverver="$(echo "$updatecheckresult" | cut -f3 -d',')"

		if [ "$isupdate" = "version" ]; then
			Print_Output true "New version of $SCRIPT_NAME available - $serverver" "$PASS"
		elif [ "$isupdate" = "md5" ]; then
			Print_Output true "MD5 hash of $SCRIPT_NAME does not match - hotfix available - $serverver" "$PASS"
		fi

		if [ "$isupdate" != "false" ]
		then
			printf "\n${BOLD}Do you want to continue with the update? (y/n)${CLEARFORMAT}  "
			read -r confirm
			case "$confirm" in
				y|Y)
					printf "\n"
					Update_File shared-jy.tar.gz
					Update_File Main_LogStatus_Content.asp
					Download_File "$SCRIPT_REPO/$SCRIPT_NAME.sh" "/jffs/scripts/$SCRIPT_NAME" && \
					Print_Output true "$SCRIPT_NAME successfully updated" "$PASS"
					chmod 0755 "/jffs/scripts/$SCRIPT_NAME"
					Set_Version_Custom_Settings local "$serverver"
					Set_Version_Custom_Settings server "$serverver"
					Clear_Lock
					PressEnter
					exec "$0"
					exit 0
				;;
				*)
					printf "\n"
					Clear_Lock
					return 1
				;;
			esac
		else
			Print_Output true "No updates available - latest is $localver" "$WARN"
			Clear_Lock
		fi
	fi

	if [ "$1" = "force" ]
	then
		serverver="$(curl -fsL --retry 4 --retry-delay 5 "$SCRIPT_REPO/$SCRIPT_NAME.sh" | grep "SCRIPT_VERSION=" | grep -m1 -oE "$scriptVersRegExp")"
		Print_Output true "Downloading latest version ($serverver) of $SCRIPT_NAME" "$PASS"
		Update_File shared-jy.tar.gz
		Update_File Main_LogStatus_Content.asp
		Download_File "$SCRIPT_REPO/$SCRIPT_NAME.sh" "/jffs/scripts/$SCRIPT_NAME" && \
		Print_Output true "$SCRIPT_NAME successfully updated" "$PASS"
		chmod 0755 "/jffs/scripts/$SCRIPT_NAME"
		Set_Version_Custom_Settings local "$serverver"
		Set_Version_Custom_Settings server "$serverver"
		Clear_Lock
		if [ $# -lt 2 ] || [ -z "$2" ]
		then
			PressEnter
			exec "$0"
		elif [ "$2" = "unattended" ]
		then
			exec "$0" postupdate
		fi
		exit 0
	fi
}

##----------------------------------------##
## Modified by Martinski W. [2025-Jun-15] ##
##----------------------------------------##
Update_File()
{
	if [ "$1" = "Main_LogStatus_Content.asp" ]
	then
		tmpfile="/tmp/$1"
		if [ -f "$SCRIPT_DIR/$1" ]
		then
			Download_File "$SCRIPT_REPO/$1" "$tmpfile"
			if ! diff -q "$tmpfile" "$SCRIPT_DIR/$1" >/dev/null 2>&1
			then
				Download_File "$SCRIPT_REPO/$1" "$SCRIPT_DIR/$1"
				Print_Output true "New version of $1 downloaded" "$PASS"
				Mount_WebUI
			fi
			rm -f "$tmpfile"
		else
			Download_File "$SCRIPT_REPO/$1" "$SCRIPT_DIR/$1"
			Print_Output true "New version of $1 downloaded" "$PASS"
			Mount_WebUI
		fi
	elif [ "$1" = "shared-jy.tar.gz" ]
	then
		if [ ! -f "$SHARED_DIR/$1.md5" ]
		then
			Download_File "$SHARED_REPO/$1" "$SHARED_DIR/$1"
			Download_File "$SHARED_REPO/$1.md5" "$SHARED_DIR/$1.md5"
			tar -xzf "$SHARED_DIR/$1" -C "$SHARED_DIR"
			rm -f "$SHARED_DIR/$1"
			Print_Output true "New version of $1 downloaded" "$PASS"
		else
			localmd5="$(cat "$SHARED_DIR/$1.md5")"
			remotemd5="$(curl -fsL --retry 4 --retry-delay 5 "$SHARED_REPO/$1.md5")"
			if [ "$localmd5" != "$remotemd5" ]
			then
				Download_File "$SHARED_REPO/$1" "$SHARED_DIR/$1"
				Download_File "$SHARED_REPO/$1.md5" "$SHARED_DIR/$1.md5"
				tar -xzf "$SHARED_DIR/$1" -C "$SHARED_DIR"
				rm -f "$SHARED_DIR/$1"
				Print_Output true "New version of $1 downloaded" "$PASS"
			fi
		fi
	else
		return 1
	fi
}

Validate_Number()
{
	if [ "$1" -eq "$1" ] 2>/dev/null; then
		return 0
	else
		return 1
	fi
}

Create_Dirs()
{
	if [ ! -d "$SCRIPT_DIR" ]; then
		mkdir -p "$SCRIPT_DIR"
	fi

	if [ ! -d "$SHARED_DIR" ]; then
		mkdir -p "$SHARED_DIR"
	fi

	if [ ! -d "$SCRIPT_WEB_DIR" ]; then
		mkdir -p "$SCRIPT_WEB_DIR"
	fi
}

##----------------------------------------##
## Modified by Martinski W. [2025-Jun-15] ##
##----------------------------------------##
Create_Symlinks()
{
	if [ -z "$(which syslog-ng)" ]
	then
		Print_Output true "**ERROR**: syslog-ng is NOT found." "$CRIT"
		touch "$SCRIPT_DIR/.logs"
	else
		syslog-ng --preprocess-into="$SCRIPT_DIR/tmplogs.txt" && grep -A 1 "destination" "$SCRIPT_DIR/tmplogs.txt" | grep "file(\"" | grep -v "#" | grep -v "messages" | sed -e 's/file("//;s/".*$//' | awk '{$1=$1;print}' > "$SCRIPT_DIR/.logs"
		rm -f "$SCRIPT_DIR/tmplogs.txt" 2>/dev/null
	fi

	if [ $# -gt 0 ] && [ "$1" = "force" ]
	then
		rm -f "$SCRIPT_DIR/.logs_user"
	fi

	if [ ! -f "$SCRIPT_DIR/.logs_user" ]; then
		touch "$SCRIPT_DIR/.logs_user"
	fi

	while IFS='' read -r line || [ -n "$line" ]
	do
		if [ "$(grep -c "$line" "$SCRIPT_DIR/.logs_user")" -eq 0 ]; then
			printf "%s\\n" "$line" >> "$SCRIPT_DIR/.logs_user"
		fi
	done < "$SCRIPT_DIR/.logs"

	rm -f "$SCRIPT_WEB_DIR/"*.htm 2>/dev/null
	ln -s "$SCRIPT_DIR/.logs_user" "$SCRIPT_WEB_DIR/logs.htm" 2>/dev/null
	ln -s /opt/var/log/messages "$SCRIPT_WEB_DIR/messages.htm" 2>/dev/null
	while IFS='' read -r line || [ -n "$line" ]
	do
		ln -s "$line" "$SCRIPT_WEB_DIR/$(basename "$line").htm" 2>/dev/null
	done < "$SCRIPT_DIR/.logs"

	if [ ! -d "$SHARED_WEB_DIR" ]; then
		ln -s "$SHARED_DIR" "$SHARED_WEB_DIR" 2>/dev/null
	fi
}

Logs_FromSettings()
{
	SETTINGSFILE="/jffs/addons/custom_settings.txt"
	LOGS_USER="$SCRIPT_DIR/.logs_user"
	if [ -f "$SETTINGSFILE" ]
	then
		if grep -q "uiscribe_logs_enabled" "$SETTINGSFILE"
		then
			Print_Output true "Updated logs from WebUI found, merging into $LOGS_USER" "$PASS"
			cp -a "$LOGS_USER" "$LOGS_USER.bak"
			SETTINGVALUE="$(grep "uiscribe_logs_enabled" "$SETTINGSFILE" | cut -f2 -d' ')"
			sed -i "\\~uiscribe_logs_enabled~d" "$SETTINGSFILE"

			syslog-ng --preprocess-into="$SCRIPT_DIR/tmplogs.txt" && grep -A 1 "destination" "$SCRIPT_DIR/tmplogs.txt" | grep "file(\"" | grep -v "#" | grep -v "messages" | sed -e 's/file("//;s/".*$//' | awk '{$1=$1;print}' > "$SCRIPT_DIR/.logs"
			rm -f "$SCRIPT_DIR/tmplogs.txt" 2>/dev/null

			echo "" > "$LOGS_USER"

			comment=" #excluded#"
			while IFS='' read -r line || [ -n "$line" ]
			do
				if [ "$(grep -c "$line" "$LOGS_USER")" -eq 0 ]; then
						printf "%s%s\\n" "$line" "$comment" >> "$LOGS_USER"
				fi
			done < "$SCRIPT_DIR/.logs"

			for log in $(echo "$SETTINGVALUE" | sed "s/,/ /g")
			do
				loglinenumber="$(grep -n "$log" "$LOGS_USER" | cut -f1 -d':')"
				logline="$(sed "$loglinenumber!d" "$LOGS_USER" | awk '{$1=$1};1')"

				if echo "$logline" | grep -q "#excluded" ; then
					sed -i "$loglinenumber"'s/ #excluded#//' "$LOGS_USER"
				fi
			done

			awk 'NF' "$LOGS_USER" > /tmp/uiscribe-logs
			mv -f /tmp/uiscribe-logs "$LOGS_USER"

			rm -f "$SCRIPT_WEB_DIR/"*.htm 2>/dev/null
			ln -s "$SCRIPT_DIR/.logs_user" "$SCRIPT_WEB_DIR/logs.htm" 2>/dev/null
			ln -s /opt/var/log/messages "$SCRIPT_WEB_DIR/messages.htm" 2>/dev/null
			while IFS='' read -r line || [ -n "$line" ]
			do
				ln -s "$line" "$SCRIPT_WEB_DIR/$(basename "$line").htm" 2>/dev/null
			done < "$SCRIPT_DIR/.logs"

			Print_Output true "Merge of updated logs from WebUI completed successfully" "$PASS"
		else
			Print_Output true "No updated logs from WebUI found, no merge into $LOGS_USER necessary" "$PASS"
		fi
	fi
}

##----------------------------------------##
## Modified by Martinski W. [2025-Jun-18] ##
##----------------------------------------##
Generate_Log_List()
{
	ScriptHeader
	goback=false
	printf "Retrieving list of log files...\n\n"
	logCount="$(wc -l < "$SCRIPT_DIR/.logs_user")"
	COUNTER=1
	until [ "$COUNTER" -gt "$logCount" ]
	do
		logfile="$(sed "$COUNTER!d" "$SCRIPT_DIR/.logs_user" | awk '{$1=$1};1')"
		if [ "$COUNTER" -lt 10 ]; then
			printf "%s)  %s\n" "$COUNTER" "$logfile"
		else
			printf "%s) %s\n" "$COUNTER" "$logfile"
		fi
		COUNTER="$((COUNTER + 1))"
	done
	printf "\ne)  Go back\n"

	while true
	do
		printf "\n${BOLD}Please select a log to toggle inclusion in %s [1-%s]:${CLEARFORMAT}  " "$SCRIPT_NAME" "$logCount"
		read -r logNum

		if [ "$logNum" = "e" ]
		then
			goback=true
			break
		elif ! Validate_Number "$logNum"
		then
			printf "\n${ERR}Please enter a valid number [1-%s]${CLEARFORMAT}\n" "$logCount"
			PressEnter
			break
		else
			if [ "$logNum" -lt 1 ] || [ "$logNum" -gt "$logCount" ]
			then
				printf "\n${ERR}Please enter a number between 1 and %s${CLEARFORMAT}\n" "$logCount"
				PressEnter
				break
			else
				logLine="$(sed "$logNum!d" "$SCRIPT_DIR/.logs_user" | awk '{$1=$1};1')"
				if echo "$logLine" | grep -q "#excluded#"
				then
					sed -i "$logNum"'s/ #excluded#//' "$SCRIPT_DIR/.logs_user"
				else
					sed -i "$logNum"'s/$/ #excluded#/' "$SCRIPT_DIR/.logs_user"
				fi
				sed -i 's/ *$//' "$SCRIPT_DIR/.logs_user"
				printf "\n"
				break
			fi
		fi
	done

	if [ "$goback" != "true" ]; then
		Generate_Log_List
	fi
}

##----------------------------------------##
## Modified by Martinski W. [2025-Jun-18] ##
##----------------------------------------##
Auto_ServiceEvent()
{
	local theScriptFilePath="/jffs/scripts/$SCRIPT_NAME"
	case $1 in
		create)
			if [ -f /jffs/scripts/service-event ]
			then
				STARTUPLINECOUNT="$(grep -c '# '"$SCRIPT_NAME" /jffs/scripts/service-event)"
				STARTUPLINECOUNTEX="$(grep -cx 'if echo "$2" | /bin/grep -q "'"$SCRIPT_NAME"'"; then { '"$theScriptFilePath"' service_event "$@" & }; fi # '"$SCRIPT_NAME" /jffs/scripts/service-event)"

				if [ "$STARTUPLINECOUNT" -gt 1 ] || { [ "$STARTUPLINECOUNTEX" -eq 0 ] && [ "$STARTUPLINECOUNT" -gt 0 ]; }
				then
					sed -i -e '/# '"$SCRIPT_NAME"'/d' /jffs/scripts/service-event
				fi

				if [ "$STARTUPLINECOUNTEX" -eq 0 ]
				then
					{
					  echo 'if echo "$2" | /bin/grep -q "'"$SCRIPT_NAME"'"; then { '"$theScriptFilePath"' service_event "$@" & }; fi # '"$SCRIPT_NAME" 
					} >> /jffs/scripts/service-event
				fi
			else
				{
				  echo "#!/bin/sh" ; echo
				  echo 'if echo "$2" | /bin/grep -q "'"$SCRIPT_NAME"'"; then { '"$theScriptFilePath"' service_event "$@" & }; fi # '"$SCRIPT_NAME"
				  echo
				} > /jffs/scripts/service-event
				chmod 0755 /jffs/scripts/service-event
			fi
		;;
		delete)
			if [ -f /jffs/scripts/service-event ]
			then
				STARTUPLINECOUNT="$(grep -c '# '"$SCRIPT_NAME" /jffs/scripts/service-event)"
				if [ "$STARTUPLINECOUNT" -gt 0 ]
				then
					sed -i -e '/# '"$SCRIPT_NAME"'/d' /jffs/scripts/service-event
				fi
			fi
		;;
	esac
}

##----------------------------------------##
## Modified by Martinski W. [2025-Jun-27] ##
##----------------------------------------##
Auto_Startup()
{
	local theScriptFilePath="/jffs/scripts/$SCRIPT_NAME"
	case $1 in
		create)
			if [ -f /jffs/scripts/services-start ]
			then
				STARTUPLINECOUNT="$(grep -c '# '"$SCRIPT_NAME" /jffs/scripts/services-start)"
				if [ "$STARTUPLINECOUNT" -gt 0 ]
				then
					sed -i -e '/# '"$SCRIPT_NAME"'/d' /jffs/scripts/services-start
				fi
			fi
			if [ -f /jffs/scripts/post-mount ]
			then
				STARTUPLINECOUNT="$(grep -c '# '"$SCRIPT_NAME" /jffs/scripts/post-mount)"
				STARTUPLINECOUNTEX="$(grep -cx '\[ -x "${1}/entware/bin/opkg" \] && \[ -x '"$theScriptFilePath"' \] && '"$theScriptFilePath"' startup "$@" & # '"$SCRIPT_NAME" /jffs/scripts/post-mount)"

				if [ "$STARTUPLINECOUNT" -gt 1 ] || { [ "$STARTUPLINECOUNTEX" -eq 0 ] && [ "$STARTUPLINECOUNT" -gt 0 ]; }
				then
					sed -i -e '/# '"$SCRIPT_NAME"'/d' /jffs/scripts/post-mount
				fi

				if [ "$STARTUPLINECOUNTEX" -eq 0 ]
				then
					{
					  echo '[ -x "${1}/entware/bin/opkg" ] && [ -x '"$theScriptFilePath"' ] && '"$theScriptFilePath"' startup "$@" & # '"$SCRIPT_NAME"
					} >> /jffs/scripts/post-mount
				fi
			else
				{
				  echo "#!/bin/sh" ; echo
				  echo '[ -x "${1}/entware/bin/opkg" ] && [ -x '"$theScriptFilePath"' ] && '"$theScriptFilePath"' startup "$@" & # '"$SCRIPT_NAME"
				  echo
				} > /jffs/scripts/post-mount
				chmod 0755 /jffs/scripts/post-mount
			fi
		;;
		delete)
			if [ -f /jffs/scripts/services-start ]
			then
				STARTUPLINECOUNT="$(grep -c '# '"$SCRIPT_NAME" /jffs/scripts/services-start)"
				if [ "$STARTUPLINECOUNT" -gt 0 ]
				then
					sed -i -e '/# '"$SCRIPT_NAME"'/d' /jffs/scripts/services-start
				fi
			fi
			if [ -f /jffs/scripts/post-mount ]
			then
				STARTUPLINECOUNT="$(grep -c '# '"$SCRIPT_NAME" /jffs/scripts/post-mount)"
				if [ "$STARTUPLINECOUNT" -gt 0 ]
				then
					sed -i -e '/# '"$SCRIPT_NAME"'/d' /jffs/scripts/post-mount
				fi
			fi
		;;
	esac
}

##----------------------------------------##
## Modified by Martinski W. [2025-Jun-09] ##
##----------------------------------------##
Download_File()
{ /usr/sbin/curl -LSs --retry 4 --retry-delay 5 --retry-connrefused "$1" -o "$2" ; }

##-------------------------------------##
## Added by Martinski W. [2025-Jun-15] ##
##-------------------------------------##
_Check_WebGUI_Page_Exists_()
{
   local webPageCnt  retCode
   local wwwWebPageFilePath  scriptPageFilePath

   wwwWebPageFilePath="/www/Main_LogStatus_Content.asp"
   scriptPageFilePath="$SCRIPT_DIR/Main_LogStatus_Content.asp"

   if [ ! -s "$scriptPageFilePath" ] || \
      [ ! -s "$wwwWebPageFilePath" ] || \
      ! diff "$scriptPageFilePath" "$wwwWebPageFilePath" >/dev/null 2>&1
   then return 1
   fi

   webPageCnt="$(grep -Ec "$webPageLineRegExp" "$wwwWebPageFilePath")"
   if [ "$webPageCnt" -gt 3 ]
   then retCode=0
   else retCode=1
   fi
   return "$retCode"
}

### function based on @dave14305's FlexQoS webconfigpage function ###
##----------------------------------------##
## Modified by Martinski W. [2025-Jun-15] ##
##----------------------------------------##
Get_WebUI_URL()
{
	local preURL  urlProto  urlDomain  urlPort  lanPort

	if ! _Check_WebGUI_Page_Exists_
	then
		Print_Output false "**ERROR**: WebUI page NOT found" "$ERR"
		return 1
	fi

	if [ "$(nvram get http_enable)" -eq 1 ]; then
		urlProto="https"
	else
		urlProto="http"
	fi
	if [ -n "$(nvram get lan_domain)" ]; then
		urlDomain="$(nvram get lan_hostname).$(nvram get lan_domain)"
	else
		urlDomain="$(nvram get lan_ipaddr)"
	fi

	lanPort="$(nvram get ${urlProto}_lanport)"
	if [ "$lanPort" -eq 80 ] || [ "$lanPort" -eq 443 ]
	then
		urlPort=""
	else
		urlPort=":$lanPort"
	fi

	preURL="$(echo "${urlProto}://${urlDomain}${urlPort}" | tr "A-Z" "a-z")"
	echo "${preURL}/Main_LogStatus_Content.asp"
}

##----------------------------------------##
## Modified by Martinski W. [2025-Jun-27] ##
##----------------------------------------##
Mount_WebUI()
{
	local wwwWebPageFilePath  scriptPageFilePath
	wwwWebPageFilePath="/www/Main_LogStatus_Content.asp"
	scriptPageFilePath="$SCRIPT_DIR/Main_LogStatus_Content.asp"

	Print_Output true "Mounting WebUI tab for $SCRIPT_NAME" "$PASS" oneline
	if [ ! -s "$scriptPageFilePath" ]
	then
		Print_Output true "**ERROR1**: Unable to mount $SCRIPT_NAME WebUI page." "$CRIT"
		return 1
	fi
	if [ ! -s "$wwwWebPageFilePath" ]
	then
		Print_Output true "**ERROR2**: Unable to mount $SCRIPT_NAME WebUI page." "$CRIT"
		return 1
	fi

	umount "$wwwWebPageFilePath" 2>/dev/null
	mount -o bind "$scriptPageFilePath" "$wwwWebPageFilePath"
	Print_Output true "Mounted $SCRIPT_NAME WebUI page as Main_LogStatus_Content.asp" "$PASS"
}

##-------------------------------------##
## Added by Martinski W. [2025-Jun-15] ##
##-------------------------------------##
_CheckFor_WebGUI_Page_()
{
   if ! _Check_WebGUI_Page_Exists_
   then Mount_WebUI ; fi
}

Shortcut_Script()
{
	case $1 in
		create)
			if [ -d /opt/bin ] && [ ! -f "/opt/bin/$SCRIPT_NAME" ] && [ -f "/jffs/scripts/$SCRIPT_NAME" ]
			then
				ln -s "/jffs/scripts/$SCRIPT_NAME" /opt/bin
				chmod 0755 "/opt/bin/$SCRIPT_NAME"
			fi
		;;
		delete)
			if [ -f "/opt/bin/$SCRIPT_NAME" ]; then
				rm -f "/opt/bin/$SCRIPT_NAME"
			fi
		;;
	esac
}

PressEnter()
{
	while true
	do
		printf "Press <Enter> key to continue..."
		read -rs key
		case "$key" in
			*) break ;;
		esac
	done
	return 0
}

##-------------------------------------##
## Added by Martinski W. [2025-Aug-23] ##
##-------------------------------------##
_CenterTextStr_()
{
    if [ $# -lt 2 ] || [ -z "$1" ] || [ -z "$2" ] || \
       ! echo "$2" | grep -qE "^[1-9][0-9]+$"
    then echo ; return 1
    fi
    local stringLen="${#1}"
    local space1Len="$((($2 - stringLen)/2))"
    local space2Len="$space1Len"
    local totalLen="$((space1Len + stringLen + space2Len))"

    if [ "$totalLen" -lt "$2" ]
    then space2Len="$((space2Len + 1))"
    elif [ "$totalLen" -gt "$2" ]
    then space1Len="$((space1Len - 1))"
    fi
    if [ "$space1Len" -gt 0 ] && [ "$space2Len" -gt 0 ]
    then printf "%*s%s%*s" "$space1Len" '' "$1" "$space2Len" ''
    else printf "%s" "$1"
    fi
}

##----------------------------------------##
## Modified by Martinski W. [2025-Aug-23] ##
##----------------------------------------##
ScriptHeader()
{
	clear
	local spaceLen=50
	printf "\n"
	printf "${BOLD}########################################################${CLRct}\n"
	printf "${BOLD}##                                                    ##${CLRct}\n"
	printf "${BOLD}##           _   _____              _  _              ##${CLRct}\n"
	printf "${BOLD}##          (_) / ____|            (_)| |             ##${CLRct}\n"
	printf "${BOLD}##    _   _  _ | (___    ___  _ __  _ | |__    ___    ##${CLRct}\n"
	printf "${BOLD}##   | | | || | \___ \  / __|| '__|| || '_ \  / _ \   ##${CLRct}\n"
	printf "${BOLD}##   | |_| || | ____) || (__ | |   | || |_) ||  __/   ##${CLRct}\n"
	printf "${BOLD}##    \__,_||_||_____/  \___||_|   |_||_.__/  \___|   ##${CLRct}\n"
	printf "${BOLD}##                                                    ##${CLRct}\n"
	printf "${BOLD}## ${GRNct}%s${CLRct}${BOLD} ##${CLRct}\n" "$(_CenterTextStr_ "$versionMod_TAG" "$spaceLen")"
	printf "${BOLD}## ${GRNct}%s${CLRct}${BOLD} ##${CLRct}\n" "$(_CenterTextStr_ "$branchxStr_TAG" "$spaceLen")"
	printf "${BOLD}##        https://github.com/AMTM-OSR/uiScribe        ##${CLRct}\n"
	printf "${BOLD}##  Forked from https://github.com/jackyaz/uiScribe   ##${CLRct}\n"
	printf "${BOLD}##                                                    ##${CLRct}\n"
	printf "${BOLD}########################################################${CLRct}\n\n"
}

##----------------------------------------##
## Modified by Martinski W. [2025-Jun-18] ##
##----------------------------------------##
MainMenu()
{
	Create_Dirs
	Create_Symlinks
	printf "WebUI for %s is available at:\n${SETTING}%s${CLEARFORMAT}\n\n" "$SCRIPT_NAME" "$(Get_WebUI_URL)"

	printf "1.    Customise list of logs displayed by %s\n\n" "$SCRIPT_NAME"
	printf "rf.   Clear user preferences for displayed logs\n\n"
	printf "u.    Check for updates\n"
	printf "uf.   Force update %s with latest version\n\n" "$SCRIPT_NAME"
	printf "e.    Exit %s\n\n" "$SCRIPT_NAME"
	printf "z.    Uninstall %s\n" "$SCRIPT_NAME"
	printf "\n"
	printf "${BOLD}########################################################${CLEARFORMAT}\n"
	printf "\n"

	while true
	do
		printf "Choose an option:  "
		read -r menuOption
		case "$menuOption" in
			1)
				if Check_Lock menu
				then
					Generate_Log_List
					printf "\n"
					Clear_Lock
				fi
				PressEnter
				break
			;;
			rf)
				if Check_Lock menu
				then
					Create_Symlinks force
					printf "\n"
					Clear_Lock force
				fi
				PressEnter
				break
			;;
			u)
				printf "\n"
				if Check_Lock menu
				then
					Update_Version
					Clear_Lock
				fi
				PressEnter
				break
			;;
			uf)
				printf "\n"
				if Check_Lock menu
				then
					Update_Version force
					Clear_Lock
				fi
				PressEnter
				break
			;;
			e)
				ScriptHeader
				printf "\n${BOLD}Thanks for using %s!${CLEARFORMAT}\n\n\n" "$SCRIPT_NAME"
				exit 0
			;;
			z)
				while true
				do
					printf "\n${BOLD}Are you sure you want to uninstall %s? (y/n)${CLEARFORMAT}  " "$SCRIPT_NAME"
					read -r confirm
					case "$confirm" in
						y|Y)
							Menu_Uninstall
							exit 0
						;;
						*)
							break
						;;
					esac
				done
				break
			;;
			*)
				[ -n "$menuOption" ] && \
				printf "\n${ERR}INVALID input [$menuOption]${CLEARFORMAT}"
				printf "\nPlease choose a valid option.\n\n"
				PressEnter
				break
			;;
		esac
	done

	ScriptHeader
	MainMenu
}

Check_Requirements()
{
	CHECKSFAILED="false"

	if [ "$(nvram get jffs2_scripts)" -ne 1 ]
	then
		nvram set jffs2_scripts=1
		nvram commit
		Print_Output true "Custom JFFS Scripts enabled" "$WARN"
	fi

	if [ ! -f /opt/bin/opkg ]
	then
		Print_Output false "Entware is NOT detected!" "$ERR"
		CHECKSFAILED="true"
	fi

	if [ ! -f /opt/bin/scribe ]
	then
		Print_Output false "Scribe is NOT installed!" "$ERR"
		CHECKSFAILED="true"
	fi

	if ! Firmware_Version_Check
	then
		Print_Output false "Unsupported firmware version detected" "$ERR"
		Print_Output false "$SCRIPT_NAME requires Merlin 384.15/384.13_4 or Fork 43E5 (or later)" "$ERR"
		CHECKSFAILED="true"
	fi

	if [ "$CHECKSFAILED" = "false" ]; then
		return 0
	else
		return 1
	fi
}

##----------------------------------------##
## Modified by Martinski W. [2025-Jun-09] ##
##----------------------------------------##
Menu_Install()
{
	ScriptHeader
	Print_Output true "Welcome to $SCRIPT_NAME $SCRIPT_VERSION, a script by JackYaz" "$PASS"
	sleep 1

	Print_Output false "Checking your router meets the requirements for $SCRIPT_NAME" "$PASS"

	if ! Check_Requirements
	then
		Print_Output false "Requirements for $SCRIPT_NAME not met, please see above for the reason(s)" "$CRIT"
		PressEnter ; echo
		Clear_Lock
		rm -f "/jffs/scripts/$SCRIPT_NAME" 2>/dev/null
		exit 1
	fi

	Create_Dirs
	Set_Version_Custom_Settings local "$SCRIPT_VERSION"
	Set_Version_Custom_Settings server "$SCRIPT_VERSION"
	Create_Symlinks
	Update_File Main_LogStatus_Content.asp
	Update_File shared-jy.tar.gz
	Auto_Startup create 2>/dev/null
	Auto_ServiceEvent create 2>/dev/null
	Shortcut_Script create

	Print_Output true "$SCRIPT_NAME installed successfully!" "$PASS"

	Clear_Lock
}

##----------------------------------------##
## Modified by Martinski W. [2025-Jun-09] ##
##----------------------------------------##
Menu_Startup()
{
	if [ -z "$PPID" ] || ! ps | grep "$PPID" | grep -iq "scribe"
	then
		if [ $# -eq 0 ] || [ -z "$1" ]
		then
			Print_Output true "Missing argument for startup, not starting $SCRIPT_NAME" "$ERR"
			exit 1
		elif [ "$1" != "force" ]
		then
			if [ ! -f "$1/entware/bin/opkg" ]
			then
				Print_Output true "$1 does NOT contain Entware, not starting $SCRIPT_NAME" "$CRIT"
				exit 1
			else
				Print_Output true "$1 contains Entware, $SCRIPT_NAME $SCRIPT_VERSION starting up" "$WARN"
			fi
		fi
	fi

	NTP_Ready
	Check_Lock
	Create_Dirs
	Create_Symlinks
	Auto_Startup create 2>/dev/null
	Auto_ServiceEvent create 2>/dev/null
	Shortcut_Script create
	Mount_WebUI
	Clear_Lock
}

Menu_Uninstall()
{
	Print_Output true "Removing $SCRIPT_NAME..." "$PASS"
	Auto_Startup delete 2>/dev/null
	Auto_ServiceEvent delete 2>/dev/null
	Shortcut_Script delete
	umount /www/Main_LogStatus_Content.asp 2>/dev/null
	rm -rf "$SCRIPT_DIR" 2>/dev/null
	rm -rf "$SCRIPT_WEB_DIR" 2>/dev/null
	SETTINGSFILE="/jffs/addons/custom_settings.txt"
	sed -i '/uiscribe_version_local/d' "$SETTINGSFILE"
	sed -i '/uiscribe_version_server/d' "$SETTINGSFILE"
	rm -f "/jffs/scripts/$SCRIPT_NAME" 2>/dev/null
	Clear_Lock
	Print_Output true "Uninstall completed" "$PASS"
}

##----------------------------------------##
## Modified by Martinski W. [2025-Jul-27] ##
##----------------------------------------##
NTP_Ready()
{
	local theSleepDelay=15  ntpMaxWaitSecs=600  ntpWaitSecs

	if [ "$(nvram get ntp_ready)" -eq 0 ]
	then
		Check_Lock
		ntpWaitSecs=0
		Print_Output true "Waiting for NTP to sync..." "$WARN"

		while [ "$(nvram get ntp_ready)" -eq 0 ] && [ "$ntpWaitSecs" -lt "$ntpMaxWaitSecs" ]
		do
			if [ "$ntpWaitSecs" -gt 0 ] && [ "$((ntpWaitSecs % 30))" -eq 0 ]
			then
			    Print_Output true "Waiting for NTP to sync [$ntpWaitSecs secs]..." "$WARN"
			fi
			sleep "$theSleepDelay"
			ntpWaitSecs="$((ntpWaitSecs + theSleepDelay))"
		done

		if [ "$ntpWaitSecs" -ge "$ntpMaxWaitSecs" ]
		then
			Print_Output true "NTP failed to sync after 10 minutes. Please resolve!" "$CRIT"
			Clear_Lock
			exit 1
		else
			Print_Output true "NTP has synced [$ntpWaitSecs secs]. $SCRIPT_NAME will now continue." "$PASS"
			Clear_Lock
		fi
	fi
}

### function based on @Adamm00's Skynet USB wait function ###
##----------------------------------------##
## Modified by Martinski W. [2025-Jul-27] ##
##----------------------------------------##
Entware_Ready()
{
	local theSleepDelay=5  maxSleepTimer=120  sleepTimerSecs

	if [ ! -f /opt/bin/opkg ]
	then
		Check_Lock
		sleepTimerSecs=0

		while [ ! -f /opt/bin/opkg ] && [ "$sleepTimerSecs" -lt "$maxSleepTimer" ]
		do
			if [ "$((sleepTimerSecs % 10))" -eq 0 ]
			then
			    Print_Output true "Entware NOT found. Wait for Entware to be ready [$sleepTimerSecs secs]..." "$WARN"
			fi
			sleep "$theSleepDelay"
			sleepTimerSecs="$((sleepTimerSecs + theSleepDelay))"
		done

		if [ ! -f /opt/bin/opkg ]
		then
			Print_Output true "Entware NOT found and is required for $SCRIPT_NAME to run, please resolve!" "$CRIT"
			Clear_Lock
			exit 1
		else
			Print_Output true "Entware found [$sleepTimerSecs secs]. $SCRIPT_NAME will now continue." "$PASS"
			Clear_Lock
		fi
	fi
}

### function based on @dave14305's FlexQoS about function ###
##----------------------------------------##
## Modified by Martinski W. [2025-Jul-09] ##
##----------------------------------------##
Show_About()
{
	printf "About ${MGNTct}${SCRIPT_VERS_INFO}${CLRct}\n"
	cat <<EOF
  $SCRIPT_NAME updates the System Log page to show log files created
  by Scribe (syslog-ng). Requires Scribe https://github.com/AMTM-OSR/scribe

License
  $SCRIPT_NAME is free to use under the GNU General Public License
  version 3 (GPL-3.0) https://opensource.org/licenses/GPL-3.0

Help & Support
  https://www.snbforums.com/forums/asuswrt-merlin-addons.60/?prefix_id=24

Source code
  https://github.com/AMTM-OSR/$SCRIPT_NAME
EOF
	printf "\n"
}

### function based on @dave14305's FlexQoS show_help function ###
##----------------------------------------##
## Modified by Martinski W. [2025-Jul-09] ##
##----------------------------------------##
Show_Help()
{
	printf "HELP ${MGNTct}${SCRIPT_VERS_INFO}${CLRct}\n"
	cat <<EOF
Available commands:
  $SCRIPT_NAME about            explains functionality
  $SCRIPT_NAME update           checks for updates
  $SCRIPT_NAME forceupdate      updates to latest version (force update)
  $SCRIPT_NAME startup force    runs startup actions such as mount WebUI tab
  $SCRIPT_NAME install          installs script
  $SCRIPT_NAME uninstall        uninstalls script
  $SCRIPT_NAME develop          switch to development branch version
  $SCRIPT_NAME stable           switch to stable/production branch version
EOF
	printf "\n"
}

##-------------------------------------##
## Added by Martinski W. [2025-Jun-09] ##
##-------------------------------------##
if [ "$SCRIPT_BRANCH" = "master" ]
then SCRIPT_VERS_INFO=""
else SCRIPT_VERS_INFO="[$versionDev_TAG]"
fi

##----------------------------------------##
## Modified by Martinski W. [2025-Jun-15] ##
##----------------------------------------##
if [ $# -eq 0 ] || [ -z "$1" ]
then
	NTP_Ready
	Entware_Ready
	sed -i '/\/dev\/null/d' "$SCRIPT_DIR/.logs_user"
	Create_Dirs
	Create_Symlinks
	Auto_Startup create 2>/dev/null
	Auto_ServiceEvent create 2>/dev/null
	Shortcut_Script create
	_CheckFor_WebGUI_Page_
	ScriptHeader
	MainMenu
	exit 0
fi

##----------------------------------------##
## Modified by Martinski W. [2025-Jun-27] ##
##----------------------------------------##
case "$1" in
	install)
		Check_Lock
		Menu_Install
		exit 0
	;;
	startup)
		shift
		Menu_Startup "$@"
		exit 0
	;;
	service_event)
		if [ "$2" = "start" ] && [ "$3" = "${SCRIPT_NAME}config" ]
		then
			Logs_FromSettings
		elif [ "$2" = "start" ] && [ "$3" = "${SCRIPT_NAME}checkupdate" ]
		then
			Update_Check
		elif [ "$2" = "start" ] && [ "$3" = "${SCRIPT_NAME}doupdate" ]
		then
			Update_Version force unattended
		fi
		exit 0
	;;
	update)
		Update_Version
		exit 0
	;;
	forceupdate)
		Update_Version force
		exit 0
	;;
	setversion)
		sed -i '/\/dev\/null/d' "$SCRIPT_DIR/.logs_user"
		Create_Dirs
		Create_Symlinks
		Auto_Startup create 2>/dev/null
		Auto_ServiceEvent create 2>/dev/null
		Shortcut_Script create
		Set_Version_Custom_Settings local "$SCRIPT_VERSION"
		Set_Version_Custom_Settings server "$SCRIPT_VERSION"
		exit 0
	;;
	postupdate)
		sed -i '/\/dev\/null/d' "$SCRIPT_DIR/.logs_user"
		Create_Dirs
		Create_Symlinks
		Auto_Startup create 2>/dev/null
		Auto_ServiceEvent create 2>/dev/null
		Shortcut_Script create
		exit 0
	;;
	about)
		ScriptHeader
		Show_About
		exit 0
	;;
	help)
		ScriptHeader
		Show_Help
		exit 0
	;;
	develop)
		SCRIPT_BRANCH="develop"
		SCRIPT_REPO="https://raw.githubusercontent.com/AMTM-OSR/$SCRIPT_NAME/$SCRIPT_BRANCH"
		Update_Version force
		exit 0
	;;
	stable)
		SCRIPT_BRANCH="master"
		SCRIPT_REPO="https://raw.githubusercontent.com/AMTM-OSR/$SCRIPT_NAME/$SCRIPT_BRANCH"
		Update_Version force
		exit 0
	;;
	uninstall)
		Menu_Uninstall
		exit 0
	;;
	*)
		ScriptHeader
		Print_Output false "Parameter [$*] is NOT recognised." "$ERR"
		Print_Output false "For a list of available commands run: $SCRIPT_NAME help" "$SETTING"
		exit 1
	;;
esac
