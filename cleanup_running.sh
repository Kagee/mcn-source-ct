#! /bin/bash
SOURCE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# This way we can work with realtive paths in the rest of the script
cd "${SOURCE_DIR}"
source config.sh

find data/ -name 'running' | while read RN; do
  C=$(cat "${RN}" | cut -c1);
  if [ "xE" == "x$C" ]; then
    echo "[INFO] In error mode, not touching ${RN}";
  elif [ "xP" == "x$C" ] || [ "xR" == "x$C" ]; then
    PID="$(cat "${RN}" | awk '{ print $2}')"
    if ps -p $PID > /dev/null
    then
       echo "[INFO] $PID is running, not touching ${RN}"
    else
        echo "[INFO] PID $PID not found, deleting ${RN}"
        rm "${RN}"
    fi
  fi

done

