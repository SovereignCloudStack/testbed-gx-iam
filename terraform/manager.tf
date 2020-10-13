resource "openstack_networking_floatingip_v2" "manager_floating_ip" {
  pool       = var.public
  depends_on = [openstack_networking_router_interface_v2.router_interface]
}

resource "openstack_networking_port_v2" "manager_port_management" {
  network_id = openstack_networking_network_v2.net_management.id
  security_group_ids = [
    openstack_compute_secgroup_v2.security_group_management.id,
    openstack_compute_secgroup_v2.security_group_manager.id
  ]

  fixed_ip {
    ip_address = "192.168.16.5"
    subnet_id  = openstack_networking_subnet_v2.subnet_management.id
  }
}

resource "openstack_networking_port_v2" "manager_port_internal" {
  network_id         = openstack_networking_network_v2.net_internal.id
  security_group_ids = [openstack_compute_secgroup_v2.security_group_internal.id]

  fixed_ip {
    ip_address = "192.168.32.5"
    subnet_id  = openstack_networking_subnet_v2.subnet_internal.id
  }

  allowed_address_pairs {
    ip_address = "192.168.32.9/32"
  }
}

resource "openstack_networking_floatingip_associate_v2" "manager_floating_ip_association" {
  floating_ip = openstack_networking_floatingip_v2.manager_floating_ip.address
  port_id     = openstack_networking_port_v2.manager_port_management.id
}

resource "openstack_compute_instance_v2" "manager_server" {
  name              = "${var.prefix}-manager"
  availability_zone = var.availability_zone
  image_name        = var.image
  flavor_name       = var.flavor_manager
  key_pair          = openstack_compute_keypair_v2.key.name

  network { port = openstack_networking_port_v2.manager_port_management.id }
  network { port = openstack_networking_port_v2.manager_port_internal.id }

  user_data = <<-EOT
#cloud-config
package_update: true
package_upgrade: false
packages:
  - ifupdown
write_files:
  - content: |
      import subprocess
      import netifaces

      PORTS = {
          "${openstack_networking_port_v2.manager_port_internal.mac_address}": "${openstack_networking_port_v2.manager_port_internal.all_fixed_ips[0]}",
      }

      for interface in netifaces.interfaces():
          mac_address = netifaces.ifaddresses(interface)[netifaces.AF_LINK][0]['addr']
          if mac_address in PORTS:
              subprocess.run("ip addr add %s/20 dev %s" % (PORTS[mac_address], interface), shell=True)
              subprocess.run("ip link set up dev %s" % interface, shell=True)
    path: /root/configure-network-devices.py
    permissions: '0600'
  - content: ${openstack_compute_keypair_v2.key.public_key}
    path: /home/ubuntu/.ssh/id_rsa.pub
    permissions: '0600'
  - content: |
      ${indent(6, openstack_compute_keypair_v2.key.private_key)}
    path: /home/ubuntu/.ssh/id_rsa
    permissions: '0600'
  - content: |
      ${indent(6, file("files/node.yml"))}
    path: /opt/node.yml
    permissions: '0644'
  - content: |
      ${indent(6, file("files/cleanup.yml"))}
    path: /opt/cleanup.yml
    permissions: '0644'
  - content: |
      ${indent(6, file("files/cleanup.sh"))}
    path: /root/cleanup.sh
    permissions: '0700'
  - content: |
      ---
      endpoint: "${var.endpoint}"
    path: /opt/manager.yml
    permissions: '0644'
  - content: |
      ${indent(6, file("files/manager-part-1.yml"))}
    path: /opt/manager-part-1.yml
    permissions: '0644'
  - content: |
      ${indent(6, file("files/manager-part-2.yml"))}
    path: /opt/manager-part-2.yml
    permissions: '0644'
  - content: |
      ${indent(6, file("files/manager-part-3.yml"))}
    path: /opt/manager-part-3.yml
    permissions: '0644'
  - content: |
      ${indent(6, file("files/node.sh"))}
    path: /root/node.sh
    permissions: '0700'
  - content: |
      ${indent(6, file("files/manager.sh"))}
    path: /root/manager.sh
    permissions: '0700'
  - content: |
      ${indent(6, file("files/deploy.sh"))}
    path: /root/deploy.sh
    permissions: '0700'
  - content: |
      #!/usr/bin/env bash

      # FIXME: Use a real check here
      # NOTE: Waiting for completion of the Keycloak bootstrap
      sleep 120

      # NOTE: https://github.com/keycloak/keycloak-documentation/blob/master/server_admin/topics/admin-cli.adoc

      # NOTE: Resolve “HTTPS required” while logging in to Keycloak as admin issue
      sudo -iu dragon sh -c 'docker exec keycloak /opt/jboss/keycloak/bin/kcadm.sh config credentials --server http://localhost:8080/auth --realm master --user admin --password password'
      sudo -iu dragon sh -c 'docker exec keycloak /opt/jboss/keycloak/bin/kcadm.sh update realms/master -s sslRequired=NONE'

      # NOTE: Setup the keystone realm
      sudo -iu dragon sh -c "docker exec keycloak /opt/jboss/keycloak/bin/kcadm.sh create realms -s realm=keystone -s enabled=true -s sslRequired=NONE -s displayName='Keystone realm'"
      sudo -iu dragon sh -c "docker exec keycloak /opt/jboss/keycloak/bin/kcadm.sh create clients -r keystone -s clientId=keystone -s 'redirectUris=[\"https://${var.endpoint}:5000/*\"]' -s clientAuthenticatorType=client-secret -s secret=11111111-1111-1111-1111-111111111111 -s implicitFlowEnabled=true"

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

      openstack --os-cloud admin identity provider create --remote-id https://${var.endpoint}:8170/auth/realms/keystone keycloak
      openstack --os-cloud admin mapping create --rules /configuration/files/keycloak_rules.json keycloak_mapping
      openstack --os-cloud admin federation protocol create mapped --mapping keycloak_mapping --identity-provider keycloak
    path: /root/bootstrap.sh
    permissions: '0700'
runcmd:
  - "echo 'network: {config: disabled}' > /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg"
  - "rm -f /etc/network/interfaces.d/50-cloud-init.cfg"
  - "mv /etc/netplan/50-cloud-init.yaml /etc/netplan/50-cloud-init.yaml.unused"
  - "/root/node.sh"
  - "/root/manager.sh"
  - "/root/deploy.sh"
  - "/root/bootstrap.sh"
final_message: "The system is finally up, after $UPTIME seconds"
power_state:
  mode: reboot
  condition: True
EOT

}
