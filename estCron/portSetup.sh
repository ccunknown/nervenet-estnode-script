#! /bin/bash

echo "script start ..."

DIR="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
CONFIG_PATH="$DIR/config.sh"

echo "Load Config: $CONFIG_PATH"
# Load Config.
echo "> load config"
source $CONFIG_PATH

_BLACK_='\033[0;30m'
_RED_='\033[0;31m'
_GREEN_='\033[0;32m'
_ORANGE_='\033[0;33m'
_BLUE_='\033[0;34m'
_PURPLE_='\033[0;35m'
_CYAN_='\033[0;36m'
_GRAY_='\033[0;37m'
_NC_='\033[0m'

function selectDev {
  local -n devPathRef=$1

  IFS=$'\n' read -a ttyList -d '' <<< "`ls -la /dev/ttyUSB* | awk '{print $10}'`"
  if (( ${#ttyList[@]} > 0 )); then
    # Get LoRa RF device input from user.
    while :; do
      echo "Select LoRa RF device: "

      # Show list of USB devices.
      # output="PORT_NUMBER SYMLINK ID_MODEL\n\n"
      portList=()
      printf "%-15s %-20s %s\n" "PORT_NUMBER" "SYMLINK" "ID_MODEL"
      for (( i=0; i<"${#ttyList[@]}"; i++ )); do
        model=`udevadm info ${ttyList[$i]} | grep ID_MODEL_FROM_DATABASE | grep -oP '[^=]*$'`
        port=`udevadm info ${ttyList[$i]} | grep USBSERIAL_PORT | grep -oP '[^=]*$'`
        portList[${#portList[@]}]="$port"
        # echo "${ttyList[$i]}"
        # echo -e "$_CYAN_$port$_NC_ ${ttyList[$i]} $model"
        #output="$output\n$_CYAN_$port$_NC_ ${ttyList[$i]} $model\n"
        printf "${_CYAN_}%-15s${_NC_} %-20s %s\n" "$port" "${ttyList[$i]}" "$model"
      done

      # Get input from user.
      # printf "Type device number (i.e., 001) : "
      echo -e -n "Type PORT_NUMBER (e.g.,$_CYAN_ 2$_NC_,$_CYAN_ 5$_NC_) : "
      read devPath

      # Try to get 'vendor id' and 'product id' using $devnum and break loop.
      [[ "${portList[@]}" =~ "${devPath}" ]] && break

      echo "Incorrect PORT_NUMBER: '$devPath'"
    done
    devPathRef="1.$devPath"
  else
    echo "No usb device found."
  fi
}

function setupSymlink {
  echo ""
  echo "setupSymlink"

  # Check '99-usb-serial.rules' is available.
  local ruleFile="/etc/udev/rules.d/99-usb-serial.rules"
  local devPath=$1
  local symlinkName=$2
  [ ! -f "$ruleFile" ] && touch "$ruleFile"

  # Check 'vendor id', 'product id' and 'symlink' duplications.
  duplicateDevPath=`grep -n "ATTRS{devpath}==\"$devPath\"" $ruleFile`
  duplicateSymlink=`grep -n "SYMLINK+=\"$symlinkName\"" $ruleFile`
  if [ -n "$duplicateDevPath" ] || [ -n "$duplicateSymlink" ]; then
    if [ -n "$duplicateDevPath" ]; then
      echo -e '\e[33m'"Found duplicate "'\e[0m''\e[36m'"device path."'\e[0m'
      echo "$duplicateDevPath"
    fi
    if [ -n "$duplicateSymlink" ]; then
      echo -e '\e[33m'"Found duplicate "'\e[0m''\e[36m'"symlink."'\e[0m'
      echo "$duplicateSymlink"
    fi
    # echo "Remove old setting (y): "
    # printf 'Remove old setting (y): '
    echo -n "Remove old setting (y): "
    read confirm
    if [[ "$confirm" == "y" ]]; then
      # Delete duplicate
      sed -i "/ATTRS{devpath}==\"$devPath\"/d" $ruleFile
      sed -i "/SYMLINK+=\"$symlinkName\"/d" $ruleFile
    else
      echo -e "You should to "'\e[31m'"remove"'\e[0m'" the duplicate line manually!"
      echo -e '\e[31m'"udev rule not add!!!"'\e[0m'
    fi
  fi

  # Add new config
  echo "SUBSYSTEM==\"tty\", ATTRS{devpath}==\"$devPath\", SYMLINK+=\"$symlinkName\"" >> $ruleFile
}

function setupNerveNetDeviceConfig {
  echo ""
  echo "setupNerveNetDeviceConfig"

  local configPath=$1
  local symlinkName=$2
  # local devConfig="DEVNAME=$symlinkName"

  local diffData=`diff $configPath <(echo "\`cat $configPath | sed -e \"s/^DEVNAME=.*$/DEVNAME=$symlinkName/\"\`")`
  # echo "$diffData"
  # Return if config not found!
  if [ -z diffData ]; then
    echo -e '\e[31m'"Config not found!"'\e[0m'
    return 1
  else
    echo "Config change : "
    echo "$diffData"
    echo -n "Confirm change (y): "
    read confirm
    if [[ "$confirm" == "y" ]]; then
      `sed -i -e "s/^DEVNAME=.*$/DEVNAME=$symlinkName/" $configPath`
    fi
    # sed -e 's/^DEVNAME=.*$/DEVNAME=$symlinkName/' $configPath | grep -oPn "^DEVNAME=ttyUSB0"
  fi
}

function main {
  local loraDevPath=""

  # ==== ==== ==== Setup LoRa RF Module Symbolic Link ==== ==== ==== #
  # Get device vendor id and product id, choosen by user.
  echo -e "\n==== ==== Select LoRa RF module ==== ===="
  selectDev loraDevPath
  echo "Device Path: ${loraDevPath}"

  # Setup udev rule.
  setupSymlink $loraDevPath $LORA_SYMLINK_NAME

  # Setup NerveNet device config.
  setupNerveNetDeviceConfig $FILE_RFLINK $LORA_SYMLINK_NAME

  # ==== ==== ==== Setup EST Node Symbolic Link ==== ==== ==== #
  local estDevPath=""
  echo -e "\n==== ==== Select EST node USB-to-serial cable ==== ===="
  selectDev estDevPath
  echo "Device Path: ${estDevPath}"

  # Setup udev rule.
  setupSymlink $estDevPath $EST_SYMLINK_NAME
}

main

# SUBSYSTEM=="tty", ATTRS{idVendor}=="067b", ATTRS{idProduct}=="2303", SYMLINK+="EstLink"
# SUBSYSTEM=="tty", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6001", SYMLINK+="LoraRfLink"

# sed -e 's/^DEVNAME=.*$/DEVNAME=ttyUSB0/' /writable/etc/rflink-meshd.conf | grep -oPn "^DEVNAME=ttyUSB0"
