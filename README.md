# Complete Ansible, Vagrant and AWS infrastructure

## Vagrant provisioning
- Install Vagrant and clone this repo.
- `vagrant up` to start installation
- The installation will provision 2 boxes `myproject` and `services`, you can retry provisioning using `vagrant provision` if it failed.
- After provisioning the vagrant boxes you should access the symfony project on `192.168.33.31` which is a basic symfony example project.
- All `redis`, `postgreSQL` and `solr` services are on the `services` box.
- Root is ```/var/www/application```
- MyProject IP is `192.168.33.31`.
- Services IP is `192.168.33.32`.

## AWS provisioning (AWS will charge you for launching services)
- Login vagrant `vagrant ssh myproject`
- Change the password and ssh key to yours and remove the prod_files from your repo `/var/www/application/prod_files`
- Add the production password and ssh keys to vagrant`bash /var/www/application/prod_files/add_to_vagrant.sh`
- Encrypt your AWS keys as shown on `provision/ansible/aws.sh:82`
- Go to `/var/www/application/provision/ansible`
- run `./aws-infrastructure.sh` to start building the infrastructure on AWS.
- Edit the deploy script `roles/deploy-application/files/myproject/deploy.sh` to fit your requirements.

## Solr Admin

- [http://192.168.33.32:8983](http://192.168.33.32:8983)

## pghero

- [http://192.168.33.32:3441/](http://192.168.33.32:3441/)

## [MailHog](https://github.com/mailhog/MailHog)

- [http://192.168.33.31:8025/](http://192.168.33.31:8025/)
