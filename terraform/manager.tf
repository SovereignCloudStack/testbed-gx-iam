resource "openstack_networking_floatingip_v2" "manager_floating_ip" {
  pool       = var.public
  port_id    = openstack_networking_port_v2.manager_port_management.id
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

  allowed_address_pairs {
    ip_address = "192.168.16.9/32"
  }
}

resource "openstack_compute_instance_v2" "manager_server" {
  name              = "${var.prefix}-manager"
  availability_zone = var.availability_zone
  image_name        = var.image
  flavor_name       = var.flavor_manager
  key_pair          = openstack_compute_keypair_v2.key.name

  network { port = openstack_networking_port_v2.manager_port_management.id }

  user_data = <<-EOT
#cloud-config
package_update: true
package_upgrade: false
packages:
  - ifupdown
write_files:
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
runcmd:
  - "echo 'network: {config: disabled}' > /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg"
  - "rm -f /etc/network/interfaces.d/50-cloud-init.cfg"
  - "mv /etc/netplan/50-cloud-init.yaml /etc/netplan/50-cloud-init.yaml.unused"
  - "/root/node.sh"
  - "/root/manager.sh"
  - "/root/deploy.sh"
final_message: "The system is finally up, after $UPTIME seconds"
power_state:
  mode: reboot
  condition: True
EOT

}
