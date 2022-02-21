#! /bin/bash

RFLINK_PATH=$1
#echo "config path:" $RFLINK_PATH

ID=`cat $RFLINK_PATH | grep -oP "^ID_SLOT=[0-9]+" | grep -oP "[0-9]+"`
echo $ID
