#! /bin/bash
openssl x509 -inform der -in "$1" -text
