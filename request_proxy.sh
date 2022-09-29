#!/bin/bash

BROKER_ID=broker.dev.ccp-it.dktk.dkfz.de pki/pki.sh request_ext_proxy $1

cp -v pki/$1*priv* richtige-zertifikate/
