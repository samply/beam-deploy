#!/bin/env bash

BROKER_ID=$(cat .env | grep "BROKER_ID=" | sed "s/BROKER_ID=//" | awk '{$1=$1};1')
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
LIST=$($SCRIPT_DIR/managepki warn 5)
SITES=()
echo $BROKER_ID
for entry in $LIST; do
  SITE=$(echo "$entry" | grep -e ":" | sed "s/://")
  if [ -n $SITE ]; then
    SITES+=($SITE)
  fi
done
for SITE in ${SITES[@]}; do
    $SCRIPT_DIR/managepki sign --csr-file "./csr/$SITE.csr" --common-name "$SITE.$BROKER_ID"
done
