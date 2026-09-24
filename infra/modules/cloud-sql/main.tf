resource "google_compute_global_address" "sql_private_ip_address" {
  name          = "sql-private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = var.vpc_id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = var.vpc_id
  service                 = "servicenetworking.googleapis.com"
  update_on_creation_fail = true
  deletion_policy         = "ABANDON"
  reserved_peering_ranges = [google_compute_global_address.sql_private_ip_address.name]
}

resource "google_sql_database_instance" "db_instance" {
  name                                             = var.name
  region                                           = var.location
  database_version                                 = var.db_version
  root_password                                    = var.password
  encryption_key_name                              = var.encryption_key_name
  enforce_new_sql_network_architecture             = var.enforce_new_sql_network_architecture
  final_backup_description                         = var.final_backup_description
  include_replicas_for_major_version_upgrade       = var.include_replicas_for_major_version_upgrade
  maintenance_version                              = var.maintenance_version
  master_instance_name                             = var.master_instance_name
  node_count                                       = var.node_count
  instance_type                                    = var.instance_type
  replica_names                                    = var.replica_names
  backupdr_backup                                  = var.backupdr_backup
  root_password_wo                                 = var.root_password_wo
  root_password_wo_version                         = var.root_password_wo_version
  switch_transaction_logs_to_cloud_storage_enabled = var.switch_transaction_logs_to_cloud_storage_enabled

  dynamic "replication_cluster" {
    for_each = var.replication_cluster != null ? [var.replication_cluster] : []
    content {
      failover_dr_replica_name = replication_cluster.value.failover_dr_replica_name
      psa_write_endpoint       = replication_cluster.value.psa_write_endpoint
    }
  }

  dynamic "restore_backup_context" {
    for_each = var.restore_backup_context != null ? [var.restore_backup_context] : []
    content {
      backup_run_id = restore_backup_context.value.backup_run_id
      instance_id   = restore_backup_context.value.instance_id
      project       = restore_backup_context.value.project
    }
  }

  dynamic "replica_configuration" {
    for_each = var.replica_configuration != null ? [var.replica_configuration] : []
    content {
      ca_certificate            = replica_configuration.value.ca_certificate
      cascadable_replica        = replica_configuration.value.cascadable_replica
      client_certificate        = replica_configuration.value.client_certificate
      client_key                = replica_configuration.value.client_key
      connect_retry_interval    = replica_configuration.value.connect_retry_interval
      dump_file_path            = replica_configuration.value.dump_file_path
      failover_target           = replica_configuration.value.failover_target
      master_heartbeat_period   = replica_configuration.value.master_heartbeat_period
      password                  = replica_configuration.value.password
      ssl_cipher                = replica_configuration.value.ssl_cipher
      username                  = replica_configuration.value.username
      verify_server_certificate = replica_configuration.value.verify_server_certificate
    }
  }

  dynamic "point_in_time_restore_context" {
    for_each = var.point_in_time_restore_context != null ? [var.point_in_time_restore_context] : []
    content {
      allocated_ip_range = point_in_time_restore_context.value.allocated_ip_range
      datasource         = point_in_time_restore_context.value.datasource
      point_in_time      = point_in_time_restore_context.value.point_in_time
      preferred_zone     = point_in_time_restore_context.value.preferred_zone
      region             = point_in_time_restore_context.value.region
      target_instance    = point_in_time_restore_context.value.target_instance
    }
  }

  dynamic "clone" {
    for_each = var.clone != null ? [var.clone] : []
    content {
      allocated_ip_range            = clone.value.allocated_ip_range
      database_names                = clone.value.database_names
      point_in_time                 = clone.value.point_in_time
      preferred_zone                = clone.value.preferred_zone
      source_instance_deletion_time = clone.value.source_instance_deletion_time
      source_instance_name          = clone.value.source_instance_name
      source_project                = clone.value.source_project
    }
  }

  settings {
    tier                             = var.tier
    availability_type                = var.availability_type
    disk_size                        = var.disk_size
    disk_type                        = var.disk_type
    disk_autoresize                  = var.disk_autoresize
    disk_autoresize_limit            = var.disk_autoresize_limit
    deletion_protection_enabled      = var.deletion_protection_enabled
    activation_policy                = var.activation_policy
    auto_upgrade_enabled             = var.auto_upgrade_enabled
    collation                        = var.collation
    connector_enforcement            = var.connector_enforcement
    data_api_access                  = var.data_api_access
    data_disk_provisioned_iops       = var.data_disk_provisioned_iops
    data_disk_provisioned_throughput = var.data_disk_provisioned_throughput
    edition                          = var.edition
    enable_dataplex_integration      = var.enable_dataplex_integration
    enable_google_ml_integration     = var.enable_google_ml_integration
    pricing_plan                     = var.pricing_plan
    retain_backups_on_delete         = var.retain_backups_on_delete
    time_zone                        = var.time_zone
    user_labels                      = var.user_labels

    dynamic "database_flags" {
      for_each = var.database_flags
      content {
        name  = database_flags.value["name"]
        value = database_flags.value["value"]
      }
    }

    dynamic "backup_configuration" {
      for_each = var.backup_configuration
      content {
        enabled                        = backup_configuration.value["enabled"]
        location                       = backup_configuration.value["location"]
        binary_log_enabled             = backup_configuration.value["binary_log_enabled"]
        start_time                     = backup_configuration.value["start_time"]
        point_in_time_recovery_enabled = backup_configuration.value["point_in_time_recovery_enabled"]
        dynamic "backup_retention_settings" {
          for_each = backup_configuration.value["backup_retention_settings"]
          content {
            retained_backups = backup_retention_settings.value["retained_backups"]
            retention_unit   = backup_retention_settings.value["retention_unit"]
          }
        }
      }
    }

    dynamic "advanced_machine_features" {
      for_each = var.threads_per_core != null ? [1] : []
      content {
        threads_per_core = var.threads_per_core
      }
    }

    dynamic "data_cache_config" {
      for_each = var.data_cache_enabled != null ? [1] : []
      content {
        data_cache_enabled = var.data_cache_enabled
      }
    }

    dynamic "entraid_config" {
      for_each = var.entraid_config != null ? [var.entraid_config] : []
      content {
        application_id = entraid_config.value.application_id
        tenant_id      = entraid_config.value.tenant_id
      }
    }

    dynamic "insights_config" {
      for_each = var.insights_config != null ? [var.insights_config] : []
      content {
        enhanced_query_insights_enabled = insights_config.value.enhanced_query_insights_enabled
        query_insights_enabled          = insights_config.value.query_insights_enabled
        query_plans_per_minute          = insights_config.value.query_plans_per_minute
        query_string_length             = insights_config.value.query_string_length
        record_application_tags         = insights_config.value.record_application_tags
        record_client_address           = insights_config.value.record_client_address
      }
    }

    dynamic "location_preference" {
      for_each = var.location_preference != null ? [var.location_preference] : []
      content {
        follow_gae_application = location_preference.value.follow_gae_application
        secondary_zone         = location_preference.value.secondary_zone
        zone                   = location_preference.value.zone
      }
    }

    dynamic "maintenance_window" {
      for_each = var.maintenance_window != null ? [var.maintenance_window] : []
      content {
        day          = maintenance_window.value.day
        hour         = maintenance_window.value.hour
        update_track = maintenance_window.value.update_track
      }
    }

    dynamic "password_validation_policy" {
      for_each = var.password_validation_policy != null ? [var.password_validation_policy] : []
      content {
        complexity                  = password_validation_policy.value.complexity
        disallow_username_substring = password_validation_policy.value.disallow_username_substring
        enable_password_policy      = password_validation_policy.value.enable_password_policy
        min_length                  = password_validation_policy.value.min_length
        password_change_interval    = password_validation_policy.value.password_change_interval
        reuse_interval              = password_validation_policy.value.reuse_interval
      }
    }

    dynamic "read_pool_auto_scale_config" {
      for_each = var.read_pool_auto_scale_config != null ? [var.read_pool_auto_scale_config] : []
      content {
        disable_scale_in           = read_pool_auto_scale_config.value.disable_scale_in
        enabled                    = read_pool_auto_scale_config.value.enabled
        max_node_count             = read_pool_auto_scale_config.value.max_node_count
        min_node_count             = read_pool_auto_scale_config.value.min_node_count
        scale_in_cooldown_seconds  = read_pool_auto_scale_config.value.scale_in_cooldown_seconds
        scale_out_cooldown_seconds = read_pool_auto_scale_config.value.scale_out_cooldown_seconds

        dynamic "target_metrics" {
          for_each = read_pool_auto_scale_config.value.target_metrics
          content {
            metric       = target_metrics.value.metric
            target_value = target_metrics.value.target_value
          }
        }
      }
    }

    dynamic "sql_server_audit_config" {
      for_each = var.sql_server_audit_config != null ? [var.sql_server_audit_config] : []
      content {
        bucket             = sql_server_audit_config.value.bucket
        retention_interval = sql_server_audit_config.value.retention_interval
        upload_interval    = sql_server_audit_config.value.upload_interval
      }
    }

    dynamic "active_directory_config" {
      for_each = var.active_directory_config != null ? [var.active_directory_config] : []
      content {
        admin_credential_secret_name = active_directory_config.value.admin_credential_secret_name
        dns_servers                  = active_directory_config.value.dns_servers
        domain                       = active_directory_config.value.domain
        mode                         = active_directory_config.value.mode
        organizational_unit          = active_directory_config.value.organizational_unit
      }
    }

    dynamic "connection_pool_config" {
      for_each = var.connection_pool_config != null ? [var.connection_pool_config] : []
      content {
        connection_pooling_enabled = connection_pool_config.value.connection_pooling_enabled

        dynamic "flags" {
          for_each = connection_pool_config.value.flags != null ? [connection_pool_config.value.flags] : []
          content {
            name  = flags.value.name
            value = flags.value.value
          }
        }
      }
    }

    ip_configuration {
      ipv4_enabled                                  = var.ipv4_enabled
      private_network                               = var.vpc_self_link
      allocated_ip_range                            = var.allocated_ip_range
      custom_subject_alternative_names              = var.custom_subject_alternative_names
      enable_private_path_for_google_cloud_services = true
      server_ca_mode                                = var.server_ca_mode
      server_ca_pool                                = var.server_ca_pool
      server_certificate_rotation_mode              = var.server_certificate_rotation_mode
      ssl_mode                                      = var.ssl_mode

      dynamic "authorized_networks" {
        for_each = var.authorized_networks
        content {
          expiration_time = authorized_networks.value.expiration_time
          name            = authorized_networks.value.name
          value           = authorized_networks.value.value
        }
      }

      dynamic "psc_config" {
        for_each = var.psc_config
        content {
          psc_auto_dns_enabled               = psc_config.value.psc_auto_dns_enabled
          psc_enabled                        = psc_config.value.psc_enabled
          psc_write_endpoint_dns_enabled     = psc_config.value.psc_write_endpoint_dns_enabled
          network_attachment_uri             = psc_config.value.network_attachment_uri
          psc_auto_connection_policy_enabled = psc_config.value.psc_auto_connection_policy_enabled
          allowed_consumer_projects          = psc_config.value.allowed_consumer_projects

          dynamic "psc_auto_connections" {
            for_each = psc_config.value.psc_auto_connections
            content {
              consumer_network            = psc_auto_connections.value.consumer_network
              consumer_service_project_id = psc_auto_connections.value.consumer_service_project_id
            }
          }
        }
      }
    }
  }
  deletion_protection = var.deletion_protection
  depends_on          = [google_service_networking_connection.private_vpc_connection]
}


resource "google_sql_database" "db" {
  name     = var.db_name
  instance = google_sql_database_instance.db_instance.name
}

resource "google_sql_user" "db_user" {
  name     = var.db_user
  instance = google_sql_database_instance.db_instance.name
  password = var.password
  host     = "%"
}

# resource "google_sql_provision_script" "script" {
#   script      = var.sql_provision_script
#   instance    = google_sql_database_instance.db_instance.name
#   database    = google_sql_database.db.name
#   description = "SQL provisioning script"
# }