#!/usr/bin/env bash

set -euo pipefail

cd `dirname $0`

./aws.sh --tags="ubuntu-ami"
./aws.sh --tags="infrastructure"
./aws.sh --tags="solr-provision"
./aws.sh --tags="redis-provision"
./aws.sh --tags="postgres-provision"
./aws.sh --tags="webserver-init" --app_name="myproject"
./aws.sh --tags="artifact" --app_name="myproject"
./aws.sh --tags="deploy" --app_name="myproject"
