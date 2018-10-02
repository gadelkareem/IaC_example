#!/usr/bin/env bash

set -euo pipefail

cd `dirname $0`

TIMESTAMP=$(date '+%Y_%m_%d__%H_%M_%S')


mkdir -p /var/backups/databases
cd /var/backups/databases

function postgresql_backup(){
    FILENAME=${1}_${ENV}_${TIMESTAMP}.dump
    FILE=/var/backups/databases/${FILENAME}

    echo Backing up ${1}
    chown -R postgres /var/backups/databases
    su postgres -c "pg_dump --no-owner --no-acl -h localhost -f ${FILE}  --format=custom --compress=9 --no-password ${1}"

    echo Uploading ${1}
    /usr/local/bin/aws s3 cp ${FILE} s3://myproject.backups/db/${FILENAME}
    rm -f ${FILE}
}


postgresql_backup myproject


#pg_restore -v --jobs=4 -U myproject -h localhost -p 5432 --no-owner -d myproject test.dump

