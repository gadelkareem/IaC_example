#!/usr/bin/env bash

set -euo pipefail

cd `dirname $0`



if [ -z "$PASSWORD" ]; then
    read -s -p "Enter Password: " PASSWORD
fi

VAULT_FILE=vault_key
echo "${PASSWORD}" > "${VAULT_FILE}"

ACTION=decrypt
if [ "$1" != "" ]; then
    ACTION="$1"
fi

FILES=(group_vars/prod/*.yml)
if [ ! -z "${2-}" ]; then
    FILES=("$2")
fi


for FILE in "${FILES[@]}"
do
    if [ "${ACTION}" = "encrypt" ]; then
        echo "Encrypting ${FILE}"
        ansible-vault encrypt "${FILE}.decrypted" --output=$FILE --vault-password-file "${VAULT_FILE}"
    else
        echo "Decrypting ${FILE}"
        ansible-vault decrypt $FILE --output="${FILE}.decrypted" --vault-password-file "${VAULT_FILE}"
    fi
done

rm -rf "${VAULT_FILE}"
