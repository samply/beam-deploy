#!/bin/bash

set -e
set -u

BASE_DIR=$( cd "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && cd .. && pwd)

##################################
# Table functions from: https://stackoverflow.com/a/49180405
function printTable()
{
    local -r delimiter="${1}"
    local -r data="$(removeEmptyLines "${2}")"

    if [[ "${delimiter}" != '' && "$(isEmptyString "${data}")" = 'false' ]]
    then
        local -r numberOfLines="$(wc -l <<< "${data}")"

        if [[ "${numberOfLines}" -gt '0' ]]
        then
            local table=''
            local i=1

            for ((i = 1; i <= "${numberOfLines}"; i = i + 1))
            do
                local line=''
                line="$(sed "${i}q;d" <<< "${data}")"

                local numberOfColumns='0'
                numberOfColumns="$(awk -F "${delimiter}" '{print NF}' <<< "${line}")"

                # Add Line Delimiter

                if [[ "${i}" -eq '1' ]]
                then
                    table="${table}$(printf '%s#+' "$(repeatString '#+' "${numberOfColumns}")")"
                fi

                # Add Header Or Body

                table="${table}\n"

                local j=1

                for ((j = 1; j <= "${numberOfColumns}"; j = j + 1))
                do
                    table="${table}$(printf '#| %s' "$(cut -d "${delimiter}" -f "${j}" <<< "${line}")")"
                done

                table="${table}#|\n"

                # Add Line Delimiter

                if [[ "${i}" -eq '1' ]] || [[ "${numberOfLines}" -gt '1' && "${i}" -eq "${numberOfLines}" ]]
                then
                    table="${table}$(printf '%s#+' "$(repeatString '#+' "${numberOfColumns}")")"
                fi
            done

            if [[ "$(isEmptyString "${table}")" = 'false' ]]
            then
                echo -e "${table}" | column -s '#' -t | awk '/^\+/{gsub(" ", "-", $0)}1'
            fi
        fi
    fi
}

function removeEmptyLines()
{
    local -r content="${1}"

    echo -e "${content}" | sed '/^\s*$/d'
}

function repeatString()
{
    local -r string="${1}"
    local -r numberToRepeat="${2}"

    if [[ "${string}" != '' && "${numberToRepeat}" =~ ^[1-9][0-9]*$ ]]
    then
        local -r result="$(printf "%${numberToRepeat}s")"
        echo -e "${result// /${string}}"
    fi
}

function isEmptyString()
{
    local -r string="${1}"

    if [[ "$(trimString "${string}")" = '' ]]
    then
        echo 'true' && return 0
    fi

    echo 'false' && return 1
}

function trimString()
{
    local -r string="${1}"

    sed 's,^[[:blank:]]*,,' <<< "${string}" | sed 's,[[:blank:]]*$,,'
}

##################################

VAULT_ADDR=${2:-http://127.0.0.1:8201}
VAULT_TOKEN="$(cat $BASE_DIR/pki/pki.secret)"

serials=()
serials+=$(curl -s -X LIST -H "X-Vault-Token: $VAULT_TOKEN" $VAULT_ADDR/v1/samply_pki/certs | jq .data.keys[] | sed "s/\"//g")
entry=()
from_regex='Not Before: (.*) Not After'
until_regex='Not After : (.*) Subject:'
cn_regex='Subject: CN = (.*) Subject Pub'
for ser in $serials; do
	reply=$(curl -s -X GET -H "X-Vault-Token: $VAULT_TOKEN" $VAULT_ADDR/v1/samply_pki/cert/$ser)
	cert=$(echo $reply | jq .data.certificate | sed "s/\"//g" | sed "s/\\\n/\n/g" | openssl x509 -noout -text)
	if [[ "$cert" =~ $from_regex ]]; then
		from="${BASH_REMATCH[1]}"
	else
		from="Missing"
	fi
	if [[ $cert =~ $until_regex ]]; then
		until="${BASH_REMATCH[1]}"
	else
		until="Missing"
	fi
	if [[ $cert =~ $cn_regex ]]; then
		cn="${BASH_REMATCH[1]}"
	else
		cn="Missing"
	fi
	revocation=$(echo $reply | jq .data.revocation_time)
	entry+="$cn,$ser,$from,$until,$revocation\n"
done
printTable ',' "CN,Serial,Valid From,Valid Until,Revocation Time\n$entry"
#testpattern='Not Before: (.*) Not After'
#while [[ $(cat test.out) =~ $testpattern ]]; do
#	echo ${BASH_REMATCH[1]}
#done
