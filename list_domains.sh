#! /bin/bash
source config.sh

if [ ! -e "$DOMAINS" ] || [ "x$1" = "x--update" ]; then
    echo "INFO: Calculating certificate data age. This may take some time." 1>&2
    NEWEST_TS="$(find data -type f -name '*.der' -print0 | xargs -0 stat --format '%Y :%y %n' | sort -nr | head -1 | cut -d' ' -f1)"
    AGE=$(echo "($(date --utc +%s) - ${NEWEST_TS})/86400" | bc)
    if [ $AGE -gt 7 ]; then
        echo "WARNING: The newest certificate found is $AGE days old. You might want to retrive new certificates using 'get_certs.sh'" 1>&2
    else
        echo "INFO: Certificate data less that 7 days old. Continuing." 1>&2
    fi
    echo "INFO: Extracting valid .no domains. This may take a LONG time." 1>&2
    find "${STORAGE_PATH}/" -type f -exec openssl x509 -inform der -in "{}" -text \; | \
    ${MCN_TOOLS}/default_extract > "$DOMAINS"
fi
if [ -e "$DOMAINS" ]; then
    LIST_AGE="$(stat --format '%Y' "$DOMAINS")"
    NOw="$(date --utc +%s)"
    AGE=$(echo "(${NOW} - ${LIST_AGE})/86400" | bc)
    if [ $AGE -gt 7 ]; then
        echo "WARNING: The cached list is $AGE days old. You might want to generate a new one using 'get_certs.sh' and 'list_domains.sh --update'" 1>&2
    fi
    cat "$DOMAINS";
fi

