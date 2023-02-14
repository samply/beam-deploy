#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

echo -e "Note: This tool should not be used for registering beam proxies. Instead, use beam-enroll to create a CSR and managepki (https://hub.docker.com/r/samply/managepki) to accept it.\n"

function request_proxy() {
     application="${1:-app1}"
     cn="${application}.$BROKER_ID"
     request "$application" "$cn"
}

function request() {
     application=$1
     cn=$2
     data="{\"common_name\": \"$cn\", \"ttl\": \"$TTL\"}"
     echo $data
     echo "Creating Certificate for domain $cn"
     echo "Sending to ${VAULT_ADDR}"
     echo "Token: $VAULT_TOKEN"
     curl --header "X-Vault-Token: $VAULT_TOKEN" \
          --request POST \
          --data "$data" \
     $VAULT_ADDR/v1/samply_pki/issue/im-${PROJECT} | jq . > pki/${application}.json
     cat pki/${application}.json | jq -r .data.certificate > pki/${application}.crt.pem
     cat pki/${application}.json | jq -r .data.ca_chain[] > pki/${application}.chain.pem
     cat pki/${application}.json | jq -r .data.private_key > pki/${application}.priv.pem
     echo "Success: PEM files stored to ${application}*.pem"
}

BASE_DIR=$( cd "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && cd .. && pwd)
source "$BASE_DIR/.env"
VAULT_TOKEN=$(cat $BASE_DIR/pki/pki.secret)
[[ -z $VAULT_ADDR ]] && ( echo "VAULT_ADDR not set! Please check your .env file."; exit 1)

if [[ -z ${1:-} ]]; then
  echo "Usage: $0 <proxy_shortname>"
  exit 1
fi

request_proxy $1
mkdir -p certificates
cp -v pki/$1*priv* certificates/
