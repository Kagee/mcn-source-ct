#! /bin/bash
# MCN_TOOLS have moved to system config file
source "$HOME/.mcn.conf"

STORAGE_PATH="$PWD/data"
CACHE_PATH="$PWD/cache"
THREADS="$(nproc --ignore 1)"

PROTOBUF="$CT_PATH/protobuf/python"
PYTHON_CT="$CT_PATH/certificate-transparency/python"


DOMAINS="mcn-source-ct.list"
