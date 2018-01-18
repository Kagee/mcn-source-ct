#! /bin/bash
SOURCE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# This way we can work with realtive paths in the rest of the script
cd "${SOURCE_DIR}"

source config.sh

# This script will dowload a list of all CT logs that Google
# and crt.sh mentions. It will then attempt to the the 
# tree_size of the logs. If this fails, the bare URL of
# the log will be written to FAILED_LOGS followed by a
# error message. If it works, the bare URL followed
# by the tree_size will be written to LOGS
#
# If run with the --compare command line argument
# the script will output a list of all logs, and
# the number of sources that URL was found in

GOOGLE="./google_list.json"
CRT="./crt_list.html"
TMP="./logs.tmp"
LOGS="./logs.txt"
FAILED_LOGS="./failed_logs.txt"

rm "$TMP" "$LOGS" "$FAILED_LOGS" 2>/dev/null

if [ ! -f "${GOOGLE}" ]; then
    wget -q -O "$GOOGLE" https://www.gstatic.com/ct/log_list/all_logs_list.json
fi
if [ ! -f "${CRT}" ]; then
    wget -q -O "$CRT" https://crt.sh/monitored-logs
fi

# Can be used to check age of lists. Google log updates rarely,
# so i have commented out the code for now
#CRT_AGE="$(echo "($(date --utc +%s) - $(date +%s -r "$GOOGLE"))/86400" | bc)"
#GOOGLE_AGE="$(echo "($(date --utc +%s) - $(date +%s -r "$CRT"))/86400" | bc)"

#if [ $GOOGLE_AGE -gt 7 ] || [ $CRT_AGE -gt 7 ]; then
#    echo "[INFO] Google ($GOOGLE) or crt.sh ($CRT) CT-lits are older than " \
#        "7 days, consider deleting and redownloading." 2>&1
#fi

# cat "${CRT}" | grep -A 2 '<TR>' | sed -n '/no longer monitored/q;p' | \

cat "${CRT}" | grep -A 2 '<TR>' | \
    grep -v -E '<T[RH]>|--|rowspan' | \
    while read OPER;
    do
        read URL;
        echo -e "${URL}/\t${OPER}" | \
            sed -e 's#</*TD>##g' -e 's#^http.*://##' >> "$TMP"; 
    done

jq -r '.logs[] | "\(.url)\t\(.description)"' "${GOOGLE}" | \
    while read LOG;
    do
        echo -e "$LOG" >> "$TMP"
        URL="$(echo "$LOG" | cut -f 1)"
        HEAD="${URL}/ct/v1/get-sth"
    done;

if [ '--compare' == "$1" ]; then
    cat "$TMP" | cut -f 1 | sort | uniq -c | sort; exit
fi

cat "$TMP" | cut -f 1 | sort | uniq | \
    while read URL;
    do
        HEAD="https://${URL}ct/v1/get-sth"
        #echo $HEAD
        CURL_OPTS="--connect-timeout 5 --max-time 30 --insecure"
        OUTPUT=$(curl $CURL_OPTS -sSo - "$HEAD" 2>&1);
        RC=$?;
        if [ $RC -gt 0 ]; then
            echo "[FAIL] ${URL} failed: $(echo $OUTPUT | tr -d '\n')";
            echo "${URL} $(echo $OUTPUT | tr -d '\n')" >> "${FAILED_LOGS}";
        else
            TS=$(echo "$OUTPUT" | jq -r '.tree_size' 2>&1)
            RC=$?;
            if [ $RC -gt 0 ]; then
                echo "[FAIL] ${URL} failed: jq: $(echo $TS | tr -d '\n')";
                echo "${URL} jq: $(echo $TS | tr -d '\n')" >> "${FAILED_LOGS}";
            else
                echo "[OK] ${URL} ${TS}";
                echo "${URL} ${TS}" >> "${LOGS}"
            fi
        fi
    done;
rm "$TMP" 2>/dev/null
