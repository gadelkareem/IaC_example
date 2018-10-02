
alias run-playbook 'ansible-playbook -i "{{app_name}}," -c local  /var/www/application/provision/ansible/vagrant-playbook.yml -e "services_ip={{services_ip}} myproject_ip={{myproject_ip}}" '

