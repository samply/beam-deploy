#!/bin/bash -e

set -o errexit
set -o nounset
set -o pipefail

function sign_privkey() {
  application="$1"
  cn="${application}.$BROKER_ID"
  CSR=$(mktemp)
  openssl req -new -key certificates/$1.priv.pem -out $CSR -subj "/CN=$cn"
  data="{\"csr\": \"$(sed ':a;N;$!ba;s/\n/\\n/g' $CSR)\", \"common_name\": \"$cn\", \"ttl\": \"$TTL\"}"
  curl --header "X-Vault-Token: $VAULT_TOKEN" \
       --request POST \
       --data "$data" \
  $VAULT_ADDR/v1/samply_pki/sign/im-${PROJECT} | jq . > pki/${application}.json
  cat pki/${application}.json | jq -r .data.certificate > pki/${application}.crt.pem
  cat pki/${application}.json | jq -r .data.ca_chain[] > pki/${application}.chain.pem
  rm $CSR
  echo "Success: PEM files stored to ${application}*.pem"
}

BASE_DIR=$( cd "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && cd .. && pwd)
source $BASE_DIR/.env
VAULT_TOKEN=$(cat $BASE_DIR/pki/pki.secret)

[[ -z $BROKER_ID ]] && (echo "BROKER_ID not set! Please check your .env file."; exit 1)
[[ -z $PROJECT ]] && (echo "PROJECT not set! Please check your .env file."; exit 1)
[[ -z $VAULT_ADDR ]] && (echo "VAULT_ADDR not set! Please check your .env file."; exit 1)

if [[ -z $1 ]]; then
  echo "Usage: $0 <private key>"
else
  sign_privkey "$1"
fi
