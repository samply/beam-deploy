#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
PKI_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && cd .. && cd pki && pwd)

echo "PKI_DIR: $PKI_DIR"

cd $SCRIPT_DIR

source "../.env"

[ -z "$BROKER_ID" ] && ( echo "BROKER_ID not set! Please check your .env file."; exit 1)
[ -z "$PROJECT" ] && ( echo "PROJECT not set! Please check your .env file."; exit 1)

function check_prereqs() {
     set +e
     if [[ "$(curl --version)" != *" libcurl/"* ]]; then
          echo "curl not found -- please install and put into PATH."
          exit 1
     fi
     if [[ "$(jq --version)" != *"jq-"* ]]; then
          echo "jq not found -- please install and put into PATH."
          exit 1
     fi
     set -e
}

function init_vault() {
     docker-compose exec -e VAULT_ADDR="http://127.0.0.1:8200" -it vault vault operator init -key-shares=1 -key-threshold=1 > "$PKI_DIR/init.tmp"
     cat "$PKI_DIR/init.tmp" | grep "Unseal Key" > "$PKI_DIR/unseal_key.secret"
     cat "$PKI_DIR/init.tmp" | grep "Root Token" | awk '{print $4}' > "$PKI_DIR/pki.secret" 
     rm "$PKI_DIR/init.tmp"
}

function unseal_vault() {
     docker-compose exec -e VAULT_ADDR="http://127.0.0.1:8200" vault vault operator unseal $(cat "$PKI_DIR/unseal_key.secret" | awk '{print $4}')
}

function create_root_ca() {
     docker-compose exec -e VAULT_ADDR="http://127.0.0.1:8200" -e VAULT_TOKEN=$VAULT_TOKEN vault vault secrets enable pki
     docker-compose exec -e VAULT_ADDR="http://127.0.0.1:8200" -e VAULT_TOKEN=$VAULT_TOKEN vault vault secrets tune -max-lease-ttl=87600h pki
     docker-compose exec -e VAULT_ADDR="http://127.0.0.1:8200" -e VAULT_TOKEN=$VAULT_TOKEN -e PROJECT vault \
	   vault write -field=certificate pki/root/generate/internal \
          common_name="Broker-Root" \
          issuer_name="${PROJECT}-CA-Root" \
          ttl=87600h > "$PKI_DIR/${PROJECT}_root_2022_ca.crt.pem"
     docker-compose exec -e VAULT_ADDR -e VAULT_TOKEN=$VAULT_TOKEN vault vault write pki/roles/2022-servers_root allow_any_name=true
     cp "$PKI_DIR/${PROJECT}_root_2022_ca.crt.pem" "$PKI_DIR/root.crt.pem"
}

function create_intermediate_ca() {
     docker-compose exec -e VAULT_ADDR="http://127.0.0.1:8200" -e VAULT_TOKEN=$VAULT_TOKEN vault vault secrets enable -path=samply_pki pki
     docker-compose exec -e VAULT_ADDR="http://127.0.0.1:8200" -e VAULT_TOKEN=$VAULT_TOKEN vault vault secrets tune -max-lease-ttl=43800h samply_pki
     docker-compose exec -e VAULT_ADDR="http://127.0.0.1:8200" -e VAULT_TOKEN=$VAULT_TOKEN -e BROKER_ID -it vault \
	   vault write -format=json samply_pki/intermediate/generate/internal \
          common_name="$BROKER_ID Intermediate Authority" \
          issuer_name="$BROKER_ID-intermediate" \
          | jq -r '.data.csr' > "$PKI_DIR/pki_intermediate.csr.pem"
     docker-compose exec -e VAULT_ADDR="http://127.0.0.1:8200" -e VAULT_TOKEN=$VAULT_TOKEN -e PROJECT -it vault \
	   vault write -format=json pki/root/sign-intermediate \
          issuer_ref="${PROJECT}-CA-Root" \
          csr=@pki/pki_intermediate.csr.pem \
          format=pem_bundle ttl="43800h" \
          | jq -r '.data.certificate' > "$PKI_DIR/intermediate.crt.pem"
     docker-compose exec -e VAULT_ADDR="http://127.0.0.1:8200" -e VAULT_TOKEN=$VAULT_TOKEN vault \
	   vault write samply_pki/intermediate/set-signed certificate=@pki/intermediate.crt.pem
     ISSUER=$(docker-compose exec -e VAULT_ADDR="http://127.0.0.1:8200" -e VAULT_TOKEN=$VAULT_TOKEN vault vault read -field=default samply_pki/config/issuers)
     docker-compose exec -e VAULT_ADDR="http://127.0.0.1:8200" -e VAULT_TOKEN=$VAULT_TOKEN -e BROKER_ID -it vault \
          vault write "samply_pki/roles/im-${PROJECT}" \
          issuer_ref="${ISSUER}" \
          allowed_domains="$BROKER_ID" \
          allow_subdomains=true \
          allow_glob_domains=true \
          max_ttl="720h"
}

function init() {
  	 echo "Starting vault for the first time"
     docker-compose up -d vault
     
     echo "Waiting 10 seconds for vault to start"
		 sleep 10

     echo "Initialize Vault"
     init_vault
     VAULT_TOKEN=$(cat "$PKI_DIR/pki.secret")

     echo "Unsealing Vault"
     unseal_vault

     echo "Creating Root CA"
     create_root_ca

     echo "Creating Intermediate CA"
     create_intermediate_ca

     echo "Successfully completed 'init'."
     echo "Your Vault Unseal Key is located in pki/unseal_key.secret. Please save it in an appropriate password manager and delete the file."
}


check_prereqs
init
