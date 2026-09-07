# ------------------------------------------------------------------------------
# CORE ARTIFACT REGISTRY ARGUMENTS
# ------------------------------------------------------------------------------

variable "location" {
  description = "The name of the location this repository is located in."
  type        = string
  default     = "asia-south1"
}

variable "repository_id" {
  description = "The last part of the repository name, for example: my-repo."
  type        = string
}

variable "description" {
  description = "The user-provided description of the repository."
  type        = string
  default     = "Production Artifact Registry Repository"
}

variable "artifact_type" {
  description = "The format of packages stored in the repository (e.g., DOCKER, MAVEN, NPM, PYTHON, HELM)."
  type        = string
  default     = "DOCKER"
}

variable "cleanup_policy_dry_run" {
  description = "If true, deletion actions of cleanup policies will not actually delete artifacts."
  type        = bool
  default     = false
}

variable "mode" {
  description = "The mode of the repository. Valid values are STANDARD_REPOSITORY, VIRTUAL_REPOSITORY, or REMOTE_REPOSITORY."
  type        = string
  default     = "STANDARD_REPOSITORY"
}

variable "kms_key_name" {
  description = "The Cloud KMS resource name of the customer-managed encryption key (CMEK) used to protect top-level resources."
  type        = string
  default     = null
}

# ------------------------------------------------------------------------------
# VULNERABILITY SCANNING CONFIGURATION
# ------------------------------------------------------------------------------

variable "vulnerability_scanning_config" {
  description = "Configuration for vulnerability scanning on this repository."
  type = object({
    enablement_config = string # Valid values: INHERITED, DISABLED
  })
  default = null
}

# ------------------------------------------------------------------------------
# MAVEN CONFIGURATION
# ------------------------------------------------------------------------------

variable "maven_config" {
  description = "Maven repository configuration. Mandatory if format is MAVEN."
  type = object({
    allow_snapshot_overwrites = optional(bool, false)
    version_policy            = optional(string, "VERSION_POLICY_UNSPECIFIED") # RELEASE, SNAPSHOT, VERSION_POLICY_UNSPECIFIED
  })
  default = null
}

# ------------------------------------------------------------------------------
# DOCKER CONFIGURATION
# ------------------------------------------------------------------------------

variable "docker_config" {
  description = "Docker repository configuration. Mandatory if format is DOCKER."
  type = object({
    immutable_tags = optional(bool, false)
  })
  default = null
}

# ------------------------------------------------------------------------------
# VIRTUAL REPOSITORY CONFIGURATION
# ------------------------------------------------------------------------------

variable "virtual_repository_config" {
  description = "Configuration for a Virtual Repository. Mandatory if mode is VIRTUAL_REPOSITORY."
  type = object({
    upstream_policies = list(object({
      id         = string
      priority   = number
      repository = string # Full resource path to upstream repository
    }))
  })
  default = null
}

# ------------------------------------------------------------------------------
# LABELS
# ------------------------------------------------------------------------------

variable "labels" {
  description = "Labels to attach to the Artifact Registry repository."
  type        = map(string)
  default     = {}
}