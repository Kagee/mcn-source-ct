#! /bin/bash
# MCN_TOOLS have moved to system config file
source "$HOME/.mcn.conf"

STORAGE_PATH="$PWD/data"
THREADS="$(nproc --ignore 1)"

DOMAINS="mcn-source-ct.list"
