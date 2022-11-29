#!/usr/bin/env bash

set -u

TTL="720h"
FORMAT="pem"
VAULT_ADDR=http://127.0.0.1:8201
VAULT_TOKEN=$(cat ./pki/pki.secret)

# The following is bad practice -- this script should expect exactly one CSR (file or stdin)
for f in ./*.csr; do
	CSR_NAME=$f
	PROXY_NAME=$(echo ${CSR_NAME:2} | awk -F "." '{print $1}')
	echo "Signing CSR for $PROXY_NAME"
	COMMON_NAME=${PROXY_NAME}.broker.dev.ccp-it.dktk.dkfz.de
	CSR=$(cat $CSR_NAME)
	JSON_STRING=$( jq -n \
		--arg csr "$CSR" \
		--arg ttl "$TTL" \
		--arg format "$FORMAT" \
		--arg common_name "$COMMON_NAME" \
		--arg alt_names "$COMMON_NAME" \
		'{csr: $csr, ttl: $ttl, format: $format, common_name: $common_name, alt_names: $alt_names}')
	curl -v --header "X-Vault-Token: $VAULT_TOKEN" \
		--data "$JSON_STRING" \
		--request POST \
		$VAULT_ADDR/v1/samply_pki/sign/im-dot-dktk-dot-com | jq
done
