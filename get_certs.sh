#! /bin/bash
# 1. build https://github.com/google/certificate-transparency per instructions
# 2. Install ABSL: sudo pip2 install absl-py 
# 3. build python protobuf bindings? in ct/protobuf/python using "python setup.py build"
# 4. Set path to CT-folder here: 
CT_PATH="$HOME/ct"
PROTOBUF="$CT_PATH/protobuf/python"
PYTHON_CT="$CT_PATH/certificate-transparency/python"
#ls "$CT_PATH"
# PYTHONPATH=../../../:../../../../../protobuf/python ./simple_scan.py --output $PWD/ct.googleapis.com_rocketeer/ --log 'https://ct.googleapis.com/rocketeer' --startat 164390275 --multi 8
cat logs.txt | while read LOGINFO; do
    URL=$(echo "$LOGINFO" | cut -d ' ' -f 1);
    FOLDER=$(echo "$URL" | tr '/' '_')
    SSL=$(echo "$LOGINFO" | cut -d ' ' -f 2);
    echo "URL: ${URL}, SSL: ${SSL}";
    COUNT=$(find "data/${FOLDER}" -name '*.der' | wc -l)
    LAST=$(ls -tr "data/${FOLDER}/" | grep -F '.der' | tail -1 | sed -e 's/cert_//' -e 's/\.der//')
    echo "COUNT: ${COUNT}, LAST: ${LAST}"
done

