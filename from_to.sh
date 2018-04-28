#! /bin/bash
SOURCE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# This way we can work with realtive paths in the rest of the script
cd "${SOURCE_DIR}"
source config.sh

function select_logs {
  cat logs.txt | grep -P " \d{${1},${2}}$"
}

if [ "x$1" != "x" ] && [ "x$2" != "x" ] && [ "$1" -le "$2" ] && [ "x$3" != "x"  ]; then 
   select_logs "$1" "$2" | sort -k 2 -n 
elif [ "x$1" != "x" ] && [ "x$2" != "x" ] && [ "$1" -le "$2" ]; then
   select_logs "$1" "$2" | while read LOG; 
	do ./get_certs.sh "$LOG"; 
   done
else
    echo 'Missing $1 or $2, or $2 was smaller than $1' 1>&2
    exit 1
fi

