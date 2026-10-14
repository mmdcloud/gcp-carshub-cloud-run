resource "google_storage_transfer_job" "storage_transfer_service" {
  name        = var.name
  description = var.description
  status      = var.status

  dynamic "replication_spec" {
    for_each = var.replication_spec
    content {
      
      gcs_data_source {
        bucket_name = replication_spec.value.source_bucket_name
        path        = try(replication_spec.value.source_path, null)
      }

      gcs_data_sink {
        bucket_name = replication_spec.value.sink_bucket_name
        path        = try(replication_spec.value.sink_path, null)
      }

      dynamic "object_conditions" {
        for_each = replication_spec.value.object_conditions != null ? [replication_spec.value.object_conditions] : []
        content {
          max_time_elapsed_since_last_modification = try(object_conditions.value.max_time_elapsed_since_last_modification, null)
          min_time_elapsed_since_last_modification = try(object_conditions.value.min_time_elapsed_since_last_modification, null)
          include_prefixes                         = try(object_conditions.value.include_prefixes, null)
          exclude_prefixes                         = try(object_conditions.value.exclude_prefixes, null)
          last_modified_since                      = try(object_conditions.value.last_modified_since, null)
          last_modified_before                     = try(object_conditions.value.last_modified_before, null)
        }
      }

      dynamic "transfer_options" {
        for_each = replication_spec.value.transfer_options != null ? [replication_spec.value.transfer_options] : []
        content {
          overwrite_objects_already_existing_in_sink = try(transfer_options.value.overwrite_objects_already_existing_in_sink, null)
          delete_objects_unique_in_sink              = try(transfer_options.value.delete_objects_unique_in_sink, null)
          delete_objects_from_source_after_transfer  = try(transfer_options.value.delete_objects_from_source_after_transfer, null)
          overwrite_when                             = try(transfer_options.value.overwrite_when, null)
        }
      }
    }
  }

  dynamic "logging_config" {
    for_each = var.logging_config != null ? [var.logging_config] : []
    content {
      enable_on_prem_gcs_transfer_logs = try(logging_config.value.enable_on_prem_gcs_transfer_logs, null)
      log_actions                      = try(logging_config.value.log_actions, null)
      log_action_states                = try(logging_config.value.log_action_states, null)
    }
  }

  dynamic "notification_config" {
    for_each = var.notification_config != null ? var.notification_config : []
    content {
      pubsub_topic   = notification_config.value["pubsub_topic"]
      event_types    = notification_config.value["event_types"]
      payload_format = notification_config.value["payload_format"]
    }
  }
}