variable "name" {}
variable "location" {}
variable "deletion_protection" {}
variable "ingress" {}
variable "max_instance_count" {}
variable "traffic_type" {}
variable "vpc_connector_name" {}
variable "service_account" {}
variable "traffic_type_percent" {}
variable "env" {
  type = list(object({
    name  = string
    value = string
    value_source = list(object({
      secret_key_ref = list(object({
        secret  = string
        version = string
      }))
    }))
  }))
}
variable "image" {}
variable "volumes" {
  type = list(object({
    name               = string
    cloud_sql_instance = list(string)
  }))
}
variable "volume_mounts" {
  type = list(object({
    name       = string
    mount_path = string
  }))
}
