#! /bin/bash

DIR="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

function setupPort {
  echo "setupPort() >>"

  local DEVICE_NAME=$1
  local -n REF=$2

  # Get Serial Port
  REF="/dev/`$DIR/serialPort/serialPortGet.sh "$DEVICE_NAME"`"
  if [ "$REF" = "/dev/null" ]; then
    echo "> Device $DEVICE_NAME not attached!"
    return 1
  else
    echo "> Device $DEVICE_NAME attached to $REF."
    PORT_SETUP=`$DIR/serialPort/serialPortSetup.sh $REF`
    echo "$PORT_SETUP"
    echo "> setup complete!"
    return 0
  fi
}

function getParam {
  echo "getParam() >>"
  local NAME=$1
  local STATE_FILE="$STATE_FILE_PREFIX-$NAME"
  echo "$STATE_FILE"
  if [ -f "$STATE_FILE" ]; then
    read -r "$NAME" < "$STATE_FILE"
    echo "$NAME: ${!NAME}"
    return 0
  else
    echo "File $STATE_FILE not found!"
    return 1
  fi
}

function saveParam {
  echo "saveParam() >>"
  # local NAME=$1
  # printf '%s\n' "${!NAME}" > "$STATE_FILE"
  local STATE_FILE="$STATE_FILE_PREFIX-$1"
  printf '%s\n' "$2" > "$STATE_FILE"
}

function readLog {
  echo "readLog() >>"

  # Get reference variable for send back data.
  local PORT=$1
  local -n REF=$2

  # Get write index from est board.
  local CURRENT_WRITE_INDEX=`$DIR/estCmd/logStatus.sh $PORT | grep -oP "(?<=wr )([0-9])+"`
  echo "write index: $CURRENT_WRITE_INDEX"

  # Get last readed index and put into array.
  if getParam "LAST_INDEX"; then
    echo "Last write index: $LAST_INDEX"
    local DIFF=`expr $CURRENT_WRITE_INDEX - $LAST_INDEX`
    local ARR=("$DIFF" "$READ_BACK_MAX")
  else
    echo "not found 'LAST_INDEX'"
    local ARR=("$READ_BACK_START" "$READ_BACK_MAX")
  fi

  # Get the lowest number to be number to read.
  local IFS=$'\n'
  local READ_BACK=`echo "${ARR[*]}" | sort -nr | tail -n1`
  echo "Read numbers: $READ_BACK"

  # Write CURRENT_WRITE_INDEX to file as LAST_INDEX.
  local LAST_INDEX="$CURRENT_WRITE_INDEX"
  saveParam "LAST_INDEX" "$LAST_INDEX"

  # Read 'log view'.
  DATA=`$DIR/estCmd/logView.sh $PORT $CURRENT_WRITE_INDEX $READ_BACK`

  # Write to the reference variable to send back to caller.
  REF="$DATA"
}

function checkStation {
  stations=`sqlite3 $DB_PATH "SELECT * FROM loramesh_station"`
  neighbors=`sqlite3 $DB_PATH "SELECT * FROM loramesh_neigh"`

  s_count=`echo "$stations" | wc -l`
  n_count=`echo "$neighbors" | wc -l`

  echo "Found [$s_count] stations:"
  echo "$stations"

  echo "Found [$n_count] neighbors:"
  echo "$neighbors"

  if [ "$s_count" -ge 2 ] && [ "$n_count" -ge 2 ]; then
    return 1
  else
    return 0
  fi
}

function setCron {
  if [ ! -f $CRON_PATH ]; then
    echo "Cron file not set, creating cron file ..."
    SCRIPTPATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )/cronScript.sh"
    RETURNED=`echo "* * * * * $CRON_USER $SCRIPTPATH" > "$CRON_PATH"`
    if [ -z $RETURNED ]; then
      cat $CRON_PATH
      echo "Cron file created, please restart machine."
    else
      echo "$RETURNED"
    fi
    return 0
  else
    echo "Cron file already set."
    return 1
  fi
}

function main {
  PORT=""
  # setupPort "$USB_DEVICE_NAME" PORT
  if setCron; then
    echo ""
  elif checkStation; then
    echo "No station available."
  elif setupPort "$USB_DEVICE_NAME" PORT; then
    local LOG=""
    echo "main PORT: $PORT"
    readLog "$PORT" LOG
    echo "LOG: "
    echo "${LOG//,/ }"

    # Cut LOG's static line header.
    SHORT=`echo "${LOG//,/ }" | grep -oP "[0-9]+ [AS] .+$"`
    local RESULT="$SHORT"

    echo "RESULT: "
    echo "$RESULT"

    if [ -n "$DB_PATH" ] && [ -n "$RESULT" ]; then
      INSERT=`$DIR/dbCmd/insert.sh "$DB_PATH" "$RESULT"`
      echo "INSERT: "
      echo "$INSERT"
    fi
  fi
}

echo "script start ..."
CONFIG_PATH="$DIR/config.sh"
echo "Load Config: $CONFIG_PATH"
# Load Config.
echo "> load config"
source $CONFIG_PATH
# source ./config.sh

main "$@"


