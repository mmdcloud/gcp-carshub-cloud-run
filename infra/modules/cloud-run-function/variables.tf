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

variable "function_service_account_email" {
  description = "Default service account email, used as a fallback for the event trigger's service_account_email when the trigger doesn't specify its own."
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# Source configuration (storage vs repo)
# -----------------------------------------------------------------------------
variable "repo_source" {
  description = "Repo source configuration used for the precondition check (required when source_type = \"repo\")."
  type = object({
    project_id  = optional(string)
    repo_name   = optional(string)
    branch_name = optional(string)
    tag_name    = optional(string)
    commit_sha  = optional(string)
    dir         = optional(string)
  })
  default = null
}

# -----------------------------------------------------------------------------
# Build configuration
# -----------------------------------------------------------------------------

variable "build_config" {
  description = "Build configuration block. Set to null to omit the build_config block entirely."
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
  default = null
}

# -----------------------------------------------------------------------------
# Service configuration
# -----------------------------------------------------------------------------

variable "service_config" {
  description = "Service (runtime) configuration block. Set to null to omit the service_config block entirely."
  type = object({
    max_instance_count               = optional(number)
    min_instance_count               = optional(number)
    max_instance_request_concurrency = optional(number)
    available_memory                 = optional(string, "256M")
    available_cpu                    = optional(string)
    timeout_seconds                  = optional(number, 60)
    ingress_settings                 = optional(string, "ALLOW_ALL")
    all_traffic_on_latest_revision   = optional(bool, true)
    service_account_email            = optional(string)
    service_environment_variables    = optional(map(string), {})

    vpc_connector                 = optional(string)
    vpc_connector_egress_settings = optional(string)

    binary_authorization_policy = optional(string)

    secret_environment_variables = optional(list(object({
      key        = string
      project_id = optional(string)
      secret     = string
      version    = string
    })), [])

    secret_volumes = optional(list(object({
      mount_path = string
      project_id = optional(string)
      secret     = string
      versions = list(object({
        version = string
        path    = string
      }))
    })), [])
  })
  default = null
}

# -----------------------------------------------------------------------------
# Event trigger configuration
# -----------------------------------------------------------------------------
variable "event_trigger" {
  description = "Event trigger configuration. Set to null for HTTP-triggered functions."
  type = object({
    trigger_region        = optional(string)
    event_type            = string
    pubsub_topic          = optional(string)
    service_account_email = optional(string)
    retry_policy          = optional(string)
    event_filters = optional(list(object({
      attribute = string
      value     = string
      operator  = optional(string)
    })), [])
  })
  default = null
}

# -----------------------------------------------------------------------------
# IAM / invoker access
# -----------------------------------------------------------------------------

variable "grant_all_users_invoker" {
  description = "If true, grants roles/run.invoker to allUsers (public access), overriding invoker_members."
  type        = bool
  default     = false
}

variable "invoker_members" {
  description = "List of IAM members (e.g. \"user:...\", \"serviceAccount:...\") granted roles/run.invoker. Ignored if grant_all_users_invoker = true."
  type        = list(string)
  default     = []
}
