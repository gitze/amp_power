#! /bin/sh
PATH='/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'

#UPDATE
UpdateServerURL="http://diskstation/amp_power/"
UpdateVersionFile="amp_power.version"
UpdateScriptFile="amp_power"

#Logging
debuglogfile="/mnt/mmcblk0p2/tce/amp_power/"$$.log
#exec > $debuglogfile 2>&1
MasterLogfile="/mnt/mmcblk0p2/tce/amp_power/amp_power.log"

# set verbose level to info
__VERBOSE=6
# declare -A LOG_LEVELS
# https://en.wikipedia.org/wiki/Syslog#Severity_level
# LOG_LEVELS=([0]="emerg" [1]="alert" [2]="crit" [3]="err" [4]="warning" [5]="notice" [6]="info" [7]="debug")


#GPIO / AMP Management
NextAction="AUS"
Action="AUS"
WaitTillExec=0
LastStatus=0
Status=-1
PORT=4
PowerOffDelay=10


#Network Test & Reboot
Gateway=1.1.1.1
PingIP2=8.8.8.8
PingIP3=8.8.4.4
counter=0
START_TIME=0
MAX_TIME=60

LogIt () {
  local LEVEL=${1}
  shift
  if [ ${__VERBOSE} -ge ${LEVEL} ]; then
	timestamp=`date "+%Y-%m-%d %H:%M:%S"`
	echo $timestamp":" $@
	echo $timestamp":" $@ >> $MasterLogfile
  fi
}

InitGateway() {
	LogIt 5 "InitGateway"
    Gateway=`route -n | awk '$1 == "0.0.0.0"{print$2}'|head -1`
    LogIt 5 "Network: Detected Gateway: $Gateway"
}

checkNetwork(){
	[ "$Gateway" == "" ] && InitGateway
	ping -q -w 1 -c 1 "$Gateway" > /dev/null && GWPing=0 || GWPing=1
    [ "$GWPing" -eq 0 ] && LogIt 7 "Network: Gateway OK" && START_TIME=0 && return || LogIt 6 "Network: Gateway not reachable"

    # Double Check with external IP
    extIP=$PingIP2
    ping -q -w 1 -c 1 $extIP > /dev/null && IPPing=0 || IPPing=1
    [ "$IPPing" -eq 0 ] && LogIt 6 "Network: $extIP OK, refresh Gateway" && InitGateway && START_TIME=0 && return || LogIt 6 "Network: $extIP not reachable"

    extIP=$PingIP3
    ping -q -w 1 -c 1 $extIP > /dev/null && IPPing=0 || IPPing=1
    [ "$IPPing" -eq 0 ] && LogIt 6 "Network: $extIP OK, refresh Gateway" && InitGateway && START_TIME=0 && return || LogIt 6 "Network: $extIP not reachable"

    [ $START_TIME -eq 0 ] && START_TIME=`echo $(($(date +%s)))`
    END_TIME=`echo $(($(date +%s)))`
    ELAPSED_TIME=$(($END_TIME - $START_TIME))

#    [ "$ELAPSED_TIME" -gt 60 ]  && reboot || LogIt "Network: Network error since $ELAPSED_TIME seconds (Reboot after $MAX_TIME seconds without connection)"
    [ "$ELAPSED_TIME" -gt 60 ]  && Logit 2 "REBOOT!!!!" || LogIt 4 "Network: Network error since $ELAPSED_TIME seconds (Reboot after $MAX_TIME seconds without connection)"
}



InitGPIO(){
	LogIt 5 "InitGPIO"
   if ! [ -d /sys/class/gpio/gpio$PORT ]
   then
      echo "$PORT" > /sys/class/gpio/export
      echo "out" > /sys/class/gpio/gpio$PORT/direction
   fi
   echo 1 > /sys/class/gpio/gpio$PORT/value
	#/usr/local/bin/gpio -g write 4 1
	#/usr/local/bin/gpio -g mode 4 out
	##/usr/local/bin/gpio -g write 4 1
}



checkSound(){
	Status=`cat /proc/asound/card*/pcm*/sub*/status | grep -c RUNNING`

	# Cleanup Status Value to (0/1)
	[ $Status -ne 0 ] && Status=1

	if [ "$Status" != "$LastStatus" ]
	then
		if [ $Status -eq 0 ]
		then
			LogIt 6 "Amplifier: auf AUS gedrückt. (Delay: $PowerOffDelay Zyklen)"
			WaitTillExec=$PowerOffDelay
			NextAction="AUS"
		else
			LogIt 6 "Amplifier: auf AN  gedrückt"
        		WaitTillExec=1
			NextAction="AN"
		fi
	fi
	LogIt 7 "Amplifier: Aktion: $NextAction, warte $WaitTillExec Runden"
	LastStatus=$Status

	if [ $WaitTillExec -ne 0 ]
	then
		LogIt 7 "Amplifier: Running Countdown ..."
		WaitTillExec=$((WaitTillExec-1))
		Action=$NextAction
	fi

	case "$Action$WaitTillExec" in
      "AUS0")	echo 1 > /sys/class/gpio/gpio$PORT/value; LogIt 6 "Power Off";Action="";;
      "AN0")	echo 0 > /sys/class/gpio/gpio$PORT/value; LogIt 6 "Power On";Action="";;
	#"AUS0")	/usr/local/bin/gpio -g write 4 1 ;LogIt "Amplifier: Power Off";Action="";;
	#"AN0")	/usr/local/bin/gpio -g write 4 0 ;LogIt "Amplifier: Power On";Action="";;
	esac
}

######################################################
###### SelfUpdate
###### Thx to script from:
###### http://stackoverflow.com/questions/8595751/is-this-a-valid-self-update-approach-for-a-bash-script
######################################################
runSelfUpdate() {
  LogIt 5 "Performing self-update..."

  # Download new version
  echo -n "Downloading latest version..."
  if ! wget --quiet --output-document="$0.tmp" $UpdateServerURL/$SELF ; then
    echo "Failed: Error while trying to wget new version!"
    echo "File requested: $UpdateServerURL/$SELF"
    exit 1
  fi
  echo "Done."

  # Copy over modes from old version
  OCTAL_MODE=$(stat -c '%a' $SELF)
  if ! chmod $OCTAL_MODE "$0.tmp" ; then
    echo "Failed: Error while trying to set mode on $0.tmp."
    exit 1
  fi

  # Spawn update script
  cat > /tmp/updateScript.sh << EOF
#!/bin/bash
# Overwrite old file with new
if mv "$0.tmp" "$0"; then
  echo "Done. Update complete."
  rm \$0
else
  echo "Failed!"
fi
EOF

  echo -n "Inserting update process..."
  exec /bin/bash /tmp/updateScript.sh
}


######################################################
###### Main
######################################################
if [ "$1" == "update" ]
then
	LogIt 5 "Update:  $UpdateServerURL$UpdateScriptFile > /mnt/mmcblk0p2/tce/amp_power/amp_power"
	echo "Starting Update"
	wget -q -O - $UpdateServerURL$UpdateScriptFile > /mnt/mmcblk0p2/tce/amp_power/amp_power
	exit
fi

InitGateway
InitGPIO


# Loop
while [ 1 -eq 1 ]
do
	checkSound
	checkNetwork
	sleep 0.5
done
