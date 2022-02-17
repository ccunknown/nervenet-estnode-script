#! /bin/bash

RETRY=5
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

PORT=$1
INDEX=$2
NUMBER=$3
CMD="$ flash log_view $INDEX $NUMBER"
RESULT=""

function validate {
  DATA=$1
  # REGEX="^[0-9]+ flash [0-9]+,[AS],[0-9/]+,[0-9\:]+,.+$"
  REGEX_A="^[0-9]+ flash [0-9]+,A,[0-9/]+,[0-9\:]+,[0-9]+,[0-9]+(,-?[0-9]+(\.[0-9]+)?)+$"
  REGEX_S="^[0-9]+ flash [0-9]+,S,[0-9/]+,[0-9\:]+,.+$"
  REGEX_END="^[0-9]+ flash log view ready"
  # echo "$DATA" | tr -d '\r' | od -c
  # echo "DATA: $DATA"
  if [[ "$DATA" =~ $REGEX_A ]]; then
    echo "valid"
  elif [[ "$DATA" =~ $REGEX_S ]]; then
    echo "valid"
  elif [[ "$DATA" =~ $REGEX_END ]]; then
    echo "end tag"
  else
    echo "invalid"
  fi
}

#echo $CMD

for (( i=0 ; i < $RETRY ; i++ ))
do
  RESULT=""
  QUERY=`$DIR/cmd.sh "$CMD" "$PORT"`
  # echo "$QUERY"
  # echo "$QUERY" | od -c
  VALID="invalid"
  while read LINE; do
    # echo "LINE: $LINE"
    VALID=`validate "$LINE"`
    # echo $VALID
    if [ "$VALID" == "invalid" ]; then
      # echo $LINE
      break
    elif [ "$VALID" == "valid" ]; then
      if [ -z "$RESULT" ]; then
        RESULT=`printf "$LINE" | tr -d '\r'`
      else
        RESULT=`printf "$RESULT\n$LINE" | tr -d '\r'`
      fi
    fi
  done <<< "$QUERY"

  if [ "$VALID" != "invalid" ]; then
    break
  fi
  # VALID=`validate "$QUERY"`
  # # echo $VALID
  # if [ "$VALID" == "valid" ]; then
  #   echo "$QUERY"
  #   break
  # fi
done

echo "$RESULT"
