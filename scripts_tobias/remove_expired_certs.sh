#!/usr/bin/env bash
VAULT_ADDR=127.0.0.1:8201
VAULT_TOKEN=$(cat ../pki/pki.secret)
curl -v -X POST \
  http://$VAULT_ADDR/v1/samply_pki/tidy \
  -H 'content-type: application/json' \
  -H "x-vault-token: $VAULT_TOKEN" \
  -d '{
    "tidy_cert_store": true
}'

