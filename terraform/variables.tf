variable "cloud_provider" {
  default = "betacloud"
  type    = string
}

variable "prefix" {
  default = "testbed-gx-iam"
  type    = string
}

variable "image" {
  default = "Ubuntu 20.04"
  type    = string
}

variable "flavor_manager" {
  default = "4C-16GB-40GB"
  type    = string
}

variable "availability_zone" {
  default = "south-2"
  type    = string
}

variable "network_availability_zone" {
  default = "south-2"
  type    = string
}

variable "public" {
  default = "external"
  type    = string
}

# testbed specific paramters

variable "endpoint" {
  default = "testbed-gx-iam.osism.test"
  type    = string
}

variable "openstack_version" {
  default = "ussuri"
  type    = string
}
