resource "google_cloudfunctions2_function" "carshub_media_function" {
  name        = var.function_name
  location    = var.location
  description = var.function_description
  build_config {
    runtime               = var.runtime
    entry_point           = var.handler
    environment_variables = var.build_env_variables
    source {
      dynamic "storage_source" {
        for_each = var.storage_source
        content {
          bucket = storage_source.value["bucket"]
          object = storage_source.value["object"]
        }
      }
    }
  }
  service_config {
    max_instance_count             = var.max_instance_count
    min_instance_count             = var.min_instance_count
    available_memory               = var.available_memory
    timeout_seconds                = var.timeout_seconds
    environment_variables          = var.build_env_variables
    ingress_settings               = var.ingress_settings
    all_traffic_on_latest_revision = var.all_traffic_on_latest_revision
    service_account_email          = var.sa
  }
  dynamic "event_trigger" {
    for_each = var.event_triggers
    content {
      event_type            = event_trigger.value["event_type"]
      retry_policy          = event_trigger.value["retry_policy"]
      service_account_email = event_trigger.value["service_account_email"]
      dynamic "event_filters" {
        for_each = event_trigger.value["event_filters"]
        content {
          attribute = event_filters.value["attribute"]
          value     = event_filters.value["value"]
        }
      }
    }
  }
}
