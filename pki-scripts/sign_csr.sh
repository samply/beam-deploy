#!/usr/bin/env bash

CSR_FILE="$1"
CN_CHECK="$2"

set -o errexit
set -o nounset
set -o pipefail

BASE_DIR=$( cd "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && cd .. && pwd)

source  "$BASE_DIR/.env"
VAULT_TOKEN=$(cat $BASE_DIR/pki/pki.secret)
[[ -z $TTL ]] && ( echo "TTL not set! Please check your .env file."; exit 1)
[[ -z $VAULT_ADDR ]] && ( echo "VAULT_ADDR not set! Please check your .env file."; exit 1)

FORMAT="pem"

function sign_csr(){
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
		$VAULT_ADDR/v1/samply_pki/sign/im-${PROJECT} | jq
}

if [[ -z $CSR_FILE ]]; then
	echo "Usage: $0 <csr-file>"
else
	sign_csr
fi
