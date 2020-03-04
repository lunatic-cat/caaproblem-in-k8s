#!/bin/bash
set -uo pipefail

RED="\033[1;31m"
GREEN="\033[1;32m"
NOCOLOR="\033[0m"

if [[ $# -eq 0 ]]; then
    echo "Pass list of 'LANG=C sort'-ed bad serial nubers as first argument to skip download..."
    url='https://d4twhgtvn0ff5.cloudfront.net/caa-rechecking-incident-affected-serials.txt.gz'
    serials=$(mktemp)
    cmd="curl ${url} | gunzip | sed -e 's:^serial ::g' -e 's: .*::g' | LANG=C sort -u > ${serials}"
    echo "Doing: \"${cmd}\""
    bash -c "${cmd}"
else
    serials=$1
fi

check() {
    local ns=$1
    local certtype=$2
    local certname=$3

    local secret=$(kubectl -n ${ns} get ${certtype} ${certname} -o "jsonpath={.spec.secretName}")
    local cert=$(kubectl -n ${ns} get secret ${secret} -o "jsonpath={.data.tls\.crt}" | base64 -D)

    local dns=$(echo "${cert}" | openssl x509 -noout -text | grep 'DNS:' | sed -e 's/DNS://g' -e 's:^ *::g')
    local serial=$(echo "${cert}" | openssl x509 -noout -serial | sed 's:^serial=::g' | tr '[:upper:]' '[:lower:]')
    
    look ${serial} ${serials} > /dev/null
    local renew=$?
    if [[ $renew -eq 0 ]]; then
        # TODO: automatically upgrade
        echo -e "[ ${RED}FAIL${NOCOLOR} ] ${ns}/${certname} [${dns}] serial=${serial}"
    else
        echo -e "[  ${GREEN}OK${NOCOLOR}  ] ${ns}/${certname} [${dns}] serial=${serial}"
    fi
}

echo "Getting all certificates from all namespaces, please be patient..."
for ns in $(kubectl get ns -o name | awk -F'/' '{ print $2 }'); do
    # new cert-manager misses some certs in `kubectl get certificates`
    for certname in $(kubectl get certificate.cert-manager.io -o name -n ${ns} | awk -F'/' '{ print $2 }'); do
        check ${ns} "certificate.cert-manager.io" ${certname}
    done
done

if [[ $# -eq 0 ]]; then
    echo "Cleaning up ${serials}"
    rm -f ${serials}
fi