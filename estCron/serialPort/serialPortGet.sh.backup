#! /bin/bash

DEVICE_NAME=$1
#echo "name: $DEVICE_NAME"
DMESG=`dmesg | grep "$DEVICE_NAME" | tail -n 1`
#echo "dmesg: $DMESG"

if [[ $DMESG =~ "$DEVICE_NAME now attached to".+ ]]; then
  RESULT=`echo "$DMESG" | grep -oP "([a-zA-Z0-9]+)$"`
else
  RESULT="null"
fi

echo "$RESULT"
