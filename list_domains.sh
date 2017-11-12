#! /bin/bash
source config.sh

if [ ! -e "./enhetsregisteret.list" ] || [ "x$1" = "x--update-list" ]; then
    cat ./enhetsregisteret.csv | ../../scraper/default_extract > ./enhetsregisteret.list
fi

