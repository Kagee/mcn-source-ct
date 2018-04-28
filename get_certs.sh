#! /bin/bash
source config.sh
PROTOBUF="$CT_PATH/protobuf/python"
PYTHON_CT="$CT_PATH/certificate-transparency/python"

if [ "x$1" != "x" ]; then
    LOGS="$(echo $1)"
else
    #LOGS="$(cat logs.txt)"
    echo "Supply a log to download as argument "\
         "(you probably don't want to download all of them)."
    exit 1
fi

find data/ -type f -name 'running'

echo "$LOGS" | while read LOGINFO; do
    URL=$(echo "$LOGINFO" | cut -d ' ' -f 1 | sed -e 's#/$##');
    TREE_SIZE=$(echo "$LOGINFO" | cut -d ' ' -f 2);
    #COUNT_AT="$(echo "(${TREE_SIZE} * 0.09)+10" | bc | cut -d. -f1)"
    COUNT_AT="$(echo "a=(${TREE_SIZE} * 0.0999999999999); " \
        "if (a > 1) print (a/1) else print 1" | bc)"
    WORKDIR="${STORAGE_PATH}/$(echo "$URL" | tr '/' '_')"
    echo -e "URL: ${URL}, CACHED TREE SIZE: ${TREE_SIZE}" \
        "\nCOUNT_AT: ${COUNT_AT}, WORKDIR: ${WORKDIR}";

    LAST_CHECKED=0
    if [ -f "${WORKDIR}/last.checked" ]; then
        LAST_CHECKED="$(cat "${WORKDIR}/last.checked")"
    fi

    if [ -d "${WORKDIR}" ]; then
        PREV_MATCHES="$(find "${WORKDIR}" -name '*.der' | wc -l)"
        LAST_MATCH="$(ls "${WORKDIR}/" | grep -F '.der' | \
            sed -e 's/cert_//' -e 's/\.der//' | sort -n | tail -1)"
        if [ "x${LAST_MATCH}" == "x" ]; then
            LAST_MATCH="0"
        fi
        START_AT=$(echo -e "0\n${LAST_MATCH}\n${LAST_CHECKED}" | sort -n | tail -1)
        echo "PREV_MATCHES: ${PREV_MATCHES}, LAST_MATCH: ${LAST_MATCH}, " \
            "LAST_CHECKED: ${LAST_CHECKED}, START_AT: ${START_AT} " \
            "(of >${TREE_SIZE})"
    else
        echo "Working directory ${WORKDIR} does not " \
            "exist, no data downloaded"
        LAST_MATCH="0"
    fi
    mkdir -p "${WORKDIR}"
    if [ -f "${WORKDIR}/running" ]; then
      echo "https://${URL} already running, skipping"
    else
      echo "$(date)" > "${WORKDIR}/running"
      PYTHONPATH=${PYTHON_CT}:${PROTOBUF} $PWD/save_dotno_certs.py \
        --output "${WORKDIR}/" \
        --log "https://${URL}" \
        --startat ${START_AT} \
        --countat ${COUNT_AT} \
        --multi ${THREADS} | tee "${WORKDIR}/last.log" && \
        (N=$(grep "Certificate index:" "${WORKDIR}/last.log" | \
        grep -o -P 'Certificate index: \d*' | grep -o -P '\d*' | sort -n | \
        tail -1); echo -e "0\n${N}\n${LAST_MATCH}\n$(cat "${WORKDIR}/last.checked")" | \
        sort -n | tail -1 > "${WORKDIR}/last.checked");
        rm "${WORKDIR}/running"
        echo "LAST_CHECKED: $(cat "${WORKDIR}/last.checked")"
    fi
done

