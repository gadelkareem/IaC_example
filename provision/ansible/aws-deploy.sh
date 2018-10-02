#!/usr/bin/env bash

set -euo pipefail

cd `dirname $0`

./aws.sh --tags="artifact" --app_name="$1"
./aws.sh --tags="deploy" --app_name="$1"

