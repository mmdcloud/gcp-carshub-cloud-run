# -----------------------------------------------------------------------------------------
# Core
# -----------------------------------------------------------------------------------------
variable "is_regional" {
  description = "Whether to create a regional secret (google_secret_manager_regional_secret) instead of a global secret (google_secret_manager_secret). Regional secrets require `location` and ignore `replication`; global secrets require `replication` (or default to Google-managed automatic replication if you choose to set one) and ignore `location`."
  type        = bool
  default     = false
}

variable "secret_id" {
  description = "The ID (name) of the secret. Must be unique within the project (and region, if regional). 1-255 characters; letters, numbers, underscores and hyphens only."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]{1,255}$", var.secret_id))
    error_message = "secret_id must be 1-255 characters and contain only letters, numbers, underscores, and hyphens."
  }
}

variable "location" {
  description = "GCP region for the secret. Required (and only used) when is_regional = true."
  type        = string
  default     = null
}

variable "deletion_protection" {
  description = "If true, Terraform will refuse to destroy the secret. Recommended true for production secrets."
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------------------
# Lifecycle / TTL / Expiry
# -----------------------------------------------------------------------------------------
variable "expire_time" {
  description = "Timestamp (RFC3339 UTC, e.g. 2026-09-18T00:00:00Z) at which the secret is scheduled for expiration and auto-deletion. Mutually exclusive with ttl."
  type        = string
  default     = null
}

variable "ttl" {
  description = "Duration string (e.g. \"2592000s\" for 30 days) after creation at which the secret is scheduled for expiration. Mutually exclusive with expire_time."
  type        = string
  default     = null

  validation {
    condition     = var.ttl == null || can(regex("^[0-9]+s$", var.ttl))
    error_message = "ttl must be a duration string in seconds, e.g. \"2592000s\"."
  }
}

variable "version_destroy_ttl" {
  description = "Duration string (e.g. \"86400s\") that a disabled/destroyed secret version is retained before being permanently deleted. Recommended for production to allow recovery from accidental destruction."
  type        = string
  default     = null
}

variable "version_aliases" {
  description = "Map of alias name to version number, used to reference secret versions by a stable alias (e.g. { \"latest_stable\" = 5 })."
  type        = map(number)
  default     = {}
}

variable "is_version_enabled" {
  description = "Whether the created secret version is enabled (accessible) on creation."
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------------------
# Rotation
# -----------------------------------------------------------------------------------------
variable "rotation" {
  description = "Optional rotation configuration. When set, Pub/Sub topics in `topics` are notified on the configured schedule so an external process can rotate the secret value."
  type = object({
    next_rotation_time = optional(string) # RFC3339 timestamp
    rotation_period     = optional(string) # duration string, e.g. "2592000s"
  })
  default = null
}

variable "topics" {
  description = "List of Pub/Sub topics to notify on secret events (rotation, version changes). Each topic must be a fully qualified topic name: projects/{project}/topics/{topic}."
  type = list(object({
    name = string
  }))
  default = []
}

# -----------------------------------------------------------------------------------------
# Encryption
# -----------------------------------------------------------------------------------------
variable "customer_managed_encryption" {
  description = "Optional CMEK configuration applied to the secret (regional) or to automatic replication (global). Provide the full KMS key resource name: projects/{project}/locations/{location}/keyRings/{ring}/cryptoKeys/{key}."
  type = object({
    kms_key_name = string
  })
  default = null
}

variable "replication" {
  description = "Replication policy for GLOBAL secrets only (ignored when is_regional = true). Set `auto` for Google-managed automatic replication (optionally with CMEK via var.customer_managed_encryption), or `user_managed` to pin replicas to specific locations."
  type = object({
    auto = optional(object({}))
    user_managed = optional(object({
      replicas = list(object({
        location = string
        customer_managed_encryption = optional(object({
          kms_key_name = string
        }))
      }))
    }))
  })
  default = {
    auto = {
      
    }
  }

  validation {
    condition = try(
      (var.replication.auto != null ? 1 : 0) +
      (var.replication.user_managed != null ? 1 : 0) == 1,
      true # var.replication is null -> nothing to validate, pass
    )
    error_message = "replication must set exactly one of `auto` or `user_managed`."
  }
}

# -----------------------------------------------------------------------------------------
# Secret data (sensitive)
# -----------------------------------------------------------------------------------------
variable "secret_data" {
  description = "The secret payload to store as the initial/current version. Marked sensitive so it is redacted from CLI output and logs."
  type        = string
  default     = null
  sensitive   = true
}

variable "is_secret_data_base64" {
  description = "Set true if secret_data is already base64-encoded."
  type        = bool
  default     = false
}

variable "secret_data_wo" {
  description = "Write-only secret payload (global secrets only). Use instead of secret_data to avoid persisting the value in Terraform state; must be paired with secret_data_wo_version."
  type        = string
  default     = null
  sensitive   = true
}

variable "secret_data_wo_version" {
  description = "Version number to associate with secret_data_wo. Increment this to push a new write-only value without state ever holding the previous plaintext."
  type        = number
  default     = null
}

# -----------------------------------------------------------------------------------------
# IAM
# -----------------------------------------------------------------------------------------
variable "additional_accessors" {
  description = "Additional IAM members (e.g. \"serviceAccount:foo@project.iam.gserviceaccount.com\", \"user:jane@example.com\") to grant roles/secretmanager.secretAccessor on this secret, beyond the default Compute Engine default service account binding created by this module."
  type        = list(string)
  default     = []
}