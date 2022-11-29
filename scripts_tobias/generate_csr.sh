#!/usr/bin/env bash

source .env

set -u

for f in ./*.pem; do
	PROXYNAME=$(echo ${f:2} | awk -F "." '{print $1}')
	echo "Generate CSR for ${PROXYNAME}"
	openssl req -new -key $f -out $PROXYNAME.csr -subj "/C=DE/O=DKTK/CN=${PROXYNAME}.${BROKER_ID}"
done
