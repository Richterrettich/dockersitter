#!/bin/bash

openssl genrsa -out ${1}.key 4096
openssl req -new -subj "/CN=$1" -nodes -sha256 -key ${1}.key -out ${1}.csr
openssl x509 -req -in ${1}.csr -sha256 -CA rootCA.crt -CAkey rootCA.key -CAcreateserial -out ${1}.crt -days 7800
mv ${1}.* ../../proxy/certs/
