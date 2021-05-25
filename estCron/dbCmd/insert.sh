#! /bin/bash

# DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

function insertToDb {
  echo "insertToDb() >>"
  echo "PATH: $1"
  echo "LINE: $2"
  # local CMD="sqlite3 $1 \"INSERT INTO loramesh_send (asc_payload) VALUES('$2')\""
  # echo "CMD: $CMD"
  # CMD="$CMD"
  # `$CMD`
  # `sqlite3 $1 "INSERT INTO loramesh_send (asc_payload) VALUES('$2');"`
  # sqlite3 /var/tmp/loramesh.sqlite3 "INSERT INTO loramesh_send(asc_payload) VALUES(\"2000 flash 1000 A 19/11/19 20:30:00 7 1 20.6 74.6 0.000 063 0.0 0.0 0.0 0 -0.001 12.4\")"
  # eval $CMD
  
  sqlite3 $1 "INSERT INTO loramesh_send (asc_payload) VALUES(\"$2\")"
}

function main {
  local DEST=$1
  local VAL=$2

  echo "PATH: $DEST"
  echo "VAL: "
  echo "$VAL"

  # Loop for each line of $VAL.
  while IFS= read -r LINE; do
    local RESULT=`insertToDb "$DEST" "$LINE"`
    echo "$RESULT"
  done <<< "$VAL"
  # insertToDb $1 $2
}

main "$@"
