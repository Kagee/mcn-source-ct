#! /bin/bash
source config.sh

NEWEST_TS="$(find data -type f -name '*.der' -print0 | xargs -0 stat --format '%Y :%y %n' | sort -nr | head -1 | cut -d' ' -f1)"
AGE=$(echo "($(date --utc +%s) - ${NEWEST_TS})/86400" | bc)

if [ $AGE -gt 7 ]; then
  echo "WARNING: The newest certificate found is $AGE days old. You might want to update with get_certs.sh" 1>&2
fi

exit

if [ ! -e "./enhetsregisteret.list" ] || [ "x$1" = "x--update-list" ]; then
    cat ./enhetsregisteret.csv | ../../scraper/default_extract > ./enhetsregisteret.list
fi

