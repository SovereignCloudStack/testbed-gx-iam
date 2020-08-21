#!/usr/bin/env bash

sudo -iu dragon sh -c 'INTERACTIVE=false osism-kolla deploy common'
sudo -iu dragon sh -c 'INTERACTIVE=false osism-kolla deploy haproxy'
sudo -iu dragon sh -c 'INTERACTIVE=false osism-kolla deploy mariadb'
sudo -iu dragon sh -c 'INTERACTIVE=false osism-kolla deploy rabbitmq'
sudo -iu dragon sh -c 'INTERACTIVE=false osism-kolla deploy memcached'
sudo -iu dragon sh -c 'INTERACTIVE=false osism-kolla deploy keystone'
sudo -iu dragon sh -c 'INTERACTIVE=false osism-kolla deploy horizon'

sudo -iu dragon sh -c 'INTERACTIVE=false osism-infrastructure phpmyadmin'
sudo -iu dragon sh -c 'INTERACTIVE=false osism-infrastructure openstackclient'

sudo -iu dragon sh -c 'INTERACTIVE=false osism-infrastructure keycloak'

# NOTE: waiting for completion of the Keycloak bootstrap
sleep 120

# NOTE: Resolve “HTTPS required” while logging in to Keycloak as admin issue
sudo -iu dragon sh -c 'docker exec keycloak /opt/jboss/keycloak/bin/kcadm.sh config credentials --server http://localhost:8080/auth --realm master --user admin --password password'
sudo -iu dragon sh -c 'docker exec keycloak /opt/jboss/keycloak/bin/kcadm.sh update realms/master -s sslRequired=NONE'
