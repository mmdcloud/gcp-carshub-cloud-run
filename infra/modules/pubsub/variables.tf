# -------------------------------------------------------------------------------
# Core Configuration
# -------------------------------------------------------------------------------
variable "project_id" {
  description = "The GCP Project ID where resources will be deployed."
  type        = string
  default     = null
}

variable "labels" {
  description = "A map of labels to assign to the resources."
  type        = map(string)
  default     = {}
}

# -------------------------------------------------------------------------------
# Schema Configuration
# -------------------------------------------------------------------------------
variable "enable_schema" {
  description = "Whether to create and attach a Pub/Sub schema to the topic."
  type        = bool
  default     = false
}

variable "schema_name" {
  description = "The name of the Pub/Sub schema."
  type        = string
  default     = null
}

variable "schema_type" {
  description = "The type of the schema definition (PROTOCOL_BUFFER or AVRO)."
  type        = string
  default     = "AVRO"
  validation {
    condition     = contains(["PROTOCOL_BUFFER", "AVRO"], var.schema_type)
    error_message = "schema_type must be either 'PROTOCOL_BUFFER' or 'AVRO'."
  }
}

variable "schema_definition" {
  description = "The definition of the schema. Must match the specified schema_type."
  type        = string
  default     = null
}

variable "schema_encoding" {
  description = "The encoding format of the messages (JSON or BINARY)."
  type        = string
  default     = "JSON"
  validation {
    condition     = contains(["JSON", "BINARY"], var.schema_encoding)
    error_message = "schema_encoding must be either 'JSON' or 'BINARY'."
  }
}

# -------------------------------------------------------------------------------
# Topic Configuration
# -------------------------------------------------------------------------------
variable "topic_name" {
  description = "The name of the Pub/Sub topic."
  type        = string
}

variable "kms_key_name" {
  description = "The Cloud KMS resource name of the key used to encrypt messages."
  type        = string
  default     = null
}

variable "message_retention_duration" {
  description = "Indicates the minimum duration to retain a message after it is published (e.g., '86400s')."
  type        = string
  default     = null
}

variable "deletion_policy" {
  description = "The deletion policy for the topic (NEVER, DELETE_IMMEDIATELY, default: null)."
  type        = string
  default     = null
}

variable "message_storage_policy_allowed_regions" {
  description = "A list of GCP region IDs where messages are allowed to be stored."
  type        = list(string)
  default     = []
}

variable "topic_message_transforms" {
  type = list(object({
    disabled = optional(bool, false)
    javascript_udf = optional(object({
      function_name = string
      code          = string
    }), null)
  }))
  default = []
}

variable "ingestion_data_source_settings" {
  description = "Ingestion settings for importing data into Pub/Sub from third-party sources or Cloud Storage."
  type = object({
    # Platform Logs
    platform_logs_settings = optional(object({
      severity = optional(string, "WARNING") # DEBUG, INFO, WARNING, ERROR, DISABLED
    }), null)

    # 1. Cloud Storage Source
    cloud_storage = optional(object({
      bucket                     = string
      match_glob                 = optional(string, "**")
      minimum_object_create_time = optional(string, null)
      # Choose EXACTLY ONE format configuration
      text_format = optional(object({
        delimiter = optional(string, "\n")
      }), null)
      avro_format        = optional(object({}), null)
      pubsub_avro_format = optional(object({}), null)
    }), null)

    # 2. AWS Kinesis Data Streams Source
    aws_kinesis = optional(object({
      stream_arn          = string
      consumer_arn        = string
      aws_role_arn        = string
      gcp_service_account = string
    }), null)

    # 3. AWS MSK (Managed Streaming for Kafka) Source
    aws_msk = optional(object({
      cluster_arn         = string
      topic               = string
      aws_role_arn        = string
      gcp_service_account = string
    }), null)

    # 4. Azure Event Hubs Source
    azure_event_hubs = optional(object({
      resource_group      = string
      namespace           = string
      event_hub           = string
      client_id           = string
      tenant_id           = string
      subscription_id     = string
      gcp_service_account = string
    }), null)

    # 5. Confluent Cloud Source
    confluent_cloud = optional(object({
      bootstrap_server    = string
      cluster_id          = string
      topic               = string
      identity_pool_id    = string
      gcp_service_account = string
    }), null)
  })
  default = null
}

# -------------------------------------------------------------------------------
# Subscriptions Configuration
# -------------------------------------------------------------------------------
variable "subscriptions" {
  description = "Map of subscription configurations for production flexibility."
  type = map(object({
    subscription_name            = string
    ack_deadline_seconds         = optional(number, 10)
    message_retention_duration   = optional(string, "604800s") # 7 days
    retain_acked_messages        = optional(bool, false)
    filter                       = optional(string, null)
    enable_exactly_once_delivery = optional(bool, false)
    enable_message_ordering      = optional(string, null)
    # Expiration Policy
    ttl = optional(string, "") # Set to "" to never expire

    # Dead Letter Policy
    dead_letter_topic     = optional(string, null)
    max_delivery_attempts = optional(number, 5)

    # Retry Policy
    minimum_backoff = optional(string, "10s")
    maximum_backoff = optional(string, "600s")

    message_transforms = optional(list(object({
      disabled = optional(bool, false)
      javascript_udf = optional(object({
        function_name = string
        code          = string
      }), null)
    })), [])

    # Push Configuration
    push_config = optional(object({
      push_endpoint = string
      attributes    = optional(map(string), {})
      oidc_token = optional(object({
        service_account_email = string
        audience              = optional(string, null)
      }), null)
    }), null)

    # Subscription-level IAM
    iam = optional(object({
      bindings = optional(map(list(string)), {})
      members = optional(list(object({
        role   = string
        member = string
      })), [])
    }), {})

    # BigQuery Ingestion Configuration
    bigquery_config = optional(object({
      table                 = string
      use_topic_schema      = optional(bool, true)
      write_metadata        = optional(bool, false)
      drop_unknown_fields   = optional(bool, false)
      service_account_email = optional(string, null)
    }), null)

    # Cloud Storage Ingestion Configuration
    cloud_storage_config = optional(object({
      bucket                = string
      filename_prefix       = optional(string, null)
      filename_suffix       = optional(string, null)
      max_duration          = optional(string, "300s")
      max_bytes             = optional(number, 10000000)
      service_account_email = optional(string, null)
    }), null)
  }))
  default = {}
}

variable "schema_iam" {
  description = "IAM bindings or members for the Pub/Sub schema."
  type = object({
    bindings = optional(map(list(string)), {}) # map of role -> list(members)
    members = optional(list(object({
      role   = string
      member = string
    })), [])
  })
  default = {}
}

# Topic IAM
variable "topic_iam" {
  description = "IAM bindings or members for the Pub/Sub topic."
  type = object({
    bindings = optional(map(list(string)), {}) # map of role -> list(members)
    members = optional(list(object({
      role   = string
      member = string
    })), [])
  })
  default = {}
}
