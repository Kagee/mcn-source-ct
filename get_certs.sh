#! /bin/bash
SOURCE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# This way we can work with realtive paths in the rest of the script
cd "${SOURCE_DIR}" || exit
# shellcheck disable=1091
source config.sh

if [ "x$1" != "x" ]; then
    #LOGS="$(echo $1)"
    LOG="$1"
else
    #LOGS="$(cat logs.txt)"
    echo "Supply a log to download as argument "\
         "(you probably don't want to download all of them)."
    exit 1
fi

# find data/ -type f -name 'running'


function do_log {
  LOGINFO="$1"
  URL="$(echo "$LOGINFO" | cut -d ' ' -f 1 | sed -e 's#/$##')"
  SIZE=$(echo "$LOGINFO" | cut -d ' ' -f 2);
  WORKDIR="$(url2workdir "$URL")"
  MAX_ID="$(get_highest_cert_id "$WORKDIR")"
  echo -e "URL:\t$URL"
  echo -e "WORKDIR:\t$WORKDIR"
  echo -e "SIZE:\t$SIZE"
  echo -e "MAX_ID:\t$MAX_ID"
  echo ""
}

function url2workdir {
  URL="$1"
  echo "$STORAGE_PATH/$(echo "$URL" | tr '/' '_')"
}

function get_highest_cert_id {
  WORKDIR="$1"
  LAST_MATCH="$(ls "$WORKDIR/" | grep -F '.der' | \
                sed -e 's/cert_//' -e 's/\.der//' | \
                sort -n | tail -1)"
  if [ "x${LAST_MATCH}" == "x" ]; then
    LAST_MATCH="0"
  fi
  echo "$LAST_MATCH"

}

do_log "$LOG"

exit

echo "$LOGS" | sort -R | while read -r LOGINFO; do
    URL=$(echo "$LOGINFO" | cut -d ' ' -f 1 | sed -e 's#/$##');
    TREE_SIZE=$(echo "$LOGINFO" | cut -d ' ' -f 2);
    #COUNT_AT="$(echo "(${TREE_SIZE} * 0.09)+10" | bc | cut -d. -f1)"
    #COUNT_AT="$(echo "a=(${TREE_SIZE} * 0.0999999999999); " \
    #    "if (a > 1) print (a/1) else print 1" | bc)"
    COUNT_AT="$(echo "a=(${TREE_SIZE} * 0.00999999999999); " \
        "if (a > 1) if (a > 10000) print 10000 else print (a/1) else print 1" | bc)"
    WORKDIR="${STORAGE_PATH}/$(echo "$URL" | tr '/' '_')"
    echo -e "URL: ${URL}, CACHED TREE SIZE: ${TREE_SIZE}" \
        "\nCOUNT_AT: ${COUNT_AT}, WORKDIR: ${WORKDIR}";

    LAST_CHECKED=0
    if [ -f "${WORKDIR}/last.checked" ]; then
        LAST_CHECKED="$(cat "${WORKDIR}/last.checked")"
    fi
    START_AT=0
    if [ -d "${WORKDIR}" ]; then
        PREV_MATCHES="$(find "${WORKDIR}" -name '*.der' | wc -l)"
        #LAST_MATCH="$(ls "${WORKDIR}/" | grep -F '.der' | \
        #    sed -e 's/cert_//' -e 's/\.der//' | sort -n | tail -1)"
        #if [ "x${LAST_MATCH}" == "x" ]; then
            LAST_MATCH="0"
        #fi
        START_AT=$(echo -e "${START_AT}\n${LAST_MATCH}\n${LAST_CHECKED}" | sort -n | tail -1)
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
      echo "R $$ $(date --iso=m | grep -o -E '..-..T..:..')" > "${WORKDIR}/running"
      #PYTHONPATH=${PYTHON_CT}:${PROTOBUF} "$PWD/save_dotno_certs.py" \
      #  --output "${WORKDIR}/" \
      #  --log "https://${URL}" \
      #  --startat "$START_AT" \
      #  --countat "$COUNT_AT" \
      #  --multi "$THREADS" | tee "${WORKDIR}/last.log" | grep -v -E 'sha256_root_hash|tree_head_signature' && \
      #  (N=$(grep "Certificate index:" "${WORKDIR}/last.log" | \
      #  grep -o -P 'Certificate index: \d*' | grep -o -P '\d*' | sort -n | \
      #  tail -1); echo -e "0\n${N}\n${LAST_MATCH}\n$(cat "${WORKDIR}/last.checked")" | \
      #  sort -n | tail -1 > "${WORKDIR}/last.checked.tmp"; mv "${WORKDIR}/last.checked.tmp" "${WORKDIR}/last.checked";);
        rm "${WORKDIR}/running"
      #  echo "LAST_CHECKED: $(cat "${WORKDIR}/last.checked")"
    fi
done

