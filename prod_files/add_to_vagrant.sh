#!/usr/bin/env bash

set -euo pipefail

cd `dirname $0`

cp test_rsa /home/vagrant/.ssh/id_rsa
chmod 600 /home/vagrant/.ssh/id_rsa
chmod 755 /home/vagrant/.ssh
ssh-add /home/vagrant/.ssh/id_rsa

#change 'pass' to your password
sudo bash -c "echo 'PASSWORD=pass' >> /etc/environment"


