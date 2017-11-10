#! /bin/bash
source config.sh
PROTOBUF="$CT_PATH/protobuf/python"
PYTHON_CT="$CT_PATH/certificate-transparency/python"

if [ "x$1" != "x" ]; then
    LOGS="$(echo $1)"
else
    LOGS="$(cat logs.txt)"
fi

echo "$LOGS" | while read LOGINFO; do
    URL=$(echo "$LOGINFO" | cut -d ' ' -f 1);
    FOLDER=$(echo "$URL" | tr '/' '_')
    SSL=$(echo "$LOGINFO" | cut -d ' ' -f 2);
    echo "URL: ${URL}, SSL: ${SSL}";
    if [ -d "${STORAGE_PATH}/${FOLDER}" ]; then
        COUNT=$(find "${STORAGE_PATH}/${FOLDER}" -name '*.der' | wc -l)
        LAST=$(ls -tr "${STORAGE_PATH}/${FOLDER}/" | grep -F '.der' | tail -1 | sed -e 's/cert_//' -e 's/\.der//')
        echo "COUNT: ${COUNT}, LAST: ${LAST}"
    else
        echo "Storage directory ${STORAGE_PATH}/${FOLDER} does not exist, no data downloaded"
        LAST="0"
    fi
    PYTHONPATH=${PYTHON_CT}:${PROTOBUF} $PWD/save_dotno_certs.py --output "${STORAGE_PATH}/${FOLDER}/" --log "https://${URL}" --startat ${LAST} --multi ${THREADS}
done

