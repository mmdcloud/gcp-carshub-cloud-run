variable "description" {
  type        = string
  description = "Description for the POSIX/NFS to GCS transfer job."
}

variable "status" {
  type        = string
  description = "Status of the transfer job. Must be ENABLED, DISABLED, or DELETED."
  default     = "ENABLED"
}

variable "name" {
  type        = string
  description = "The name of the transfer job."
  default     = null
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

variable "logging_config" {
  description = "Logging configuration for on-prem/POSIX to GCS transfer job."
  type = object({
    enable_on_prem_gcs_transfer_logs = optional(bool)
    log_actions                      = optional(list(string))
    log_action_states                = optional(list(string))
  })
  default = {
    enable_on_prem_gcs_transfer_logs = true
    log_actions                      = ["FIND", "COPY", "DELETE"]
    log_action_states                = ["SUCCEEDED", "FAILED"]
  }
}

variable "notification_config" {
  type = list(object({
    pubsub_topic   = string
    event_types    = list(string)
    payload_format = string
  }))
  default = null
}

variable "transfer_spec" {
  description = "POSIX/NFS to GCS transfer specification."
  type = object({
    source_agent_pool_name = optional(string)
    sink_agent_pool_name   = optional(string)

    posix_data_source = object({
      root_directory = string
    })

    gcs_data_sink = object({
      bucket_name = string
      path        = optional(string)
    })

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
        gid            = optional(string)
        uid            = optional(string)
        acl            = optional(string)
        storage_class  = optional(string)
        temporary_hold = optional(string)
        kms_key        = optional(string)
        time_created   = optional(string)
      }))
    }))
  })
}

