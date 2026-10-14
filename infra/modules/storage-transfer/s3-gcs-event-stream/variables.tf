variable "description" {}
variable "notification_config" {
  type = list(object({
    pubsub_topic   = string
    event_types    = list(string)
    payload_format = string
  }))
  default = null
}
variable "status" {
  type    = string
  default = "ENABLED"
}
variable "name" {
  type    = string
  default = null
}

variable "schedule" {
  type = list(object({
    start_year  = number
    start_month = number
    start_day   = number

    end_year  = number
    end_month = number
    end_day   = number

    hours   = number
    minutes = number
    seconds = number
    nanos   = number

    schedule_repeat_interval = string
  }))
  default = []
}

variable "event_stream" {
  description = "Event-driven transfer config. Mutually exclusive with `schedule` — set at most one of the two."
  type = list(object({
    name                         = string
    event_stream_start_time      = optional(string)
    event_stream_expiration_time = optional(string)
  }))
  default = []
}

variable "logging_config" {
  description = "Optional logging configuration for the transfer job."
  type = object({
    enable_on_prem_gcs_transfer_logs = optional(bool)
    log_actions                      = optional(list(string))
    log_action_states                = optional(list(string))
  })
  default = null
}

variable "transfer_spec" {
  description = "Transfer specification. Mutually exclusive with replication_spec — set exactly one of the two."
  type = object({
    source_agent_pool_name = optional(string)
    sink_agent_pool_name   = optional(string)

    gcs_data_sink   = optional(object({ bucket_name = string, path = optional(string) }))
    posix_data_sink = optional(object({ root_directory = string }))

    gcs_data_source   = optional(object({ bucket_name = string, path = optional(string) }))
    posix_data_source = optional(object({ root_directory = string }))

    aws_s3_data_source = optional(object({
      bucket_name             = string
      path                    = optional(string)
      role_arn                = optional(string)
      managed_private_network = optional(bool)
      cloudfront_domain       = optional(string)
      credentials_secret      = optional(string)
      aws_access_key = optional(object({
        access_key_id     = string
        secret_access_key = string
      }))
    }))

    aws_s3_compatible_data_source = optional(object({
      bucket_name = string
      path        = optional(string)
      endpoint    = string
      region      = optional(string)
      s3_metadata = optional(object({
        auth_method   = optional(string)
        request_model = optional(string)
        protocol      = optional(string)
        list_api      = optional(string)
      }))
    }))

    http_data_source = optional(object({ list_url = string }))
    hdfs_data_source = optional(object({ path = string }))

    azure_blob_storage_data_source = optional(object({
      storage_account         = string
      container               = string
      path                    = string
      credentials_secret      = optional(string)
      private_network_service = optional(string)
      azure_credentials       = optional(object({ sas_token = string }))
      federated_identity_config = optional(object({
        client_id = string
        tenant_id = string
      }))
    }))

    object_conditions = optional(object({
      max_time_elapsed_since_last_modification = optional(string)
      min_time_elapsed_since_last_modification = optional(string)
      include_prefixes                         = optional(list(string))
      exclude_prefixes                         = optional(list(string))
      last_modified_since                      = optional(string)
      last_modified_before                     = optional(string)
    }))

    transfer_options = optional(object({
      overwrite_objects_already_existing_in_sink = optional(bool)
      delete_objects_unique_in_sink              = optional(bool)
      delete_objects_from_source_after_transfer  = optional(bool)
      overwrite_when                             = optional(string)
      metadata_options = optional(object({
        symlink        = optional(string)
        mode           = optional(string)
        gid            = string
        uid            = optional(string)
        acl            = optional(string)
        storage_class  = optional(string)
        temporary_hold = optional(string)
        kms_key        = optional(string)
        time_created   = optional(string)
      }))
    }))

    transfer_manifest = optional(object({ location = string }))
  })
  default = null
}

variable "replication_spec" {
  description = "Replication specification. Mutually exclusive with transfer_spec (set this OR source_bucket_name/dest_bucket_name, not both). Cannot be combined with schedule or event_stream."
  type = list(object({
    source_bucket_name = string
    source_path        = optional(string)
    sink_bucket_name   = string
    sink_path          = optional(string)
    object_conditions = optional(object({
      max_time_elapsed_since_last_modification = optional(string)
      min_time_elapsed_since_last_modification = optional(string)
      include_prefixes                         = optional(list(string))
      exclude_prefixes                         = optional(list(string))
      last_modified_since                      = optional(string)
      last_modified_before                     = optional(string)
    }))
    transfer_options = optional(object({
      overwrite_objects_already_existing_in_sink = optional(bool)
      delete_objects_unique_in_sink              = optional(bool)
      delete_objects_from_source_after_transfer  = optional(bool)
      overwrite_when                             = optional(string)
    }))
  }))
  default = []
}
