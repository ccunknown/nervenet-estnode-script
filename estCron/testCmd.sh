#!/bin/bash

CMD=$1
DEST=$2

echo "$CMD" > /dev/$DEST
#sleep 0.1
read LINE < /dev/$DEST

echo "$LINE"
