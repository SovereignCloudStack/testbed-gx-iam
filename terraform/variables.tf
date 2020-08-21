variable "cloud_provider" {
  default = "betacloud"
  type    = string
}

variable "prefix" {
  default = "testbed-iam"
  type    = string
}

variable "image" {
  default = "Ubuntu 18.04"
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

variable "configuration_version" {
  default = "master"
  type    = string
}

variable "openstack_version" {
  default = "ussuri"
  type    = string
}
