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
    URL=$(echo "$LOGINFO" | cut -d ' ' -f 1 | sed -e 's#/$##');
    FOLDER=$(echo "$URL" | tr '/' '_')
    TREE_SIZE=$(echo "$LOGINFO" | cut -d ' ' -f 2);
    WORKDIR="${STORAGE_PATH}/${FOLDER}"
    LAST_CHECKED=0
    if [ -f "${WORKDIR}/last.checked" ]; then
        LAST_CHECKED="$(cat "${WORKDIR}/last.checked")"
    fi
    echo "URL: ${URL}, CACHED TREE SIZE: ${TREE_SIZE}, WORKDIR: ${WORKDIR}";

    if [ -d "${WORKDIR}" ]; then
        COUNT="$(find "${WORKDIR}" -name '*.der' | wc -l)"
        LAST_MATCH="$(ls -tr "${WORKDIR}/" | grep -F '.der' | \
            tail -1 | sed -e 's/cert_//' -e 's/\.der//')"
        if [ "x${LAST_MATCH}" == "x" ]; then
            LAST_MATCH="0"
        fi
        START_AT=$(echo -e "${LAST_MATCH}\n${LAST_CHECKED}" | sort | tail -1)
        echo "COUNT: ${COUNT}, LAST_MATCH: ${LAST_MATCH}, " \
            "LAST_CHECKED: ${LAST_CHECKED}, START_AT: ${START_AT} " \
            "(of >${TREE_SIZE})"
    else
        echo "Working directory ${WORKDIR} does not " \
            "exist, no data downloaded"
        LAST_MATCH="0"
    fi
    PYTHONPATH=${PYTHON_CT}:${PROTOBUF} $PWD/save_dotno_certs.py \
        --output "${WORKDIR}/" \
        --log "https://${URL}" \
        --startat ${START_AT} \
        --multi ${THREADS} | tee "${WORKDIR}/last.log"
    grep "Certificate index:" "${WORKDIR}/last.log" | \
        grep 'Certificate index:' | grep -o -P '\d*' | sort | \
        tail -1 > "${WORKDIR}/last.checked"
done

