# -----------------------------------------------------------------------------
# General
# -----------------------------------------------------------------------------

variable "project_id" {
  description = "GCP project ID where the function will be created."
  type        = string
}

variable "function_name" {
  description = "Name of the Cloud Function (2nd gen)."
  type        = string
}

variable "location" {
  description = "Region to deploy the function in."
  type        = string
  default     = "us-central1"
}

variable "function_description" {
  description = "Human-readable description of the function."
  type        = string
  default     = ""
}

variable "labels" {
  description = "Labels to apply to the function."
  type        = map(string)
  default     = {}
}

variable "kms_key_name" {
  description = "Customer-managed encryption key (CMEK) resource name, if any."
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# Build Configuration
# -----------------------------------------------------------------------------

variable "build_config" {
  description = "Build configuration for compiling and packaging the event-driven function."
  type = object({
    runtime                     = string
    handler                     = string
    build_environment_variables = optional(map(string), {})
    build_worker_pool           = optional(string)
    docker_repository           = optional(string)

    storage_source = optional(object({
      bucket     = string
      object     = string
      generation = optional(string)
    }))

    repo_source = optional(object({
      project_id  = optional(string)
      repo_name   = optional(string)
      branch_name = optional(string)
      tag_name    = optional(string)
      commit_sha  = optional(string)
      dir         = optional(string)
    }))
  })
}

# -----------------------------------------------------------------------------
# Service Configuration
# -----------------------------------------------------------------------------

variable "service_config" {
  description = "Service configuration for Cloud Functions Gen 2"
  type = object({
    max_instance_count               = optional(number, 10)
    min_instance_count               = optional(number, 0)
    max_instance_request_concurrency = optional(number)
    available_memory                 = optional(string, "256M")
    available_cpu                    = optional(string, "0.166")
    timeout_seconds                  = optional(number, 60)
    ingress_settings                 = optional(string)
    all_traffic_on_latest_revision   = optional(bool, true)
    service_account_email            = optional(string)
    service_environment_variables    = optional(map(string), {})
    vpc_connector                    = optional(string)
    vpc_connector_egress_settings    = optional(string)
    binary_authorization_policy      = optional(string)

    secret_environment_variables = optional(list(object({
      key        = string
      project_id = optional(string)
      secret     = string
      version    = optional(string, "latest")
    })), [])

    secret_volumes = optional(list(object({
      mount_path = string
      project_id = optional(string)
      secret     = string
      versions = optional(list(object({
        version = string
        path    = string
      })), [])
    })), [])
  })
  default = null
}

# -----------------------------------------------------------------------------
# Event Trigger Configuration
# -----------------------------------------------------------------------------

variable "event_trigger" {
  description = "Eventarc/PubSub trigger configuration."
  type = object({
    event_type            = string
    trigger_region        = optional(string)
    pubsub_topic          = optional(string)
    service_account_email = optional(string)
    retry_policy          = optional(string, "RETRY_POLICY_DO_NOT_RETRY")
    event_filters = optional(list(object({
      attribute = string
      value     = string
      operator  = optional(string)
    })), [])
  })

  validation {
    condition = (
      var.event_trigger.event_type != "google.cloud.pubsub.topic.v1.messagePublished" ||
      var.event_trigger.pubsub_topic != null
    )
    error_message = "When event_type is 'google.cloud.pubsub.topic.v1.messagePublished', 'pubsub_topic' must be specified."
  }
}
