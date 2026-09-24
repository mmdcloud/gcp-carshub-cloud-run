# variable "name" {}
# variable "location" {}
# variable "db_name" {}
# variable "db_version" {}
# variable "tier" {}
# variable "db_user" {}
# variable "password" {}
# variable "vpc_id" {}
# variable "vpc_self_link" {}
# variable "ipv4_enabled" {}
# variable "deletion_protection_enabled" {}
# variable "availability_type" {}
# variable "disk_size" {}
# variable "disk_type" {
#   type = string
#   default = "PD_SSD"
# }
# variable "disk_autoresize" {
#   type = bool
#   default = false
# }
# variable "disk_autoresize_limit" {
#   type = number
#   default = 0
# }
# variable "database_flags" {
#   type = list(object({
#     name  = string
#     value = string
#   }))
#   default = []  
# } 
# variable "backup_configuration" {
#   type = list(object({
#     enabled                        = bool
#     start_time                     = string
#     location                       = string
#     binary_log_enabled = bool
#     point_in_time_recovery_enabled = bool
#     backup_retention_settings = list(object({
#       retained_backups = number
#       retention_unit   = string
#     }))
#   }))
# }

############################
# Networking
############################

variable "vpc_id" {
  description = "Self link / ID of the VPC network to peer for private services access."
  type        = string
}

variable "vpc_self_link" {
  description = "Self link of the VPC network to attach as the private_network for the instance."
  type        = string
  default     = null
}

############################
# Core instance settings
############################

variable "name" {
  description = "Name of the Cloud SQL instance."
  type        = string
}

variable "location" {
  description = "Region for the Cloud SQL instance."
  type        = string
}

variable "db_version" {
  description = "Database engine and version, e.g. POSTGRES_15, MYSQL_8_0."
  type        = string
}

variable "password" {
  description = "Root password for the Cloud SQL instance / default DB user."
  type        = string
  sensitive   = true
}

variable "encryption_key_name" {
  description = "Self link of the KMS key used for CMEK disk encryption. Null uses Google-managed keys."
  type        = string
  default     = null
}

variable "enforce_new_sql_network_architecture" {
  description = "Whether to enforce the new SQL network architecture."
  type        = bool
  default     = null
}

variable "final_backup_description" {
  description = "Description applied to the automatically taken final backup on instance deletion."
  type        = string
  default     = null
}

variable "include_replicas_for_major_version_upgrade" {
  description = "Whether replicas are included when performing a major version upgrade."
  type        = bool
  default     = null
}

variable "maintenance_version" {
  description = "Maintenance version to pin the instance to."
  type        = string
  default     = null
}

variable "master_instance_name" {
  description = "Name of the master instance, set only when creating a read replica."
  type        = string
  default     = null
}

variable "node_count" {
  description = "Number of nodes in the instance (Enterprise Plus read pools)."
  type        = number
  default     = null
}

variable "instance_type" {
  description = "Type of the instance, e.g. CLOUD_SQL_INSTANCE, READ_REPLICA_INSTANCE, READ_POOL_INSTANCE."
  type        = string
  default     = null
}

variable "replica_names" {
  description = "List of replica names for this instance."
  type        = list(string)
  default     = null
}

variable "backupdr_backup" {
  description = "Resource name of the backup from Backup and DR used to create this instance."
  type        = string
  default     = null
}

variable "root_password_wo" {
  description = "Write-only root password for the instance (ephemeral, not stored in state)."
  type        = string
  sensitive   = true
  default     = null
}

variable "root_password_wo_version" {
  description = "Version counter that must be incremented to trigger a root_password_wo update."
  type        = number
  default     = null
}

variable "switch_transaction_logs_to_cloud_storage_enabled" {
  description = "Whether to switch transaction/WAL log storage to Cloud Storage."
  type        = bool
  default     = null
}

variable "deletion_protection" {
  description = "Top-level Terraform-managed deletion protection flag on the instance resource."
  type        = bool
  default     = false
}

############################
# Replication / restore / clone
############################

variable "replication_cluster" {
  description = "Replication cluster configuration for cross-region DR replicas."
  type = object({
    failover_dr_replica_name = optional(string)
    psa_write_endpoint       = optional(string)
  })
  default = null
}

variable "restore_backup_context" {
  description = "Backup context to restore the instance from."
  type = object({
    backup_run_id = number
    instance_id   = optional(string)
    project       = optional(string)
  })
  default = null
}

variable "point_in_time_restore_context" {
  description = "Point-in-time restore context for the instance."
  type = object({
    allocated_ip_range = optional(string)
    datasource         = string
    point_in_time      = string
    preferred_zone     = optional(string)
    region             = optional(string)
    target_instance    = optional(string)
  })
  default = null
}

variable "clone" {
  description = "Clone context to create this instance as a clone of another instance."
  type = object({
    allocated_ip_range            = optional(string)
    database_names                = optional(list(string))
    point_in_time                 = optional(string)
    preferred_zone                = optional(string)
    source_instance_deletion_time = optional(string)
    source_instance_name          = string
    source_project                = optional(string)
  })
  default = null
}

variable "replica_configuration" {
  description = "Configuration for a read replica pointing back at the master instance."
  type = object({
    ca_certificate            = optional(string)
    cascadable_replica        = optional(bool)
    client_certificate        = optional(string)
    client_key                = optional(string)
    connect_retry_interval    = optional(number)
    dump_file_path            = optional(string)
    failover_target           = optional(bool)
    master_heartbeat_period   = optional(number)
    password                  = optional(string)
    ssl_cipher                = optional(string)
    username                  = optional(string)
    verify_server_certificate = optional(bool)
  })
  default = null
}

############################
# settings {}
############################

variable "tier" {
  description = "Machine tier for the instance, e.g. db-custom-2-8192."
  type        = string
}

variable "availability_type" {
  description = "Availability type: ZONAL or REGIONAL."
  type        = string
  default     = "ZONAL"
}

variable "disk_size" {
  description = "Disk size in GB."
  type        = number
  default     = null
}

variable "disk_type" {
  description = "Disk type: PD_SSD or PD_HDD."
  type        = string
  default     = "PD_SSD"
}

variable "disk_autoresize" {
  description = "Whether to enable automatic disk growth."
  type        = bool
  default     = true
}

variable "disk_autoresize_limit" {
  description = "Maximum size, in GB, the disk can auto-grow to. 0 means no limit."
  type        = number
  default     = 0
}

variable "deletion_protection_enabled" {
  description = "Whether Cloud SQL's own deletion protection setting is enabled."
  type        = bool
  default     = true
}

variable "activation_policy" {
  description = "Activation policy for the instance: ALWAYS, NEVER, or ON_DEMAND."
  type        = string
  default     = null
}

variable "auto_upgrade_enabled" {
  description = "Whether minor engine version auto-upgrades are enabled."
  type        = bool
  default     = null
}

variable "collation" {
  description = "Collation to set for the database instance."
  type        = string
  default     = null
}

variable "connector_enforcement" {
  description = "Whether Cloud SQL Auth Proxy / connectors are required: REQUIRED or NOT_REQUIRED."
  type        = string
  default     = null
}

variable "data_api_access" {
  description = "Data API access setting for the instance."
  type        = string
  default     = null
}

variable "data_disk_provisioned_iops" {
  description = "Provisioned IOPS for the data disk (hyperdisk-backed tiers)."
  type        = number
  default     = null
}

variable "data_disk_provisioned_throughput" {
  description = "Provisioned throughput (MB/s) for the data disk (hyperdisk-backed tiers)."
  type        = number
  default     = null
}

variable "edition" {
  description = "Edition of the instance: ENTERPRISE or ENTERPRISE_PLUS."
  type        = string
  default     = null
}

variable "enable_dataplex_integration" {
  description = "Whether Dataplex integration is enabled."
  type        = bool
  default     = null
}

variable "enable_google_ml_integration" {
  description = "Whether Vertex AI / Google ML integration is enabled."
  type        = bool
  default     = null
}

variable "pricing_plan" {
  description = "Pricing plan for the instance: PER_USE or PACKAGE."
  type        = string
  default     = "PER_USE"
}

variable "retain_backups_on_delete" {
  description = "Whether automated backups are retained after the instance is deleted."
  type        = bool
  default     = null
}

variable "time_zone" {
  description = "Time zone for the instance (SQL Server only)."
  type        = string
  default     = null
}

variable "user_labels" {
  description = "Map of user labels to apply to the instance."
  type        = map(string)
  default     = {}
}

variable "database_flags" {
  description = "List of database flags to set on the instance."
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "backup_configuration" {
  description = "Backup configuration for the instance."
  type = list(object({
    enabled                        = bool
    location                       = optional(string)
    binary_log_enabled             = optional(bool)
    start_time                     = optional(string)
    point_in_time_recovery_enabled = optional(bool)
    backup_retention_settings = optional(list(object({
      retained_backups = number
      retention_unit    = string
    })), [])
  }))
  default = []
}

variable "threads_per_core" {
  description = "Threads per core for advanced machine features (set to 0 to disable SMT)."
  type        = number
  default     = null
}

variable "data_cache_enabled" {
  description = "Whether the data cache is enabled (Enterprise Plus edition)."
  type        = bool
  default     = null
}

variable "entraid_config" {
  description = "Microsoft Entra ID configuration for SQL Server instances."
  type = object({
    application_id = string
    tenant_id      = string
  })
  default = null
}

variable "insights_config" {
  description = "Query Insights configuration."
  type = object({
    enhanced_query_insights_enabled = optional(bool)
    query_insights_enabled          = optional(bool)
    query_plans_per_minute          = optional(number)
    query_string_length             = optional(number)
    record_application_tags         = optional(bool)
    record_client_address           = optional(bool)
  })
  default = null
}

variable "location_preference" {
  description = "Preferred zone/secondary zone placement for the instance."
  type = object({
    follow_gae_application = optional(string)
    secondary_zone         = optional(string)
    zone                   = optional(string)
  })
  default = null
}

variable "maintenance_window" {
  description = "Preferred maintenance window for the instance."
  type = object({
    day          = number
    hour         = number
    update_track = optional(string)
  })
  default = null
}

variable "password_validation_policy" {
  description = "Password validation policy for database users."
  type = object({
    complexity                   = optional(string)
    disallow_username_substring  = optional(bool)
    enable_password_policy       = bool
    min_length                   = optional(number)
    password_change_interval     = optional(string)
    reuse_interval                = optional(number)
  })
  default = null
}

variable "read_pool_auto_scale_config" {
  description = "Auto-scaling configuration for read pools (Enterprise Plus)."
  type = object({
    disable_scale_in           = optional(bool)
    enabled                     = optional(bool)
    max_node_count              = optional(number)
    min_node_count              = optional(number)
    scale_in_cooldown_seconds  = optional(number)
    scale_out_cooldown_seconds = optional(number)
    target_metrics = optional(list(object({
      metric       = string
      target_value = number
    })), [])
  })
  default = null
}

variable "sql_server_audit_config" {
  description = "SQL Server audit configuration."
  type = object({
    bucket             = string
    retention_interval = optional(string)
    upload_interval     = optional(string)
  })
  default = null
}

variable "active_directory_config" {
  description = "Managed Active Directory configuration (SQL Server)."
  type = object({
    admin_credential_secret_name = optional(string)
    dns_servers                   = optional(string)
    domain                         = string
    mode                           = optional(string)
    organizational_unit           = optional(string)
  })
  default = null
}

variable "connection_pool_config" {
  description = "Managed connection pooling configuration."
  type = object({
    connection_pooling_enabled = optional(bool)
    flags = optional(object({
      name  = string
      value = string
    }))
  })
  default = null
}

############################
# ip_configuration {}
############################

variable "ipv4_enabled" {
  description = "Whether the instance should be assigned a public IPv4 address."
  type        = bool
  default     = true
}

variable "allocated_ip_range" {
  description = "Name of the allocated IP range for private IP connection, in the ip_configuration block."
  type        = string
  default     = null
}

variable "custom_subject_alternative_names" {
  description = "Custom Subject Alternative Names for the server SSL certificate."
  type        = list(string)
  default     = []
}

variable "server_ca_mode" {
  description = "Server CA mode: GOOGLE_MANAGED_INTERNAL_CA or GOOGLE_MANAGED_CAS_CA."
  type        = string
  default     = null
}

variable "server_ca_pool" {
  description = "Resource name of the CA pool when server_ca_mode is GOOGLE_MANAGED_CAS_CA."
  type        = string
  default     = null
}

variable "server_certificate_rotation_mode" {
  description = "Server certificate rotation mode."
  type        = string
  default     = null
}

variable "ssl_mode" {
  description = "SSL enforcement mode for connections, e.g. ENCRYPTED_ONLY, TRUSTED_CLIENT_CERTIFICATE_REQUIRED."
  type        = string
  default     = null
}

variable "authorized_networks" {
  description = "List of authorized external networks allowed to connect via public IP."
  type = list(object({
    expiration_time = optional(string)
    name            = optional(string)
    value           = string
  }))
  default = []
}

variable "psc_config" {
  description = "Private Service Connect configuration."
  type = list(object({
    psc_auto_dns_enabled               = optional(bool)
    psc_enabled                         = optional(bool)
    psc_write_endpoint_dns_enabled     = optional(bool)
    network_attachment_uri              = optional(string)
    psc_auto_connection_policy_enabled = optional(bool)
    allowed_consumer_projects           = optional(list(string))
    psc_auto_connections = optional(list(object({
      consumer_network            = string
      consumer_service_project_id = string
    })), [])
  }))
  default = []
}

############################
# Database / user
############################

variable "db_name" {
  description = "Name of the database created inside the instance."
  type        = string
}

variable "db_user" {
  description = "Name of the database user created for the instance."
  type        = string
}

############################
# Provisioning (see note in main.tf — no matching real resource exists)
############################

# variable "sql_provision_script" {
#   description = "Script/command to run against the database after creation. Not wired to a resource by default — see the commented-out null_resource in main.tf."
#   type        = string
#   default     = null
# }