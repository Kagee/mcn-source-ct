#! /bin/bash
SOURCE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# This way we can work with realtive paths in the rest of the script
cd "${SOURCE_DIR}" || exit
# shellcheck disable=1091
source config.sh

# Slightly modified https://github.com/google/certificate-transparency-go/blob/master/client/ctclient/ctclient.go
CLIENT="/home/hildenae/go/src/ctclient/ctclient_simple"

ME="$(basename "${BASH_SOURCE[0]}")"

LOGS="$(cat logs.txt | grep -v -E 'ct.gdca.com.cn|ctserver.cnnic.cn|ct.sheca.com' )"

# 2018/06/22 18:57:15 Get https://ct.gdca.com.cn/ct/v1/get-entries?end=2&start=0: x509: certificate has expired or is not yet valid
# 2018/06/22 18:57:27 Get https://ctserver.cnnic.cn/ct/v1/get-entries?end=2&start=0: x509: certificate signed by unknown authority
#2018/06/22 18:57:28 Get https://ct.sheca.com/ct/v1/get-entries?end=2&start=0: x509: certificate signed by unknown authority

# TODo: make global logfile (per log?). Add timestamp to log-funcs
STEP=999

function url_to_safe {
  echo "${1:-}" | sed -e 's#/$##' -e 's/[^a-z0-9-]/_/g'
}

function get_sth {
  #echo $@
  LOG_URI="${1:-}"
  STH="$($CLIENT -log_uri "https://$LOG_URI" -logtostderr sth 2>&1)"
  VERSION="$(echo "$STH" | awk '/sth.Version/{print $2}')"
  if [ "V1" != "$VERSION" ]; then
    ERROR "Log version $VERSION is unknown in $LOG_URI [$ME/${FUNCNAME[0]}]"
    exit 1
  fi
  echo "$STH"
}


function get_size {
  LOG_URI="${1:-}"
  SIZE="$(get_sth "$LOG_URI" | awk '/sth.TreeSize/{print $2}')"
  INFO "Queried size of $LOG_URI: $SIZE [$ME/${FUNCNAME[0]}]"
  echo "$SIZE"
}

function logs {
  echo "$LOGS"
}

LAST=0

function get_from {
  LOG_URI="${1:-}"
  SIZE="${2:-}"
  FIRST="${3:-}"
  #set -x
  LAST="$(echo "$FIRST + $STEP" | bc)"
  INFO "first: $FIRST last: $LAST size: $SIZE. [$ME/${FUNCNAME[0]}]"
  if ! [ $FIRST -lt $SIZE ]; then
    ERROR "first ($FIRST) is greater than size ($SIZE) of log $LOG_URI. [$ME/${FUNCNAME[0]}]"
    exit 2
  elif [ $LAST -gt $SIZE ]; then
    INFO "last ($LAST) is greater than size ($SIZE), setting last=size for log $LOG_URI. [$ME/${FUNCNAME[0]}]"
    LAST="$SIZE"
  fi
  PFIRST="$(printf "%011d" $FIRST)"

  mkdir -p "$CACHE_PATH/se_$(url_to_safe "$LOG_URI")"
  TMP1="$(mktemp "$CACHE_PATH/c-$(url_to_safe "$LOG_URI")-$PFIRST-XXXXXXXXXX.certs")"
  TMP2="$(mktemp "$CACHE_PATH/c-$(url_to_safe "$LOG_URI")-$PFIRST-XXXXXXXXXX.certs")"
  $CLIENT -log_uri "https://$LOG_URI" -first "$FIRST" -last "$LAST" -logtostderr getentries &> "$TMP1"
  RC=$?
  if [ $RC -ne 0 ]; then
    mv "$TMP1" "$TMP1.error"
    rm "$TMP2"
    ERROR "Last get from $LOG_URI terminated with exit code $RC. See $TMP1.error for details."
    exit 1
  fi
  LAST="$(cat "$TMP1" | grep -P '^Index=' | tail -1 | awk '{ print $1}' | sed -e 's/Index=//')"
  cat "$TMP1" | grep -a -F '.no' | xz --compress --stdout > "$TMP2"

  PLAST="$(printf "%011d" $LAST)"
  OUTPUT_FILE="$PFIRST-$PLAST.xz"
  PREFIX="$(echo "$OUTPUT_FILE" | md5sum | cut -c 1,2)"
  OUTPUT_PREFIX="$CACHE_PATH/se_$(url_to_safe "$LOG_URI")/${PREFIX}"
  mkdir -p "$OUTPUT_PREFIX"
  mv "$TMP2" "$OUTPUT_PREFIX/$OUTPUT_FILE"
  echo "$LAST" > "$CACHE_PATH/se_$(url_to_safe "$LOG_URI")/last"
  rm "$TMP1"
}

function do_whole_log {
  #set -x
  LOG_URI="${1:-}"
  SIZE="$(get_size "$LOG_URI")"
  if [ "x" = "x$SIZE" ]; then
    exit 1
  fi

  INFO "Size of log: $SIZE. [$ME/${FUNCNAME[0]}]"
  INFO "Number of downloads: $(echo "$SIZE / 1000" | bc). [$ME/${FUNCNAME[0]}]"
  INFO "Calulating highest cert downloaded: ... [$ME/${FUNCNAME[0]}]"
  TIMESTAMP="$(date +%F-%T | tr ':' '-')"
  ATOM="$CACHE_PATH/$(url_to_safe "$LOG_URI").pid"
  if [ -f "$ATOM" ]; then
    ERROR "Log $LOG_URI already running: $(cat "$ATOM") ($ATOM) [$ME/${FUNCNAME[0]}]"
    exit 0
  fi
  mkdir -p "$CACHE_PATH"
  echo "$TIMESTAMP $$" > "$ATOM"
  INFO "Log $LOG_URI not running, continuing. [$ME/${FUNCNAME[0]}]"

  OUTPUT_PREFIX="$CACHE_PATH/se_$(url_to_safe "$LOG_URI")"
  HIGHEST="$(cat "$CACHE_PATH/se_$(url_to_safe "$LOG_URI")/last" 2>/dev/null)"
  #HIGHEST="$(find "$OUTPUT_PREFIX" -type f -name '*.xz' 2>/dev/null | rev | cut -d- -f1 | rev | sort -n | tail -1 | cut -d. -f1 | sed -e 's/^0*//')"
  if [ "x$HIGHEST" = "x" ]; then
    INFO " ... none found, starting at 1. [$ME/${FUNCNAME[0]}]"
    HIGHEST=1
    FROM="$HIGHEST"
  else
    INFO " ... found $HIGHEST. [$ME/${FUNCNAME[0]}]"
    FROM="$(echo "$HIGHEST + 1" | bc)"
  fi
  INFO "Current time is $TIMESTAMP. Starting download of $LOG_URI from $FROM to $SIZE. [$ME/${FUNCNAME[0]}]"
  while [ $FROM -lt $SIZE ]; do
    TIMESTAMP="$(date +%F-%T | tr ':' '-')"
    NEXT="$(echo "$FROM + $STEP + 1" | bc)"
    INFO "Downloading $FROM to $NEXT from $LOG_URI. ($TIMESTAMP) [$ME/${FUNCNAME[0]}]"
    get_from "$LOG_URI" "$SIZE" "$FROM"
    RNEXT="$(echo "1 + $(cat "$CACHE_PATH/se_$(url_to_safe "$LOG_URI")/last")" | bc)"
    INFO "Next: $NEXT Real next: $RNEXT Step: $STEP"
    if [ $RNEXT -lt $NEXT ]; then
      #STEP="$(echo "$RNEXT - $FROM" | bc)"
      #INFO "Real next ($RNEXT) is less than next ($NEXT), resetting step to $STEP ($RNEXT - $FROM = $STEP)"
      NEXT="$RNEXT"
    fi
    FROM="$NEXT"
  done
  INFO "Next to download ($FROM) is larger size ($SIZE) of log $LOG_URI, graceful exit. [$ME/${FUNCNAME[0]}]"
  rm "$ATOM"
}

case "$1" in
  size)
    get_size "$2"
    ;;
  from)
    get_from "$2" "$3" "$4"
    ;;
  logs)
    logs
    ;;
  download_log)
    do_whole_log $2
  ;;
  count)
    find cache/ -type f -name '*.xz' -exec xzcat {} \; | ../mcn-tools/default_extract
  ;;
  *)
    echo $"Usage: $0 {logs|size <log>|download_log <log>|from <log> <from>"
    exit 1
esac
