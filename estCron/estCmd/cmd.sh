#! /bin/bash

# Timeout (ms)
TIMEOUT=1000
TIME_DELAY=0.1;
SERIAL_FILE="/tmp/est_cron_serial.txt"

CMD=$1
PORT=$2
RESULT=""

echo "" > $SERIAL_FILE
# read LINE < $PORT &
cat $PORT > $SERIAL_FILE &
CHILD_PID=$!
sleep $TIME_DELAY
echo "$CMD" > $PORT

TIMEOUT_BEGIN=`echo $(($(date +%s%N)/1000000))`
while true; do
  TIMEOUT_END=`echo $(($(date +%s%N)/1000000))`
  TIMEOUT_DIFF=`echo "$(($TIMEOUT_END-$TIMEOUT_BEGIN))"`
  if [ "$TIMEOUT_DIFF" -gt "$TIMEOUT" ]; then
    echo "TIMEOUT: $TIMEOUT_DIFF ms"
    kill -9 $CHILD_PID
    exit 1
  fi
  BLANK_LINE=`cat $SERIAL_FILE | grep -c -e '^.$'`
  if [ "$BLANK_LINE" -ne "0" ] ;then
    break
  fi
  sleep $TIME_DELAY
  # echo "RETRY"
done

kill -9 $CHILD_PID
wait $CHILD_PID 2>/dev/null

RESULT=`cat $SERIAL_FILE`
RESULT=`printf "$RESULT" | tr -d '\r'`
RESULT2=""
while read LINE; do
  # echo "LINE: $LINE"
  if [ -z "$LINE" ]; then
    break
  elif [ "$LINE" = "$CMD" ]; then
    RESULT2=`printf "$RESULT2"`
  elif [ "$LINE" = ">$CMD" ]; then
    RESULT2=`printf "$RESULT2"`
  elif [ -z "$RESULT2" ]; then
    RESULT2=`printf "$LINE"`
  else
    RESULT2=`printf "$RESULT2\n$LINE"`
  fi
done <<< "$RESULT"

echo "$RESULT2"
