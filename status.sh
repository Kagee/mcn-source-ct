#! /bin/bash

SOURCE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# This way we can work with realtive paths in the rest of the script
cd "${SOURCE_DIR}"
source config.sh


OUTPUT=$(LOGS="$(cat logs.txt)"
SORT=$1
if [ "x$SORT" = "x" ]; then 
 SORT=4;
fi
#echo "#CRT LAST_MATCH LAST_CHECKED TREE_SIZE DIFF % R TS_LC URL"
echo "#CRT TREE_SIZE DIFF % R TS_LC URL COUNT_AT"

echo "$LOGS" | while read LOGINFO; do
    URL=$(echo "$LOGINFO" | cut -d ' ' -f 1 | sed -e 's#/$##');
    TREE_SIZE=$(echo "$LOGINFO" | cut -d ' ' -f 2);
    COUNT_AT="$(echo "a=(${TREE_SIZE} * 0.00999999999999); " \
      "if (a > 1) if (a > 10000) print 10000 else print (a/1) else print 1" | bc)"
    WORKDIR="${STORAGE_PATH}/$(echo "$URL" | tr '/' '_')"

    if [ ! -d "${WORKDIR}" ]; then
       echo "[ERROR] ${WORKDIR} finnes ikke" 1>&2
    else
        RUNNING=" "
        if [ -f "${WORKDIR}/running" ]; then
          RUNNING="$(cat "${WORKDIR}/running" | cut -c1)"
	  if [ "$RUNNING" = "R" ]; then
		RUNNING="$(cat "${WORKDIR}/running" | awk '{ print $3}')"
	  fi
        fi
        TS_LC="0000-00-00-00-00"
        TS_LC="$(stat -c %y "${WORKDIR}/last.log" | cut -d- -f 2,3 | cut -d: -f1,2 | tr '[ ]' 'T')"
        LAST_CHECKED=0
        if [ -f "${WORKDIR}/last.checked" ]; then
            LAST_CHECKED="$(cat "${WORKDIR}/last.checked")"
        fi
        DERS="$(find "${WORKDIR}" -name '*.der' -printf "%f\n")"
        #PREV_MATCHES="$(find "${WORKDIR}" -name '*.der' | wc -l)"
        PREV_MATCHES="$(echo "${DERS}" | wc -l)"
        #LAST_MATCH="$(ls "${WORKDIR}/" | grep -F '.der' | \
        LAST_MATCH="$(echo "${DERS}" | \
                sed -e 's/cert_//' -e 's/\.der//' | sort -n | tail -1)"
        if [ "x${LAST_MATCH}" = "x" ]; then
            LAST_MATCH="0"
        fi
        MAX=$(echo -e "0\n${LAST_MATCH}\n${LAST_CHECKED}" | sort -n | tail -1)
        P=$(echo "(${MAX}/${TREE_SIZE})*100" | bc -l |  cut -c 1,2,3,4,5|tr '.' ','); #cut -d'.' -f1);
        DIFF=$(echo "${TREE_SIZE} -${MAX}" | bc -l)
        if [ "x${P}" = "x" ]; then
            P="0.00"
        fi
        if [ ${TREE_SIZE} -gt 10 ]; then
            #echo "${PREV_MATCHES} ${LAST_MATCH} ${LAST_CHECKED} ${TREE_SIZE} ${DIFF} ${P}% ${RUNNING} ${TS_LC} ${URL}"
          echo "${PREV_MATCHES} ${TREE_SIZE} ${DIFF} ${P}% ${RUNNING} ${TS_LC} ${URL} $COUNT_AT"
        fi
        #(N=$(grep "Certificate index:" "${WORKDIR}/last.log" | \
        #grep -o -P '\d*' | sort -n | \
        #tail -1); echo -e "0\n${N}\n${LAST_MATCH}\n$(cat "${WORKDIR}/last.checked")" | \
        #sort -n | tail -1 > "${WORKDIR}/last.checked");
        #echo "LAST_CHECKED: $(cat "${WORKDIR}/last.checked")"
    fi
done | sort -t ' ' -n -k $SORT -k 4 -k 5;
# done | sort -t ' ' -n -k 6 -k 4 -k 5;
#echo "#CRT LAST_MATCH LAST_CHECKED TREE_SIZE DIFF % R TS_LC URL"
echo "#CRT TREE_SIZE DIFF % R TS_LC URL"

) 
echo "$OUTPUT" | column -t
