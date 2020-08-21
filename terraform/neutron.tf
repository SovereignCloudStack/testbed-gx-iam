###################
# Security groups #
###################

resource "openstack_compute_secgroup_v2" "security_group_manager" {
  name        = "${var.prefix}-manager"
  description = "manager security group"

  rule {
    cidr        = "0.0.0.0/0"
    ip_protocol = "tcp"
    from_port   = 80
    to_port     = 80
  }

  rule {
    cidr        = "0.0.0.0/0"
    ip_protocol = "tcp"
    from_port   = 5000
    to_port     = 5000
  }

  rule {
    cidr        = "0.0.0.0/0"
    ip_protocol = "tcp"
    from_port   = 8110
    to_port     = 8110
  }

  rule {
    cidr        = "0.0.0.0/0"
    ip_protocol = "tcp"
    from_port   = 8120
    to_port     = 8120
  }

  rule {
    cidr        = "0.0.0.0/0"
    ip_protocol = "tcp"
    from_port   = 8130
    to_port     = 8130
  }

  rule {
    cidr        = "0.0.0.0/0"
    ip_protocol = "tcp"
    from_port   = 8170
    to_port     = 8170
  }

  rule {
    cidr        = "0.0.0.0/0"
    ip_protocol = "tcp"
    from_port   = 35357
    to_port     = 35357
  }

  rule {
    cidr        = "0.0.0.0/0"
    ip_protocol = "tcp"
    from_port   = 15672
    to_port     = 15672
  }
}

resource "openstack_compute_secgroup_v2" "security_group_management" {
  name        = "${var.prefix}-management"
  description = "management security group"

  rule {
    cidr        = "0.0.0.0/0"
    ip_protocol = "tcp"
    from_port   = 22
    to_port     = 22
  }

  rule {
    cidr        = "0.0.0.0/0"
    ip_protocol = "icmp"
    from_port   = -1
    to_port     = -1
  }
}

############
# Networks #
############

resource "openstack_networking_network_v2" "net_management" {
  name                    = "${var.prefix}-management"
  availability_zone_hints = [var.network_availability_zone]
}

resource "openstack_networking_subnet_v2" "subnet_management" {
  network_id      = openstack_networking_network_v2.net_management.id
  cidr            = "192.168.40.0/24"
  ip_version      = 4
  dns_nameservers = ["9.9.9.9", "149.112.112.112"]

  allocation_pool {
    start = "192.168.40.100"
    end   = "192.168.40.110"
  }
}

resource "openstack_networking_port_v2" "vip_port" {
  network_id = openstack_networking_network_v2.net_management.id

  fixed_ip {
    ip_address = "192.168.40.200"
    subnet_id  = openstack_networking_subnet_v2.subnet_management.id
  }
}

data "openstack_networking_network_v2" "public" {
  name = var.public
}

resource "openstack_networking_router_v2" "router" {
  external_network_id     = data.openstack_networking_network_v2.public.id
  availability_zone_hints = [var.network_availability_zone]
}

resource "openstack_networking_router_interface_v2" "router_interface" {
  router_id = openstack_networking_router_v2.router.id
  subnet_id = openstack_networking_subnet_v2.subnet_management.id
}
