# --------------------------------------------------------------------------------------------
# Core bucket settings
# --------------------------------------------------------------------------------------------

variable "project_id" {
  description = "The ID of the project in which resources will be created."
  type        = string
}

variable "name" {
  description = "The name of the bucket."
  type        = string
}

variable "location" {
  description = "The GCS location (region, dual-region, or multi-region) of the bucket."
  type        = string
  default     = "US"
}

variable "force_destroy" {
  description = "When true, allows deletion of a non-empty bucket by deleting all objects within it."
  type        = bool
  default     = false
}

variable "storage_class" {
  description = "The storage class of the bucket (STANDARD, NEARLINE, COLDLINE, ARCHIVE, MULTI_REGIONAL, REGIONAL)."
  type        = string
  default     = "STANDARD"
}

variable "uniform_bucket_level_access" {
  description = "Whether to enable uniform bucket-level access (disables per-object ACLs)."
  type        = bool
  default     = true
}

variable "default_event_based_hold" {
  description = "Whether newly created objects should have an event-based hold applied by default."
  type        = bool
  default     = false
}

variable "rpo" {
  description = "The recovery point objective for dual-region buckets (DEFAULT or ASYNC_TURBO)."
  type        = string
  default     = null
}

variable "enable_object_retention" {
  description = "Whether object retention (object-level retention configuration) is enabled for this bucket."
  type        = bool
  default     = false
}

variable "requester_pays" {
  description = "Whether the requester (caller) pays for access/egress costs instead of the bucket owner."
  type        = bool
  default     = false
}

variable "public_access_prevention" {
  description = "Prevents public access to the bucket (inherited or enforced)."
  type        = string
  default     = "inherited"
}

variable "versioning" {
  description = "Whether object versioning is enabled on the bucket."
  type        = bool
  default     = false
}

variable "enable_hierarchical_namespace" {
  description = "Whether hierarchical namespace (HNS) is enabled for this bucket."
  type        = bool
  default     = false
}

# --------------------------------------------------------------------------------------------
# Placement / retention / logging / IP filter
# --------------------------------------------------------------------------------------------

variable "custom_placement_config" {
  description = "Map keyed by bucket name of custom dual-region placement configs (data_locations)."
  type = map(object({
    data_locations = list(string)
  }))
  default = {}
}

variable "soft_delete_policy" {
  description = "Map keyed by bucket name of soft delete policy retention duration (in seconds)."
  type = map(object({
    retention_duration_seconds = optional(number)
  }))
  default = {}
}

variable "retention_policy" {
  description = "Bucket retention policy. Null to omit the block entirely."
  type = object({
    is_locked        = bool
    retention_period = number
  })
  default = null
}

variable "logging" {
  description = "Bucket access logging configuration. Null to omit the block entirely."
  type = object({
    log_bucket        = string
    log_object_prefix = optional(string)
  })
  default = null
}

variable "ip_filter" {
  description = "IP filtering configuration for the bucket. Null to omit the block entirely."
  type = object({
    allow_all_service_agent_access = optional(bool)
    allow_cross_org_vpcs           = optional(bool)
    mode                           = string
    public_network_source = optional(object({
      allowed_ip_cidr_ranges = list(string)
    }))
    vpc_network_sources = optional(object({
      allowed_ip_cidr_ranges = list(string)
      network                = string
    }))
  })
  default = null
}

# --------------------------------------------------------------------------------------------
# CORS / autoclass / encryption / website / lifecycle
# --------------------------------------------------------------------------------------------

variable "cors" {
  description = "List of CORS configuration rules for the bucket."
  type = list(object({
    max_age_seconds = optional(number)
    method          = list(string)
    origin          = list(string)
    response_header = optional(list(string))
  }))
  default = []
}

variable "autoclass" {
  description = "Autoclass configuration for the bucket. Null to omit the block entirely."
  type = object({
    enabled                 = bool
    terminal_storage_class  = optional(string)
  })
  default = null
}

variable "encryption_key_names" {
  description = "Map of bucket name (lowercase) to the CMEK key name used to encrypt that bucket's objects. Leave a value empty/absent to skip the encryption block."
  type        = map(string)
  default     = {}
}

variable "website" {
  description = "Website configuration for the bucket. Leave both fields null to omit the block entirely."
  type = object({
    main_page_suffix = optional(string)
    not_found_page   = optional(string)
  })
  default = {
    main_page_suffix = null
    not_found_page   = null
  }
}

variable "lifecycle_rules" {
  description = "List of lifecycle rules for the bucket."
  type = list(object({
    condition = object({
      age                                      = optional(number)
      created_before                           = optional(string)
      custom_time_before                       = optional(string)
      days_since_custom_time                   = optional(number)
      days_since_noncurrent_time                = optional(number)
      matches_prefix                           = optional(list(string))
      matches_storage_class                    = optional(list(string))
      matches_suffix                           = optional(list(string))
      noncurrent_time_before                   = optional(string)
      num_newer_versions                       = optional(number)
      send_age_if_zero                         = optional(bool)
      send_days_since_custom_time_if_zero      = optional(bool)
      send_days_since_noncurrent_time_if_zero  = optional(bool)
      send_num_newer_versions_if_zero          = optional(bool)
      with_state                               = optional(string)
    })
    action = object({
      type          = string
      storage_class = optional(string)
    })
  }))
  default = []
}

# --------------------------------------------------------------------------------------------
# Objects / notifications
# --------------------------------------------------------------------------------------------

variable "contents" {
  description = "List of objects to upload into the bucket. Provide either source_path (a local file) or content (inline string) per item."
  type = list(object({
    name        = string
    source_path = optional(string, "")
    content     = optional(string, "")
  }))
  default = []
}

variable "notifications" {
  description = "List of Pub/Sub notification configurations for the bucket."
  type = list(object({
    event_types         = optional(list(string))
    payload_format      = optional(string)
    topic_id            = string
    object_name_prefix  = optional(string)
    custom_attributes   = optional(map(string))
  }))
  default = []
}

# --------------------------------------------------------------------------------------------
# Anywhere Cache
# --------------------------------------------------------------------------------------------

variable "enable_storage_anywhere_cache" {
  description = "Anywhere Cache configuration. Set to null/omit to disable; provide an object to enable the cache. NOTE: the resource's count expression currently checks `== true`, which will never match an object value — update that condition (e.g. to `!= null`) to actually enable this."
  type = object({
    zone            = string
    ttl             = optional(string)
    ingest_on_write = optional(bool)
  })
  default = null
}

# --------------------------------------------------------------------------------------------
# HMAC keys
# --------------------------------------------------------------------------------------------

variable "set_hmac_access" {
  description = "Whether to create HMAC keys for the given service accounts."
  type        = bool
  default     = false
}

variable "hmac_service_accounts" {
  description = "Map of service account email to desired HMAC key state (ACTIVE or INACTIVE)."
  type        = map(string)
  default     = {}
}

# --------------------------------------------------------------------------------------------
# Bucket IAM
# --------------------------------------------------------------------------------------------

variable "set_admin_roles" {
  description = "Whether to grant roles/storage.objectAdmin on the bucket(s)."
  type        = bool
  default     = false
}

variable "admins" {
  description = "List of members to grant roles/storage.objectAdmin on every bucket."
  type        = list(string)
  default     = []
}

variable "bucket_admins" {
  description = "Map of bucket name to a comma-separated string of additional objectAdmin members for that bucket."
  type        = map(string)
  default     = {}
}

variable "set_creator_roles" {
  description = "Whether to grant roles/storage.objectCreator on the bucket(s)."
  type        = bool
  default     = false
}

variable "creators" {
  description = "List of members to grant roles/storage.objectCreator on every bucket."
  type        = list(string)
  default     = []
}

variable "bucket_creators" {
  description = "Map of bucket name to a comma-separated string of additional objectCreator members for that bucket."
  type        = map(string)
  default     = {}
}

variable "set_viewer_roles" {
  description = "Whether to grant roles/storage.objectViewer on the bucket(s)."
  type        = bool
  default     = false
}

variable "viewers" {
  description = "List of members to grant roles/storage.objectViewer on every bucket."
  type        = list(string)
  default     = []
}

variable "bucket_viewers" {
  description = "Map of bucket name to a comma-separated string of additional objectViewer members for that bucket."
  type        = map(string)
  default     = {}
}

variable "set_hmac_key_admin_roles" {
  description = "Whether to grant roles/storage.hmacKeyAdmin on the bucket(s)."
  type        = bool
  default     = false
}

variable "hmac_key_admins" {
  description = "List of members to grant roles/storage.hmacKeyAdmin on every bucket."
  type        = list(string)
  default     = []
}

variable "bucket_hmac_key_admins" {
  description = "Map of bucket name to a comma-separated string of additional hmacKeyAdmin members for that bucket."
  type        = map(string)
  default     = {}
}

variable "set_storage_admin_roles" {
  description = "Whether to grant roles/storage.admin on the bucket(s)."
  type        = bool
  default     = false
}

variable "storage_admins" {
  description = "List of members to grant roles/storage.admin on every bucket."
  type        = list(string)
  default     = []
}

variable "bucket_storage_admins" {
  description = "Map of bucket name to a comma-separated string of additional storage.admin members for that bucket."
  type        = map(string)
  default     = {}
}

# --------------------------------------------------------------------------------------------
# HNS / Managed folders
# --------------------------------------------------------------------------------------------

variable "hns_folders" {
  description = "List of root-level hierarchical namespace folders to create in the bucket."
  type = list(object({
    name          = string
    force_destroy = optional(bool, false)
  }))
  default = []
}

variable "managed_folders" {
  description = "List of root-level managed folders to create in the bucket."
  type = list(object({
    name          = string
    force_destroy = optional(bool, false)
  }))
  default = []
}