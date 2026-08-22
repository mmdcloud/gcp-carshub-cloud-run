variable "vpc_name" {}
variable "delete_default_routes_on_create" {}
variable "auto_create_subnetworks" {}
variable "routing_mode" {}
variable "region" {}
variable "firewall_data" {
  type = list(object({
    name                = string
    description         = optional(string)
    priority            = optional(number, 1000)
    source_ranges       = optional(list(string))
    source_tags         = optional(list(string))
    destination_ranges  = optional(list(string))
    target_tags         = optional(list(string))
    allow_list = optional(list(object({
      protocol = string
      ports    = optional(list(string))
    })), [])
    deny_list = optional(list(object({
      protocol = string
      ports    = optional(list(string))
    })), [])
  }))
}
variable "subnets" {
  type = list(object({
    name                     = string
    ip_cidr_range            = string
    region                   = string
    private_ip_google_access = bool
    purpose                  = string
    role                     = string
  }))
}