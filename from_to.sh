#! /bin/bash
if [ "x$1" != "x" ] && [ "x$2" != "x" ] && [ "$1" -le "$2" ]; then
   cat logs.txt | grep -P " \d{${1},${2}}$"
else
    echo 'Missing $1 or $2, or $2 was smaller than $1' 1>&2
    exit 1
fi

