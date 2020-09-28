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
