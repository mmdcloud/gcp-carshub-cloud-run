locals {
  # Default to function location if trigger_region is omitted
  trigger_location = coalesce(var.event_trigger.trigger_region, var.location)
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
      # Default event functions to internal-only ingress for security
      ingress_settings                 = coalesce(service_config.value.ingress_settings, "ALLOW_INTERNAL_ONLY")
      all_traffic_on_latest_revision   = service_config.value.all_traffic_on_latest_revision
      service_account_email            = service_config.value.service_account_email
      environment_variables            = service_config.value.service_environment_variables

      vpc_connector                 = service_config.value.vpc_connector
      vpc_connector_egress_settings = service_config.value.vpc_connector != null ? try(service_config.value.vpc_connector_egress_settings, null) : null

      binary_authorization_policy = service_config.value.binary_authorization_policy

      dynamic "secret_environment_variables" {
        for_each = coalesce(service_config.value.secret_environment_variables, [])
        content {
          key        = secret_environment_variables.value.key
          project_id = coalesce(secret_environment_variables.value.project_id, var.project_id)
          secret     = secret_environment_variables.value.secret
          version    = secret_environment_variables.value.version
        }
      }

      dynamic "secret_volumes" {
        for_each = coalesce(service_config.value.secret_volumes, [])
        content {
          mount_path = secret_volumes.value.mount_path
          project_id = coalesce(secret_volumes.value.project_id, var.project_id)
          secret     = secret_volumes.value.secret

          dynamic "versions" {
            for_each = coalesce(secret_volumes.value.versions, [])
            content {
              version = versions.value.version
              path    = versions.value.path
            }
          }
        }
      }
    }
  }

  event_trigger {
    trigger_region        = local.trigger_location
    event_type            = var.event_trigger.event_type
    pubsub_topic          = var.event_trigger.pubsub_topic
    service_account_email = var.event_trigger.service_account_email
    retry_policy          = var.event_trigger.retry_policy

    dynamic "event_filters" {
      for_each = coalesce(var.event_trigger.event_filters, [])
      content {
        attribute = event_filters.value.attribute
        value     = event_filters.value.value
        operator  = event_filters.value.operator
      }
    }
  }

  lifecycle {
    precondition {
      condition = (
        (try(var.build_config.storage_source, null) != null) !=
        (try(var.build_config.repo_source, null) != null)
      )
      error_message = "Provide exactly one of 'storage_source' or 'repo_source' inside build_config."
    }
  }
}

# -----------------------------------------------------------------------------
# IAM: Authorize the Trigger Identity to Invoke the Underlying Cloud Run Service
# -----------------------------------------------------------------------------
resource "google_cloud_run_service_iam_member" "event_invoker" {
  count = var.event_trigger.service_account_email != null ? 1 : 0

  project  = var.project_id
  location = google_cloudfunctions2_function.function.location
  service  = google_cloudfunctions2_function.function.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${var.event_trigger.service_account_email}"
}