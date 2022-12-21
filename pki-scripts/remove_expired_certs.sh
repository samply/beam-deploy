#!/usr/bin/env bash

set -e
set -u

BASE_DIR=$( cd "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && cd .. && pwd)

VAULT_ADDR=127.0.0.1:8200
VAULT_TOKEN="$(cat $BASE_DIR/pki/pki.secret)"
curl -X POST \
  http://$VAULT_ADDR/v1/samply_pki/tidy \
  -H 'content-type: application/json' \
  -H "x-vault-token: $VAULT_TOKEN" \
  -d '{
    "tidy_cert_store": true
}' | jq

