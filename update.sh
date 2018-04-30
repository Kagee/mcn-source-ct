#! /bin/bash
SOURCE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# This way we can work with realtive paths in the rest of the script
cd "${SOURCE_DIR}"
source config.sh

LOGS="$(cat logs.txt)"

echo "$LOGS" | while read LOGINFO; do
    URL=$(echo "$LOGINFO" | cut -d ' ' -f 1 | sed -e 's#/$##');
    TREE_SIZE=$(echo "$LOGINFO" | cut -d ' ' -f 2);
    WORKDIR="${STORAGE_PATH}/$(echo "$URL" | tr '/' '_')";
    if [ -d "$WORKDIR" ]; then
	echo -n "$WORKDIR exists"
       if [ -f "$WORKDIR/running" ]; then
	   echo " but is job running"
       else
           echo " and job is not running, updating:"
           ./get_certs.sh "$LOGINFO"
       fi
    fi
done;
