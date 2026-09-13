variable "project_id" {
  description = "Project the repository (and project-level configs) belong to."
  type        = string
}

variable "location" {
  description = "Region or multi-region, e.g. us-central1 or us."
  type        = string
}

variable "repository_id" {
  description = "ID of the repository."
  type        = string
}

variable "description" {
  description = "Human-readable description."
  type        = string
  default     = null
}

variable "artifact_type" {
  description = "Repository format, e.g. DOCKER, MAVEN, NPM, PYTHON, APT, YUM, GO."
  type        = string
}

variable "cleanup_policy_dry_run" {
  description = "If true, cleanup policies are evaluated but nothing is actually deleted."
  type        = bool
  default     = false
}

variable "mode" {
  description = "STANDARD_REPOSITORY, VIRTUAL_REPOSITORY, or REMOTE_REPOSITORY."
  type        = string
  default     = "STANDARD_REPOSITORY"
}

variable "kms_key_name" {
  description = "CMEK key resource name. Cannot be changed after creation."
  type        = string
  default     = null
}

variable "labels" {
  description = "Caller-supplied labels, merged with the module's baseline labels."
  type        = map(string)
  default     = {}
}

variable "vulnerability_scanning_config" {
  type = object({
    enablement_config = string # "INHERITED" | "DISABLED"
  })
  default = null
}

variable "maven_config" {
  type = object({
    allow_snapshot_overwrites = optional(bool)
    version_policy             = optional(string)
  })
  default = null
}

variable "docker_config" {
  type = object({
    immutable_tags = optional(bool)
  })
  default = null
}

variable "virtual_repository_config" {
  type = object({
    upstream_policies = list(object({
      id         = string
      priority   = number
      repository = string
    }))
  })
  default = null
}

# --- IAM ---------------------------------------------------------------

variable "iam_members" {
  description = "Repository-level IAM bindings, e.g. [{ role = \"roles/artifactregistry.reader\", member = \"serviceAccount:ci@project.iam.gserviceaccount.com\" }]. Applied non-authoritatively (google_artifact_registry_repository_iam_member)."
  type = list(object({
    role   = string
    member = string
    condition = optional(object({
      title       = string
      description = optional(string)
      expression  = string
    }))
  }))
  default = []
}

# --- Rules ---------------------------------------------------------------

variable "rules" {
  description = "Allow/deny rules for the repository or specific packages within it."
  type = list(object({
    rule_id    = string
    package_id = optional(string) # null/omitted = applies to the whole repository
    action     = string           # ALLOW | DENY
    operation  = optional(string, "DOWNLOAD")
    condition = optional(object({
      expression  = string
      title       = optional(string)
      description = optional(string)
    }))
  }))
  default = []
}

# --- Project config (platform logs) ---------------------------------------

variable "enable_project_config" {
  description = "If true, manage the project+location Artifact Registry platform-logs config."
  type        = bool
  default     = false
}

variable "platform_logs_config" {
  description = "Platform logs settings, used when var.enable_project_config is true."
  type = object({
    logging_state  = optional(string, "ENABLED")  # ENABLED | DISABLED
    severity_level = optional(string, "INFO")     # DEBUG..EMERGENCY
  })
  default = {
    logging_state  = "ENABLED"
    severity_level = "INFO"
  }
}

# --- VPC-SC config ---------------------------------------------------------

variable "enable_vpcsc_config" {
  description = "If true, manage the project+location VPC-SC policy for remote-repository upstream access."
  type        = bool
  default     = false
}

variable "vpcsc_policy" {
  description = "DENY (block upstream calls from inside a perimeter) or ALLOW. Used when var.enable_vpcsc_config is true. Defaults to the safer DENY."
  type        = string
  default     = "DENY"
  validation {
    condition     = contains(["DENY", "ALLOW"], var.vpcsc_policy)
    error_message = "var.vpcsc_policy must be DENY or ALLOW."
  }
}

variable "remote_repository_config" {
  type = object({
    description                 = optional(string)
    disable_upstream_validation = optional(bool, true)
    upstream_credentials = optional(object({
      username                = string
      password_secret_version = string
    }), null)
    apt_repository = optional(object({
      public_repository = optional(object({
        repository_base = string
        repository_path = string
      }), null)
    }), null)
    docker_repository = optional(object({
      public_repository = optional(string)
      custom_repository = optional(object({
        uri = string
      }), null)
    }), null)
    maven_repository = optional(object({
      public_repository = optional(string)
      custom_repository = optional(object({
        uri = string
      }), null)
    }), null)
    npm_repository = optional(object({
      public_repository = optional(string)
      custom_repository = optional(object({
        uri = string
      }), null)
    }), null)
    python_repository = optional(object({
      public_repository = optional(string)
      custom_repository = optional(object({
        uri = string
      }), null)
    }), null)
    yum_repository = optional(object({
      public_repository = optional(object({
        repository_base = string
        repository_path = string
      }), null)
    }), null)
  })
  description = "Configuration specific for a Remote Repository."
  default     = null
}

variable "cleanup_policies" {
  type = map(object({
    action = optional(string)
    condition = optional(object({
      tag_state             = optional(string)
      tag_prefixes          = optional(list(string))
      version_name_prefixes = optional(list(string))
      package_name_prefixes = optional(list(string))
      older_than            = optional(string)
      newer_than            = optional(string)
    }), null)
    most_recent_versions = optional(object({
      package_name_prefixes = optional(list(string))
      keep_count            = optional(number)
    }), null)
  }))
  description = "Cleanup policies for this repository. Cleanup policies indicate when certain package versions can be automatically deleted. Map keys are policy IDs supplied by users during policy creation. They must unique within a repository and be under 128 characters in length."
  default     = {}
}

variable "members" {
  type        = map(list(string))
  description = "Artifact Registry Reader and Writer roles for Users/SAs. Key names must be readers and/or writers"
  default     = {}
  validation {
    condition = alltrue([
      for key in keys(var.members) : contains(["readers", "writers"], key)
    ])
    error_message = "The supported keys are readers and writers."
  }
}