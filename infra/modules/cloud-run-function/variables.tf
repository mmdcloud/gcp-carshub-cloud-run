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
variable "function_app_service_account_email" {}
variable "max_instance_count" {}
variable "min_instance_count" {}
variable "available_memory" {}
variable "timeout_seconds" {}
variable "vpc_connector" {}
variable "vpc_connector_egress_settings" {}

variable "storage_source_bucket" {}
variable "storage_source_bucket_object" {}

variable "event_trigger_event_type" {}
variable "event_trigger_retry_policy" {}
variable "event_trigger_service_account_email" {}
variable "event_filters" {
  type = list(object({
    attribute = string
    value     = string
  }))
}