#!/bin/bash -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
ME="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")"

[ -z "$BROKER_ID" ] && ( echo "BROKER_ID not set!"; exit 1)
export BROKER_ID

cd $SCRIPT_DIR
export VAULT_TOKEN=$(cat pki.secret)
export VAULT_ADDR=http://127.0.0.1:8200

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

function start() {
  case "$1" in
    dev)
      docker_compose_file="../docker-compose-dev.yml"
    ;;
    central)
      docker_compose_file="../docker-compose-central.yml"
    ;;
    local)
      docker_compose_file="../docker-compose-local.yml"
    ;;
  esac
  docker-compose -f $docker_compose_file up -d vault
}

function clean() {
  rm -vf *.pem *.json
  case "$1" in
    dev)
      docker_compose_file="../docker-compose-dev.yml"
    ;;
    central)
      docker_compose_file="../docker-compose-central.yml"
    ;;
    local)
      docker_compose_file="../docker-compose-local.yml"
    ;;
  esac
  docker-compose -f $docker_compose_file down
}

function create_root_ca() {
     vault secrets enable pki
     vault secrets tune -max-lease-ttl=87600h pki
     vault write -field=certificate pki/root/generate/internal \
          common_name="Broker-Root" \
          issuer_name="root-2022" \
          ttl=87600h > dktk_root_2022_ca.crt.pem
     vault write pki/roles/2022-servers_root allow_any_name=true
}

function create_intermediate_ca() {
     vault secrets enable -path=samply_pki pki
     vault secrets tune -max-lease-ttl=43800h samply_pki
     vault write -format=json samply_pki/intermediate/generate/internal \
          common_name="$BROKER_ID Intermediate Authority" \
          issuer_name="$BROKER_ID-intermediate" \
          | jq -r '.data.csr' > pki_intermediate.csr.pem
     vault write -format=json pki/root/sign-intermediate \
          issuer_ref="root-2022" \
          csr=@pki_intermediate.csr.pem \
          format=pem_bundle ttl="43800h" \
          | jq -r '.data.certificate' > intermediate.crt.pem
     vault write samply_pki/intermediate/set-signed certificate=@intermediate.crt.pem
     vault write samply_pki/roles/im-dot-dktk-dot-com \
          issuer_ref="$(vault read -field=default samply_pki/config/issuers)" \
          allowed_domains="$BROKER_ID" \
          allow_subdomains=true \
          allow_glob_domains=true \
          max_ttl="720h"
}

function request_proxy() {
     application="${1:-app1}"
     cn="${application}.$BROKER_ID"
     request "$application" "$cn"
}

function request() {
     application=$1
     cn=$2
     data="{\"common_name\": \"$cn\", \"ttl\": \"24h\"}"
     echo $data
     echo "Creating Certificate for domain $cn"
     curl --header "X-Vault-Token: $VAULT_TOKEN" \
          --request POST \
          --data "$data" \
     $VAULT_ADDR/v1/samply_pki/issue/im-dot-dktk-dot-com | jq . > ${application}.json
     cat ${application}.json | jq -r .data.certificate > ${application}.crt.pem
     cat ${application}.json | jq -r .data.ca_chain[] > ${application}.chain.pem
     cat ${application}.json | jq -r .data.private_key > ${application}.priv.pem
     echo "Success: PEM files stored to ${application}*.pem"
}

function init() {
#     echo "Cleaning Up Old Certificates and Keys"
#     clean

     echo "Creating Root CA"
     create_root_ca

     echo "Creating Intermediate HD CA"
     create_intermediate_ca

     echo "Successfully completed 'init'."
}

cd $SCRIPT_DIR

check_prereqs

case "$1" in
  start)
    start $2
    ;;
  clean)
    clean $2
    ;;
  init)
    init
    ;;
  request_proxy)
    request_proxy $2
    tar czf "$2_secrets.tar.gz" pki.secret "$2.priv.pem"
    ;;
  setup_central)
    clean central
    start central
    while ! [ "$(curl -s $VAULT_ADDR/v1/sys/health | jq -r .sealed)" == "false" ]; do echo "Waiting ..."; sleep 0.1; done
    docker-compose exec vault sh -c "https_proxy=$http_proxy apk add --no-cache bash curl jq"
    docker-compose exec vault sh -c "VAULT_TOKEN=$VAULT_TOKEN http_proxy= HTTP_PROXY= BROKER_ID=$BROKER_ID /pki/pki.sh init"
    docker-compose exec vault sh -c "VAULT_TOKEN=$VAULT_TOKEN http_proxy= HTTP_PROXY= BROKER_ID=$BROKER_ID /pki/pki.sh request_proxy dummy"
    ;;
  devsetup)
    #          set -m # job control
    [ -z "$PROXY1_ID" ] && ( echo "PROXY1_ID not set!"; exit 1)
    [ -z "$PROXY2_ID" ] && ( echo "PROXY2_ID not set!"; exit 1)
    export PROXY1_ID
    export PROXY2_ID
    export PROXY1_ID_SHORT=$(echo $PROXY1_ID | cut -d '.' -f 1)
    export PROXY2_ID_SHORT=$(echo $PROXY2_ID | cut -d '.' -f 1)
    export BROKER_ID=$(echo $PROXY1_ID | cut -d '.' -f 2-)
    clean dev
    touch ${PROXY1_ID_SHORT}.priv.pem # see https://github.com/docker/compose/issues/8305
    touch ${PROXY2_ID_SHORT}.priv.pem # see https://github.com/docker/compose/issues/8305
    start dev
    while ! [ "$(curl -s $VAULT_ADDR/v1/sys/health | jq -r .sealed)" == "false" ]; do echo "Waiting ..."; sleep 0.1; done
    docker-compose exec vault sh -c "https_proxy=$http_proxy apk add --no-cache bash curl jq"
    docker-compose exec vault sh -c "VAULT_TOKEN=$VAULT_TOKEN http_proxy=
    HTTP_PROXY= BROKER_ID=$BROKER_ID /pki/pki.sh init"
    docker-compose exec vault sh -c "VAULT_TOKEN=$VAULT_TOKEN http_proxy= HTTP_PROXY= BROKER_ID=$BROKER_ID /pki/pki.sh request_proxy $PROXY1_ID_SHORT"
    docker-compose exec vault sh -c "VAULT_TOKEN=$VAULT_TOKEN http_proxy= HTTP_PROXY= BROKER_ID=$BROKER_ID /pki/pki.sh request_proxy $PROXY2_ID_SHORT"
    docker-compose exec vault sh -c "VAULT_TOKEN=$VAULT_TOKEN http_proxy= HTTP_PROXY= BROKER_ID=$BROKER_ID /pki/pki.sh request_proxy dummy"
    ;;
  *)
    echo "Usage: $0 start|init|setup_central|devsetup|(request_proxy [AppName])"
    ;;
esac
