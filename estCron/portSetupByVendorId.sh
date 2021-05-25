#! /bin/bash

echo "script start ..."

DIR="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
CONFIG_PATH="$DIR/config.sh"

echo "Load Config: $CONFIG_PATH"
# Load Config.
echo "> load config"
source $CONFIG_PATH

function selectLoraRfDev {
  echo ""
  echo "selectLoraRfDev"

  local -n vendorIdRef=$1
  local -n productIdRef=$2

  IFS=$'\n' read -a usbList -d '' <<< "`lsusb`"
  if (( ${#usbList[@]} > 0 )); then
    # Get LoRa RF device input from user.
    while :; do
      echo "Select LoRa RF device: "

      # Show list of USB devices.
      for (( i=0; i<"${#usbList[@]}"; i++ )); do
        echo "${usbList[$i]}"
      done

      # Get input from user.
      # printf "Type device number (i.e., 001) : "
      echo -n "Type device number (i.e., 001) : "
      read devnum

      # Try to get 'vendor id' and 'product id' using $devnum and break loop.
      vendorId=`lsusb -s $devnum --verbose | grep "idVendor" | awk '{print $2}' | sed 's/0x//g'`
      productId=`lsusb -s $devnum --verbose | grep "idProduct" | awk '{print $2}' | sed 's/0x//g'`
      [ -n "$vendorId" ] && [ -n "$productId" ] && break

      echo "Cannot get 'vendor id' and/or 'product id' of device '$devnum'"
    done
    vendorIdRef="$vendorId"
    productIdRef="$productId"
  else
    echo "No usb device found."
  fi
}

function setupSymlink {
  echo ""
  echo "setupSymlink"

  # Check '99-usb-serial.rules' is available.
  local ruleFile="/etc/udev/rules.d/99-usb-serial.rules"
  local vendorId=$1
  local productId=$2
  local symlinkName=$3
  [ ! -f "$ruleFile" ] && touch "$ruleFile"

  # Check 'vendor id', 'product id' and 'symlink' duplications.
  duplicateId=`grep -n "ATTRS{idVendor}==\"$vendorId\"" $ruleFile | grep "ATTRS{idProduct}==\"$productId\""`
  duplicateSymlink=`grep -n "SYMLINK+=\"$symlinkName\"" $ruleFile`
  if [ -n "$duplicateId" ] || [ -n "$duplicateSymlink" ]; then
    if [ -n "$duplicateId" ]; then
      echo -e '\e[33m'"Found duplicate "'\e[0m''\e[36m'"vendor/product id."'\e[0m'
      echo "$duplicateId"
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
      sed -i "/ATTRS{idVendor}==\"$vendorId\"/d" $ruleFile
      sed -i "/ATTRS{idProduct}==\"$productId\"/d" $ruleFile
      sed -i "/SYMLINK+=\"$symlinkName\"/d" $ruleFile
    else
      echo -e "You should to "'\e[31m'"remove"'\e[0m'" the duplicate line manually!"
      echo -e '\e[31m'"udev rule not add!!!"'\e[0m'
    fi
  fi

  # Add new config
  echo "SUBSYSTEM==\"tty\", ATTRS{idVendor}==\"$vendorId\", ATTRS{idProduct}==\"$productId\", SYMLINK+=\"$symlinkName\"" >> $ruleFile
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
  local vendorId=""
  local productId=""

  # Get device vendor id and product id, choosen by user.
  selectLoraRfDev vendorId productId
  echo "vendor id: $vendorId"
  echo "product id: $productId"
  [ -z "$vendorId" ] || [ -z "$productId" ] && return 1

  # Setup udev rule.
  setupSymlink $vendorId $productId $SYMLINK_NAME

  # Setup NerveNet device config.
  setupNerveNetDeviceConfig $FILE_RFLINK $SYMLINK_NAME
}

main

# SUBSYSTEM=="tty", ATTRS{idVendor}=="067b", ATTRS{idProduct}=="2303", SYMLINK+="EstLink"
# SUBSYSTEM=="tty", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6001", SYMLINK+="LoraRfLink"

# sed -e 's/^DEVNAME=.*$/DEVNAME=ttyUSB0/' /writable/etc/rflink-meshd.conf | grep -oPn "^DEVNAME=ttyUSB0"
