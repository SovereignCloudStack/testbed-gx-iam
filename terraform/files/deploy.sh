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

# FIXME: Use a real check here
# NOTE: Waiting for completion of the Keycloak bootstrap
sleep 120

# NOTE: https://github.com/keycloak/keycloak-documentation/blob/master/server_admin/topics/admin-cli.adoc

# NOTE: Resolve “HTTPS required” while logging in to Keycloak as admin issue
sudo -iu dragon sh -c 'docker exec keycloak /opt/jboss/keycloak/bin/kcadm.sh config credentials --server http://localhost:8080/auth --realm master --user admin --password password'
sudo -iu dragon sh -c 'docker exec keycloak /opt/jboss/keycloak/bin/kcadm.sh update realms/master -s sslRequired=NONE'

# NOTE: Setup the keystone realm
sudo -iu dragon sh -c "docker exec keycloak /opt/jboss/keycloak/bin/kcadm.sh create realms -s realm=keystone -s enabled=true -s sslRequired=NONE -s displayName='Keystone realm'"
sudo -iu dragon sh -c "docker exec keycloak /opt/jboss/keycloak/bin/kcadm.sh create clients -r keystone -s clientId=keystone -s 'redirectUris=[\"http://testbed-iam.osism.test:5000/*\"]' -s clientAuthenticatorType=client-secret -s secret=11111111-1111-1111-1111-111111111111 -s implicitFlowEnabled=true"

sudo -iu dragon sh -c "docker exec keycloak /opt/jboss/keycloak/bin/kcadm.sh create users -s username=keycloak -s enabled=true -s email=keycloak@osism.test -r keystone"
sudo -iu dragon sh -c "docker exec keycloak /opt/jboss/keycloak/bin/kcadm.sh set-password -r keystone --username keycloak --new-password password"

# NOTE: https://jdennis.fedorapeople.org/doc/rhsso-tripleo-federation/html/rhsso-tripleo-federation.html

# FIXME: Migrate this to environments/openstack/playbook-bootstrap-keystone.yml
# NOTE: Bootstrap keystone
openstack --os-cloud admin domain create keycloak
openstack --os-cloud admin project create  --domain keycloak keycloak_project
openstack --os-cloud admin group create keycloak_users --domain keycloak
openstack --os-cloud admin role add --group keycloak_users --group-domain keycloak --domain keycloak _member_
openstack --os-cloud admin role add --group keycloak_users --group-domain keycloak --project keycloak_project --project-domain keycloak _member_

openstack --os-cloud admin identity provider create --remote-id http://testbed-iam.osism.test:8170/auth/realms/keystone keycloak
openstack --os-cloud admin mapping create --rules /configuration/files/keycloak_rules.json keycloak_mapping
openstack --os-cloud admin federation protocol create mapped --mapping keycloak_mapping --identity-provider keycloak
