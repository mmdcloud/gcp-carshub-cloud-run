variable "global_address_name" {}
variable "global_address_type" {}
variable "url_map_name" {}
variable "forwarding_scheme" {}
variable "forwarding_rule_name" {}
variable "target_proxy_name" {}
variable "forwarding_port_range" {}
variable "security_policy" {
  type    = string
  default = null
}
variable "backends" {
  type = list(object({
    backend = string
  }))
}
variable "backend_service_name" {}
variable "backend_service_protocol" {}
variable "backend_service_timeout" {}
