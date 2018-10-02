# -*- mode: ruby -*-
# vi: set ft=ruby :


PROVISION = <<SCRIPT
if [ ! -f /usr/bin/ansible-playbook ]
    then
    sudo apt-add-repository ppa:ansible/ansible -y && sudo apt-get update
    sudo apt-get install ansible -y && sudo apt-get update
fi
ansible-galaxy install -r /var/www/application/provision/ansible/requirements.yml
SCRIPT

MYPROJECT_IP = '192.168.33.31'
SERVICES_IP = '192.168.33.32'
PLAYBOOK_RUN = "ansible-playbook -i 'ANSIBLE_HOST,' -c local  /var/www/application/provision/ansible/vagrant-playbook.yml -e ' services_ip="+SERVICES_IP+" myproject_ip="+MYPROJECT_IP+" ' "

Vagrant.configure("2") do |config|

    config.vm.box = "bento/ubuntu-18.04"
    config.vm.box_check_update = true

    config.ssh.forward_agent = true
    config.vm.provision "shell", inline: PROVISION

    #config.ssh.insert_key = false
    #config.vbguest.auto_update = false
    config.vm.network "forwarded_port", guest: 80, host: 8080, protocol: 'tcp', auto_correct: true

    config.vm.synced_folder ".", "/vagrant", disabled: true
    config.vm.synced_folder ".", "/var/www/application", :nfs => { group: "www-data", owner: "vagrant" }, :mount_options => ['nolock,vers=3,udp,noatime,actimeo=1']

    #####myproject
    config.vm.define "myproject" do |myproject|
        #myproject.vm.hostname = "myproject_dev"
        myproject.vm.network "private_network", ip: MYPROJECT_IP, auto_correct: true
        myproject.vm.network "forwarded_port", guest: 22, host: 2201, id: 'ssh', auto_correct: true
        #config.vm.network "public_network", bridge: "en3: Thunderbolt Ethernet"

        myproject.vm.provision "shell", inline: PLAYBOOK_RUN.sub('ANSIBLE_HOST', 'myproject')

        myproject.vm.provider "virtualbox" do |v|
            v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
            v.customize ['modifyvm', :id, '--cableconnected1', 'on']
            v.memory = 500
            v.cpus = 1
            #v.gui = true
        end
    end

    ######services
    config.vm.define "services" do |services|
        #services.vm.hostname = "services_dev"
        services.vm.network "private_network", ip: SERVICES_IP, auto_correct: true
        services.vm.network "forwarded_port", guest: 22, host: 2200, id: 'ssh', auto_correct: true
        services.vm.network "forwarded_port", guest: 6793, host: 6793, id: 'redis', auto_correct: true

        services.vm.provision "shell", inline: PLAYBOOK_RUN.sub('ANSIBLE_HOST', 'services')

        services.vm.provider "virtualbox" do |v|
            v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
            v.memory = 2000
            v.cpus = 1
        end
    end
end
