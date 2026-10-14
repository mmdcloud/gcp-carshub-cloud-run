resource "google_storage_transfer_job" "storage_transfer_service" {
  name        = var.name
  description = var.description
  status      = var.status

  dynamic "transfer_spec" {
    for_each = var.transfer_spec != null ? [var.transfer_spec] : []
    content {
      source_agent_pool_name = try(transfer_spec.value.source_agent_pool_name, null)
      sink_agent_pool_name   = try(transfer_spec.value.sink_agent_pool_name, null)

      dynamic "posix_data_source" {
        for_each = transfer_spec.value.posix_data_source != null ? [transfer_spec.value.posix_data_source] : []
        content {
          root_directory = posix_data_source.value.root_directory
        }
      }

      dynamic "gcs_data_sink" {
        for_each = transfer_spec.value.gcs_data_sink != null ? [transfer_spec.value.gcs_data_sink] : []
        content {
          bucket_name = gcs_data_sink.value.bucket_name
          path        = try(gcs_data_sink.value.path, null)
        }
      }

      dynamic "object_conditions" {
        for_each = transfer_spec.value.object_conditions != null ? [transfer_spec.value.object_conditions] : []
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
        for_each = transfer_spec.value.transfer_options != null ? [transfer_spec.value.transfer_options] : []
        content {
          overwrite_objects_already_existing_in_sink = try(transfer_options.value.overwrite_objects_already_existing_in_sink, null)
          delete_objects_unique_in_sink              = try(transfer_options.value.delete_objects_unique_in_sink, null)
          delete_objects_from_source_after_transfer  = try(transfer_options.value.delete_objects_from_source_after_transfer, null)
          overwrite_when                             = try(transfer_options.value.overwrite_when, null)

          dynamic "metadata_options" {
            for_each = try(transfer_options.value.metadata_options, null) != null ? [transfer_options.value.metadata_options] : []
            content {
              symlink        = try(metadata_options.value.symlink, null)
              mode           = try(metadata_options.value.mode, null)
              gid            = try(metadata_options.value.gid, null)
              uid            = try(metadata_options.value.uid, null)
              acl            = try(metadata_options.value.acl, null)
              storage_class  = try(metadata_options.value.storage_class, null)
              temporary_hold = try(metadata_options.value.temporary_hold, null)
              kms_key        = try(metadata_options.value.kms_key, null)
              time_created   = try(metadata_options.value.time_created, null)
            }
          }
        }
      }
    }
  }

  dynamic "schedule" {
    for_each = length(var.schedule) > 0 ? var.schedule : []
    content {
      schedule_start_date {
        year  = schedule.value["start_year"]
        month = schedule.value["start_month"]
        day   = schedule.value["start_day"]
      }
      schedule_end_date {
        year  = schedule.value["end_year"]
        month = schedule.value["end_month"]
        day   = schedule.value["end_day"]
      }
      start_time_of_day {
        hours   = schedule.value["hours"]
        minutes = schedule.value["minutes"]
        seconds = schedule.value["seconds"]
        nanos   = schedule.value["nanos"]
      }
      repeat_interval = schedule.value["schedule_repeat_interval"]
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

