#! /bin/bash

# Cron settings.
CRON_DIR="/etc/cron.d"
CRON_FILE="est"
CRON_PATH=`echo "$CRON_DIR/$CRON_FILE"`
CRON_USER="nict"
#INTERVAL=100

# Serial Port Configuration.
USB_DEVICE_NAME="pl2303 converter"

# Database
DB_PATH="/var/tmp/loramesh.sqlite3"

# Script parameters.
STATE_FILE_PREFIX="/tmp/est_cron_state"
SERIAL_FILE="/tmp/est_cron_serial.txt"
READ_BACK_START=3
READ_BACK_MAX=3

# EST Node setup parameter.
EST_SYMLINK_NAME="EstNode"

# NerveNet setup parameter.
FILE_RFLINK="/writable/etc/rflink-meshd.conf"
FILE_RFLINK_0709="/writable/etc/rflink-meshd-0709.conf"
FILE_NN_CONFIG="/writable/etc/node.conf"
LORA_SYMLINK_NAME="LoraRfLink"

# Result options.
ADD_ID_SLOT=1
ADD_NODE_ID=1
SHORT_EST_HEADER=1
