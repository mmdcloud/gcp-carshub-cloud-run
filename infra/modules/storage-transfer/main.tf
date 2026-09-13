resource "google_storage_transfer_job" "storage_transfer_service" {
  name            = var.name
  description     = var.description
  status          = var.status

  dynamic "transfer_spec" {
    for_each = var.transfer_spec != null && length(var.replication_spec) == 0 ? [var.transfer_spec] : []
    content {
      source_agent_pool_name = try(transfer_spec.value.source_agent_pool_name, null)
      sink_agent_pool_name   = try(transfer_spec.value.sink_agent_pool_name, null)

      # ---- Sinks ----
      dynamic "gcs_data_sink" {
        for_each = transfer_spec.value.gcs_data_sink != null ? [transfer_spec.value.gcs_data_sink] : []
        content {
          bucket_name = gcs_data_sink.value.bucket_name
          path        = try(gcs_data_sink.value.path, null)
        }
      }

      dynamic "posix_data_sink" {
        for_each = transfer_spec.value.posix_data_sink != null ? [transfer_spec.value.posix_data_sink] : []
        content {
          root_directory = posix_data_sink.value.root_directory
        }
      }

      # ---- Sources ----
      dynamic "gcs_data_source" {
        for_each = transfer_spec.value.gcs_data_source != null ? [transfer_spec.value.gcs_data_source] : []
        content {
          bucket_name = gcs_data_source.value.bucket_name
          path        = try(gcs_data_source.value.path, null)
        }
      }

      dynamic "posix_data_source" {
        for_each = transfer_spec.value.posix_data_source != null ? [transfer_spec.value.posix_data_source] : []
        content {
          root_directory = posix_data_source.value.root_directory
        }
      }

      dynamic "aws_s3_data_source" {
        for_each = transfer_spec.value.aws_s3_data_source != null ? [transfer_spec.value.aws_s3_data_source] : []
        content {
          bucket_name             = aws_s3_data_source.value.bucket_name
          path                    = try(aws_s3_data_source.value.path, null)
          role_arn                = try(aws_s3_data_source.value.role_arn, null)
          managed_private_network = try(aws_s3_data_source.value.managed_private_network, null)
          cloudfront_domain       = try(aws_s3_data_source.value.cloudfront_domain, null)

          dynamic "aws_access_key" {
            for_each = try(aws_s3_data_source.value.aws_access_key, null) != null ? [aws_s3_data_source.value.aws_access_key] : []
            content {
              access_key_id     = aws_access_key.value.access_key_id
              secret_access_key = aws_access_key.value.secret_access_key
            }
          }
        }
      }

      dynamic "http_data_source" {
        for_each = transfer_spec.value.http_data_source != null ? [transfer_spec.value.http_data_source] : []
        content {
          list_url = http_data_source.value.list_url
        }
      }

      dynamic "hdfs_data_source" {
        for_each = transfer_spec.value.hdfs_data_source != null ? [transfer_spec.value.hdfs_data_source] : []
        content {
          path = hdfs_data_source.value.path
        }
      }

      dynamic "azure_blob_storage_data_source" {
        for_each = transfer_spec.value.azure_blob_storage_data_source != null ? [transfer_spec.value.azure_blob_storage_data_source] : []
        content {
          storage_account    = azure_blob_storage_data_source.value.storage_account
          container          = azure_blob_storage_data_source.value.container
          path               = azure_blob_storage_data_source.value.path
          credentials_secret = try(azure_blob_storage_data_source.value.credentials_secret, null)

          dynamic "azure_credentials" {
            for_each = try(azure_blob_storage_data_source.value.azure_credentials, null) != null ? [azure_blob_storage_data_source.value.azure_credentials] : []
            content {
              sas_token = azure_credentials.value.sas_token
            }
          }

          dynamic "federated_identity_config" {
            for_each = try(azure_blob_storage_data_source.value.federated_identity_config, null) != null ? [azure_blob_storage_data_source.value.federated_identity_config] : []
            content {
              client_id = federated_identity_config.value.client_id
              tenant_id = federated_identity_config.value.tenant_id
            }
          }
        }
      }

      # ---- Conditions / options / manifest ----
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
              gid            = metadata_options.value.gid
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

  dynamic "schedule" {
    for_each = length(var.replication_spec) == 0 && length(var.schedule) > 0 ? var.schedule : []
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

  dynamic "event_stream" {
    for_each = length(var.schedule) == 0 && length(var.event_stream) > 0 ? var.event_stream : []
    content {
      name                         = event_stream.value["name"]
      event_stream_start_time      = try(event_stream.value["event_stream_start_time"], null)
      event_stream_expiration_time = try(event_stream.value["event_stream_expiration_time"], null)
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

  lifecycle {
    # exactly one of transfer_spec / replication_spec
    precondition {
      condition     = (var.transfer_spec != null) != (length(var.replication_spec) > 0)
      error_message = "Set exactly one of `transfer_spec` or `replication_spec` — not both, and not neither."
    }

    # replication_spec forbids schedule and event_stream
    precondition {
      condition     = !(length(var.replication_spec) > 0 && (length(var.schedule) > 0 || length(var.event_stream) > 0))
      error_message = "replication_spec cannot be combined with schedule or event_stream. Remove schedule/event_stream when using replication_spec."
    }

    # schedule and event_stream are mutually exclusive with each other
    precondition {
      condition     = !(length(var.schedule) > 0 && length(var.event_stream) > 0)
      error_message = "schedule and event_stream are mutually exclusive. Set only one."
    }

    # at most one replication_spec block (API only supports one)
    precondition {
      condition     = length(var.replication_spec) <= 1
      error_message = "Only one replication_spec block is supported."
    }
  }
}
