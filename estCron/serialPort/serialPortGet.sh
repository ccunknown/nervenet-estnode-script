#! /bin/bash

DEVICE_NAME=$1
#echo "name: $DEVICE_NAME"
#echo "dmesg: $DMESG"
USB_NUMBER=`cat /etc/udev/rules.d/99-usb-serial.rules | grep "SYMLINK+=\"EstNode\"" | grep -oP "ATTRS{devpath}==\"[1-9\.]+\"" | grep -oP "[0-9\.]+"`
DMESG=`dmesg | grep "usb 1\-$USB_NUMBER:" | tail -n 1`

if [[ $DMESG =~ "now attached to".+ ]]; then
  RESULT=`echo "$DMESG" | grep -oP "([a-zA-Z0-9]+)$"`
else
  RESULT="null"
fi

echo "$RESULT"
