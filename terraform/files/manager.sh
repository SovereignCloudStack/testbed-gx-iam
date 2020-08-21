#!/usr/bin/env bash

cp /home/ubuntu/.ssh/id_rsa /home/dragon/.ssh/id_rsa
cp /home/ubuntu/.ssh/id_rsa.pub /home/dragon/.ssh/id_rsa.pub
chown -R dragon:dragon /home/dragon/.ssh

sudo -iu dragon ansible-galaxy install git+https://github.com/osism/ansible-configuration
sudo -iu dragon ansible-galaxy install git+https://github.com/osism/ansible-docker
sudo -iu dragon ansible-galaxy install git+https://github.com/osism/ansible-docker-compose
sudo -iu dragon ansible-galaxy install git+https://github.com/osism/ansible-manager

sudo -iu dragon ansible-playbook -i testbed-iam-manager.osism.local, /opt/manager-part-1.yml
sudo -iu dragon ansible-playbook -i testbed-iam-manager.osism.local, /opt/manager-part-2.yml
sudo -iu dragon ansible-playbook -i testbed-iam-manager.osism.local, /opt/manager-part-3.yml

sudo -iu dragon cp /home/dragon/.ssh/id_rsa.pub /opt/ansible/secrets/id_rsa.operator.pub

# NOTE(berendt): wait for ARA
until [[ "$(/usr/bin/docker inspect -f '{{.State.Health.Status}}' manager_ara-server_1)" == "healthy" ]]; do
    sleep 1;
done;

# NOTE(berendt): wait for Netbox
until [[ "$(/usr/bin/docker inspect -f '{{.State.Health.Status}}' manager_netbox-nginx_1)" == "healthy" ]]; do
    sleep 1;
done;

/root/cleanup.sh

# NOTE(berendt): sudo -E does not work here because sudo -i is needed

sudo -iu dragon sh -c 'INTERACTIVE=false osism-generic bootstrap'
sudo -iu dragon sh -c 'INTERACTIVE=false osism-generic operator'

# copy network configuration
sudo -iu dragon sh -c 'INTERACTIVE=false osism-generic network'

# NOTE: Restart the manager services to update the /etc/hosts file
sudo -iu dragon sh -c 'docker-compose -f /opt/manager/docker-compose.yml restart'

# NOTE(berendt): wait for ARA
until [[ "$(/usr/bin/docker inspect -f '{{.State.Health.Status}}' manager_ara-server_1)" == "healthy" ]];
do
    sleep 1;
done;
