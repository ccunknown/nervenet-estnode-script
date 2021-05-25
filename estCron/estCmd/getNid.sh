#! /bin/bash

RETRY=5

function validate {
  DATA=$1
  REGEX="^[0-9]+ route [0-9]+ [^ ]+$"
  #echo "DATA: $DATA"
  if [[ "$DATA" =~ $REGEX ]]; then
    echo "valid"
  else
    echo "invalid"
  fi
}

PORT=$1
CMD="$ route get_nid"

for (( i=0 ; i < $RETRY ; i++ ))
do
  RESULT=`./estCmd.sh "$CMD" "$PORT"`
  VALID=`validate "$RESULT"`
  echo $VALID
  if [ "$VALID" == "valid" ]; then
    echo $RESULT
    break
  fi
done