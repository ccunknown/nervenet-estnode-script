#! /bin/bash

RETRY=5
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

function validate {
  DATA=$1
  REGEX="^[0-9]+ flash wr [0-9]+ [0-9A-F]+ rd [0-9]+ [0-9A-F]+ len [0-9]+$"
  # echo "$DATA" | od -c
  # echo "DATA: $DATA"
  if [[ "$DATA" =~ $REGEX ]]; then
    echo "valid"
  else
    echo "invalid"
  fi
}

PORT=$1
CMD="$ flash log_status"

for (( i=0 ; i < $RETRY ; i++ ))
do
  RESULT=`$DIR/cmd.sh "$CMD" "$PORT"`
  VALID=`validate "$RESULT"`
  # echo $VALID
  if [ "$VALID" == "valid" ]; then
    echo $RESULT
    break
  fi
done
