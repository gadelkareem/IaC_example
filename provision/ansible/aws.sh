#!/usr/bin/env bash

set -euo pipefail

cd `dirname $0`


function dec(){
    echo $1 | openssl enc -a -d -aes-256-cbc -K $(printf  "${PASSWORD}" | od -A n -t x1 | tr -d '\040\011\012\015') -iv $(printf "0937465827384759" | od -A n -t x1 | tr -d '\040\011\012\015')
}

function enc(){
    echo $1 | openssl enc -a -e -aes-256-cbc -K $(printf "${PASSWORD}" | od -A n -t x1 | tr -d '\040\011\012\015') -iv $(printf "0937465827384759" | od -A n -t x1 | tr -d '\040\011\012\015')
}

DEBUG=""
FORCE_DEPLOY=false
APP_NAME="myproject"
ONLY_APP_NAME=""
BASE_PATH=""
BUILD_NUMBER=""
PLAYBOOK_ENV=prod
TAGS=""

while [ $# -gt 0 ]; do
  case "$1" in
    --pass=*)
      PASSWORD="${1#*=}"
      ;;
    --env=*)
      PLAYBOOK_ENV="${1#*=}"
      ;;
    --debug=*)
      DEBUG="-vvv"
      ;;
    --tags=*)
      TAGS="${1#*=}"
      ;;
    --app_name=*)
      APP_NAME="${1#*=}"
      ;;
    --only_app_name=*)
      ONLY_APP_NAME="only_app_name=${1#*=}"
      ;;
    --base_path=*)
      BASE_PATH="base_path=${1#*=}"
      ;;
    --force_deploy=*)
      FORCE_DEPLOY="${1#*=}"
      ;;
    --build_number=*)
      BUILD_NUMBER="build_number=${1#*=}"
      ;;
    *)
      printf "***************************\n"
      printf "* Error: Invalid argument.*\n"
      printf "***************************\n"
      exit 1
  esac
  shift
done



if [ -z "$PASSWORD" ]; then
    read -s -p "Enter Password: " PASSWORD
fi


if [ -z "$TAGS" ]; then
    echo ERROR: Please add some tags
    exit 1
fi

BOTO_SCRIPT="./inventory/boto/ec2.py  --refresh-cache > /dev/null "
if [ "$TAGS" == "artifact" ]; then
    BOTO_SCRIPT="echo - No boto"
fi

echo

#Uncomment these lines to generate the decrypted keys
#echo $(enc "AKIAIOSFODNN7EXAMPLE")
#echo $(enc "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY")
#exit

AWS_ACCESS_KEY_ID=$(dec "+Shz32R4hY0XusaYzVjht1CTiuXbBV+TKPazf04lCrI=")
AWS_SECRET_ACCESS_KEY=$(dec "h9tn4+S4Cj4d1dvuXZfNypses1yt9rb8jUA8sHKLLzQ4gGbdtR6H3h+FjcRC73Xb")

#echo $AWS_ACCESS_KEY_ID $AWS_SECRET_ACCESS_KEY && exit

VAULT_FILE=vault_key

function run-ansible(){
    export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} && \
    export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} && \
    eval $BOTO_SCRIPT && \
    ansible-playbook aws-playbook.yml -i inventory/boto/ec2.py  \
    --extra-vars  "env=${PLAYBOOK_ENV} encryption_pass=${PASSWORD} release=8 force_deploy=${FORCE_DEPLOY} aws_key_id=${AWS_ACCESS_KEY_ID} aws_secret_key=${AWS_SECRET_ACCESS_KEY} app_name=${APP_NAME} ${ONLY_APP_NAME} ansible_ssh_common_args='-o StrictHostKeyChecking=no' ${BASE_PATH} ${BUILD_NUMBER} " \
    $DEBUG --tags $1 --vault-password-file $VAULT_FILE
}

echo $PASSWORD > $VAULT_FILE

printf "***************************\n"
printf "* Starting tags: $TAGS  app_name: ${APP_NAME}   \n"
printf "***************************\n"

run-ansible $TAGS


rm -rf $VAULT_FILE *-playbook.retry
