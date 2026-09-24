locals {
  invoker_members = var.grant_all_users_invoker ? ["allUsers"] : var.invoker_members
}

resource "google_cloudfunctions2_function" "function" {
  project     = var.project_id
  name        = var.function_name
  location    = var.location
  description = var.function_description
  labels      = var.labels
  

  kms_key_name = var.kms_key_name

  dynamic "build_config" {
    for_each = var.build_config != null ? [var.build_config] : []
    content {
      runtime               = build_config.value.runtime
      entry_point           = build_config.value.handler
      environment_variables = build_config.value.build_environment_variables
      worker_pool           = build_config.value.build_worker_pool
      docker_repository     = build_config.value.docker_repository
      source {

        dynamic "storage_source" {
          for_each = build_config.value.storage_source != null ? [build_config.value.storage_source] : []
          content {
            bucket     = storage_source.value.bucket
            object     = storage_source.value.object
            generation = storage_source.value.generation
          }
        }

        dynamic "repo_source" {
          for_each = build_config.value.repo_source != null ? [build_config.value.repo_source] : []
          content {
            project_id  = repo_source.value.project_id
            repo_name   = repo_source.value.repo_name
            branch_name = repo_source.value.branch_name
            tag_name    = repo_source.value.tag_name
            commit_sha  = repo_source.value.commit_sha
            dir         = repo_source.value.dir
          }
        }
      }
    }
  }

  dynamic "service_config" {
    for_each = var.service_config != null ? [var.service_config] : []
    content {
      max_instance_count               = service_config.value.max_instance_count
      min_instance_count               = service_config.value.min_instance_count
      max_instance_request_concurrency = service_config.value.max_instance_request_concurrency
      available_memory                 = service_config.value.available_memory
      available_cpu                    = service_config.value.available_cpu
      timeout_seconds                  = service_config.value.timeout_seconds
      ingress_settings                 = service_config.value.ingress_settings
      all_traffic_on_latest_revision   = service_config.value.all_traffic_on_latest_revision
      service_account_email            = service_config.value.service_account_email
      environment_variables            = service_config.value.service_environment_variables

      vpc_connector                 = service_config.value.vpc_connector
      vpc_connector_egress_settings = service_config.value.vpc_connector != null ? service_config.value.vpc_connector_egress_settings : null

      binary_authorization_policy = service_config.value.binary_authorization_policy

      dynamic "secret_environment_variables" {
        for_each = service_config.value.secret_environment_variables
        content {
          key        = secret_environment_variables.value.key
          project_id = coalesce(secret_environment_variables.value.project_id, var.project_id)
          secret     = secret_environment_variables.value.secret
          version    = secret_environment_variables.value.version
        }
      }

      dynamic "secret_volumes" {
        for_each = service_config.value.secret_volumes
        content {
          mount_path = secret_volumes.value.mount_path
          project_id = coalesce(secret_volumes.value.project_id, var.project_id)
          secret     = secret_volumes.value.secret

          dynamic "versions" {
            for_each = secret_volumes.value.versions
            content {
              version = versions.value.version
              path    = versions.value.path
            }
          }
        }
      }
    }
  }

  dynamic "event_trigger" {
    for_each = var.event_trigger != null ? [var.event_trigger] : []
    content {
      trigger_region = event_trigger.value.trigger_region
      event_type     = event_trigger.value.event_type
      pubsub_topic   = event_trigger.value.pubsub_topic
      service_account_email = (
        event_trigger.value.service_account_email != null
        ? event_trigger.value.service_account_email
        : var.function_service_account_email
      )
      retry_policy = event_trigger.value.retry_policy

      dynamic "event_filters" {
        for_each = event_trigger.value.event_filters
        content {
          attribute = event_filters.value.attribute
          value     = event_filters.value.value
          operator  = event_filters.value.operator
        }
      }
    }
  }

  # lifecycle {
  #   precondition {
  #     condition     = !local.use_storage_source || (var.storage_source_bucket != null && var.storage_source_object != null)
  #     error_message = "storage_source_bucket and storage_source_object are required when source_type = \"storage\"."
  #   }
  #   precondition {
  #     condition     = local.use_storage_source || var.repo_source != null
  #     error_message = "repo_source is required when source_type = \"repo\"."
  #   }
  #   precondition {
  #     condition     = !var.enable_event_trigger || var.event_trigger_event_type != null
  #     error_message = "event_trigger_event_type is required when enable_event_trigger = true."
  #   }
  # }
}

# -----------------------------------------------------------------------------
# IAM: invoker access (Cloud Run under the hood for gen2 functions)
# -----------------------------------------------------------------------------
resource "google_cloud_run_service_iam_member" "invoker" {
  for_each = toset(local.invoker_members)

  project  = var.project_id
  location = google_cloudfunctions2_function.function.location
  service  = google_cloudfunctions2_function.function.name
  role     = "roles/run.invoker"
  member   = each.value
}