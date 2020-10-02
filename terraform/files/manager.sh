#!/usr/bin/env bash

cp /home/ubuntu/.ssh/id_rsa /home/dragon/.ssh/id_rsa
cp /home/ubuntu/.ssh/id_rsa.pub /home/dragon/.ssh/id_rsa.pub
chown -R dragon:dragon /home/dragon/.ssh

sudo -iu dragon ansible-galaxy install git+https://github.com/osism/ansible-docker
sudo -iu dragon ansible-galaxy install git+https://github.com/osism/ansible-manager

git clone https://github.com/osism/ansible-collection-commons.git /tmp/ansible-collection-commons
( cd /tmp/ansible-collection-commons; ansible-galaxy collection build; sudo -iu dragon ansible-galaxy collection install -v -f -p /usr/share/ansible/collections osism-commons-*.tar.gz; )
rm -rf /tmp/ansible-collection-commons

git clone https://github.com/osism/ansible-collection-services.git /tmp/ansible-collection-services
( cd /tmp/ansible-collection-services; ansible-galaxy collection build; sudo -iu dragon ansible-galaxy collection install -v -f -p /usr/share/ansible/collections osism-services-*.tar.gz; )
rm -rf /tmp/ansible-collection-services

sudo -iu dragon ansible-playbook -i testbed-gx-iam-manager.osism.test, /opt/manager-part-1.yml -e @/opt/manager.yml
sudo -iu dragon ansible-playbook -i testbed-gx-iam-manager.osism.test, /opt/manager-part-2.yml -e @/opt/manager.yml
sudo -iu dragon ansible-playbook -i testbed-gx-iam-manager.osism.test, /opt/manager-part-3.yml -e @/opt/manager.yml

sudo -iu dragon cp /home/dragon/.ssh/id_rsa.pub /opt/ansible/secrets/id_rsa.operator.pub

# NOTE(berendt): wait for ARA
until [[ "$(/usr/bin/docker inspect -f '{{.State.Health.Status}}' manager_ara-server_1)" == "healthy" ]]; do
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
