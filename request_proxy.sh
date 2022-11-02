#!/bin/bash

pki/pki.sh request_ext_proxy $1

cp -v pki/$1*priv* richtige-zertifikate/
