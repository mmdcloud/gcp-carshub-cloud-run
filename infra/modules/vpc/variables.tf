variable "location" {}
variable "vpc_name" {}
variable "private_ip_google_access" {}
variable "auto_create_subnetworks" {}
variable "subnets" {
  type = list(object({
    name          = string
    ip_cidr_range = string
  }))
}
variable "firewall_data" {
  type = list(object({
    firewall_name      = string
    firewall_direction = string
    target_tags        = list(string)
    source_ranges      = list(string)
    allow_list = list(object({
      protocol = string
      ports    = list(string)
    }))
  }))
}
variable "serverless_vpc_connectors" {
  type = list(object({
    name = string
    ip_cidr_range = string
    min_instances = string
    max_instances = string
    machine_type = string
  }))
}