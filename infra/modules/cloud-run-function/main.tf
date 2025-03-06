resource "google_cloudfunctions2_function" "carshub_media_function" {
  name        = var.function_name
  location    = var.location
  description = var.function_description
  build_config {
    runtime               = var.runtime
    entry_point           = var.handler
    environment_variables = var.build_env_variables
    source {
      storage_source {
        bucket = var.storage_source_bucket
        object = var.storage_source_bucket_object
      }
    }
  }
  service_config {
    vpc_connector                  = var.vpc_connector
    vpc_connector_egress_settings  = var.vpc_connector_egress_settings
    max_instance_count             = var.max_instance_count
    min_instance_count             = var.min_instance_count
    available_memory               = var.available_memory
    timeout_seconds                = var.timeout_seconds
    environment_variables          = var.build_env_variables
    ingress_settings               = var.ingress_settings
    all_traffic_on_latest_revision = var.all_traffic_on_latest_revision
    service_account_email          = var.function_app_service_account_email
  }
  event_trigger {
    event_type            = var.event_trigger_event_type
    pubsub_topic          = var.event_trigger_topic
    retry_policy          = var.event_trigger_retry_policy
    service_account_email = var.event_trigger_service_account_email
    dynamic "event_filters" {
      for_each = var.event_filters
      content {
        attribute = event_filters.value["attribute"]
        value     = event_filters.value["value"]
      }
    }
  }
}
