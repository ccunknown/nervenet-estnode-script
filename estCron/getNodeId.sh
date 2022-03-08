#! /bin/bash

CONFIG_PATH=$1
#echo "config path:" $CONFIG_PATH

ID=`cat $CONFIG_PATH | grep -oP "^NODEID=[0-9]+" | grep -oP "[0-9]+"`
echo $ID
