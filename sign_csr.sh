#!/usr/bin/env bash

source .env

CSR_FILE="$1"
CN_CHECK="$2"

set -u

TTL="720h"
FORMAT="pem"
VAULT_ADDR=http://127.0.0.1:8201
VAULT_TOKEN=$(cat ./pki/pki.secret)

if [[ -z $CSR_FILE ]]; then
	echo "Usage: $0 <csr-file>"
else
	COMMON_NAME="$(openssl req -in $CSR_FILE -subject -noout | sed "s/.*CN = \(.*\),.*/\1/g")"
	echo "CSR asks for CN $COMMON_NAME"
	if [[ "$CN_CHECK" != "$COMMON_NAME" ]]; then
		echo "Run $0 $CSR_FILE $COMMON_NAME to confirm signing this CSR."
		exit 0
	fi
	CSR=$(cat $CSR_FILE)
	JSON_STRING=$( jq -n \
		--arg csr "$CSR" \
		--arg ttl "$TTL" \
		--arg format "$FORMAT" \
		--arg common_name "$COMMON_NAME" \
		--arg alt_names "$COMMON_NAME" \
		'{csr: $csr, ttl: $ttl, format: $format, common_name: $common_name, alt_names: $alt_names}')
	curl	--header "X-Vault-Token: $VAULT_TOKEN" \
		--data "$JSON_STRING" \
		--request POST \
		$VAULT_ADDR/v1/samply_pki/sign/im-dot-dktk-dot-com | jq
fi
