variable "location" {}
variable "function_name" {}
variable "function_description" {}
variable "runtime" {}
variable "handler" {}
variable "build_env_variables" {
  type = map(string)
}
variable "ingress_settings" {}
variable "all_traffic_on_latest_revision" {}
variable "sa" {}
variable "max_instance_count" {}
variable "min_instance_count" {}
variable "available_memory" {}
variable "timeout_seconds" {}
variable "storage_source" {
  type = list(object({
    bucket =  string
    object = string
  }))
}
variable "event_triggers" {
  type = list(object({
    event_type            = string
    retry_policy          = string
    service_account_email = string
    event_filters = list(object({
      attribute = string
      value     = string
    }))
  }))
}
