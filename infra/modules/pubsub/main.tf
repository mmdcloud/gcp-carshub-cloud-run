# ===============================================================================
# Pub/Sub Schema IAM
# ===============================================================================

# Authoritative per role (Bindings)
resource "google_pubsub_schema_iam_binding" "schema_binding" {
  for_each = var.enable_schema ? var.schema_iam.bindings : {}

  project = var.project_id
  schema  = google_pubsub_schema.schema[0].name
  role    = each.key
  members = each.value
}

# Non-authoritative additive (Members)
resource "google_pubsub_schema_iam_member" "schema_member" {
  for_each = var.enable_schema ? {
    for idx, item in var.schema_iam.members : "${item.role}-${item.member}" => item
  } : {}

  project = var.project_id
  schema  = google_pubsub_schema.schema[0].name
  role    = each.value.role
  member  = each.value.member
}


# ===============================================================================
# Pub/Sub Topic IAM
# ===============================================================================

# Authoritative per role (Bindings)
resource "google_pubsub_topic_iam_binding" "topic_binding" {
  for_each = var.topic_iam.bindings != null ? var.topic_iam.bindings : {}

  project = var.project_id
  topic   = google_pubsub_topic.topic.name
  role    = each.key
  members = each.value
}

# Non-authoritative additive (Members)
resource "google_pubsub_topic_iam_member" "topic_member" {
  for_each = {
    for idx, item in(var.topic_iam.members != null ? var.topic_iam.members : []) :
    "${item.role}-${item.member}" => item
  }

  project = var.project_id
  topic   = google_pubsub_topic.topic.name
  role    = each.value.role
  member  = each.value.member
}


# ===============================================================================
# Pub/Sub Subscription IAM
# ===============================================================================

# Flatten subscription IAM bindings
locals {
  subscription_iam_bindings = flatten([
    for sub_key, sub in var.subscriptions : [
      for role, members in(sub.iam.bindings != null ? sub.iam.bindings : {}) : {
        sub_key = sub_key
        sub_name = sub.subscription_name
        role    = role
        members = members
      }
    ]
  ])

  subscription_iam_members = flatten([
    for sub_key, sub in var.subscriptions : [
      for item in(sub.iam.members != null ? sub.iam.members : []) : {
        sub_key = sub_key
        sub_name = sub.subscription_name
        role    = item.role
        member  = item.member
      }
    ]
  ])
}

# Authoritative per role (Bindings)
resource "google_pubsub_subscription_iam_binding" "subscription_binding" {
  for_each = {
    for item in local.subscription_iam_bindings :
    "${item.sub_key}.${item.role}" => item
  }

  project      = var.project_id
  subscription = google_pubsub_subscription.subscription[each.value.sub_key].name
  role         = each.value.role
  members      = each.value.members
}

# Non-authoritative additive (Members)
resource "google_pubsub_subscription_iam_member" "subscription_member" {
  for_each = {
    for item in local.subscription_iam_members :
    "${item.sub_key}.${item.role}.${item.member}" => item
  }

  project      = var.project_id
  subscription = google_pubsub_subscription.subscription[each.value.sub_key].name
  role         = each.value.role
  member       = each.value.member
}

# -------------------------------------------------------------------------------
# Pub/Sub Schema (Optional)
# -------------------------------------------------------------------------------
resource "google_pubsub_schema" "schema" {
  count      = var.enable_schema ? 1 : 0
  project    = var.project_id
  name       = var.schema_name
  type       = var.schema_type
  definition = var.schema_definition
}

# -------------------------------------------------------------------------------
# Pub/Sub Topic
# -------------------------------------------------------------------------------
resource "google_pubsub_topic" "topic" {
  project      = var.project_id
  name         = var.topic_name
  kms_key_name = var.kms_key_name
  labels       = var.labels
  message_retention_duration = var.message_retention_duration

  dynamic "schema_settings" {
    for_each = var.enable_schema ? [1] : []
    content {
      schema   = google_pubsub_schema.schema[0].id
      encoding = var.schema_encoding
    }
  }

  dynamic "message_storage_policy" {
    for_each = length(var.message_storage_policy_allowed_regions) > 0 ? [1] : []
    content {
      allowed_persistence_regions = var.message_storage_policy_allowed_regions
    }
  }

  dynamic "message_transforms" {
    for_each = length(var.topic_message_transforms) > 0 ? var.topic_message_transforms : []
    content {
      disabled = message_transforms.value.disabled

      # JavaScript UDF Transform
      dynamic "javascript_udf" {
        for_each = message_transforms.value.javascript_udf != null ? [message_transforms.value.javascript_udf] : []
        content {
          function_name = javascript_udf.value.function_name
          code          = javascript_udf.value.code
        }
      }      
    }
  }

  dynamic "ingestion_data_source_settings" {
    for_each = var.ingestion_data_source_settings != null ? [var.ingestion_data_source_settings] : []
    content {

      # Platform Logs Configuration
      dynamic "platform_logs_settings" {
        for_each = ingestion_data_source_settings.value.platform_logs_settings != null ? [ingestion_data_source_settings.value.platform_logs_settings] : []
        content {
          severity = platform_logs_settings.value.severity
        }
      }

      # 1. Cloud Storage Ingestion
      dynamic "cloud_storage" {
        for_each = ingestion_data_source_settings.value.cloud_storage != null ? [ingestion_data_source_settings.value.cloud_storage] : []
        content {
          bucket                     = cloud_storage.value.bucket
          match_glob                 = cloud_storage.value.match_glob
          minimum_object_create_time = cloud_storage.value.minimum_object_create_time

          dynamic "text_format" {
            for_each = cloud_storage.value.text_format != null ? [cloud_storage.value.text_format] : []
            content {
              delimiter = text_format.value.delimiter
            }
          }

          dynamic "avro_format" {
            for_each = cloud_storage.value.avro_format != null ? [cloud_storage.value.avro_format] : []
            content {}
          }

          dynamic "pubsub_avro_format" {
            for_each = cloud_storage.value.pubsub_avro_format != null ? [cloud_storage.value.pubsub_avro_format] : []
            content {}
          }
        }
      }

      # 2. AWS Kinesis Ingestion
      dynamic "aws_kinesis" {
        for_each = ingestion_data_source_settings.value.aws_kinesis != null ? [ingestion_data_source_settings.value.aws_kinesis] : []
        content {
          stream_arn          = aws_kinesis.value.stream_arn
          consumer_arn        = aws_kinesis.value.consumer_arn
          aws_role_arn        = aws_kinesis.value.aws_role_arn
          gcp_service_account = aws_kinesis.value.gcp_service_account
        }
      }

      # 3. AWS MSK Ingestion
      dynamic "aws_msk" {
        for_each = ingestion_data_source_settings.value.aws_msk != null ? [ingestion_data_source_settings.value.aws_msk] : []
        content {
          cluster_arn         = aws_msk.value.cluster_arn
          topic               = aws_msk.value.topic
          aws_role_arn        = aws_msk.value.aws_role_arn
          gcp_service_account = aws_msk.value.gcp_service_account
        }
      }

      # 4. Azure Event Hubs Ingestion
      dynamic "azure_event_hubs" {
        for_each = ingestion_data_source_settings.value.azure_event_hubs != null ? [ingestion_data_source_settings.value.azure_event_hubs] : []
        content {
          resource_group      = azure_event_hubs.value.resource_group
          namespace           = azure_event_hubs.value.namespace
          event_hub           = azure_event_hubs.value.event_hub
          client_id           = azure_event_hubs.value.client_id
          tenant_id           = azure_event_hubs.value.tenant_id
          subscription_id     = azure_event_hubs.value.subscription_id
          gcp_service_account = azure_event_hubs.value.gcp_service_account
        }
      }

      # 5. Confluent Cloud Ingestion
      dynamic "confluent_cloud" {
        for_each = ingestion_data_source_settings.value.confluent_cloud != null ? [ingestion_data_source_settings.value.confluent_cloud] : []
        content {
          bootstrap_server    = confluent_cloud.value.bootstrap_server
          cluster_id          = confluent_cloud.value.cluster_id
          topic               = confluent_cloud.value.topic
          identity_pool_id    = confluent_cloud.value.identity_pool_id
          gcp_service_account = confluent_cloud.value.gcp_service_account
        }
      }
    }
  }
}

# -------------------------------------------------------------------------------
# Pub/Sub Subscriptions
# -------------------------------------------------------------------------------
resource "google_pubsub_subscription" "subscription" {
  for_each = var.subscriptions

  project                      = var.project_id
  name                         = each.value.subscription_name
  topic                        = google_pubsub_topic.topic.id
  labels                       = var.labels
  ack_deadline_seconds         = each.value.ack_deadline_seconds
  message_retention_duration   = each.value.message_retention_duration
  retain_acked_messages        = each.value.retain_acked_messages
  filter                       = each.value.filter
  enable_exactly_once_delivery = each.value.enable_exactly_once_delivery
  enable_message_ordering      = each.value.enable_message_ordering

  # Expiration Policy configuration
  dynamic "expiration_policy" {
    for_each = each.value.ttl != null ? [1] : []
    content {
      ttl = each.value.ttl
    }
  }

  # Dead Letter Queue configuration
  dynamic "dead_letter_policy" {
    for_each = each.value.dead_letter_topic != null ? [1] : []
    content {
      dead_letter_topic     = each.value.dead_letter_topic
      max_delivery_attempts = each.value.max_delivery_attempts
    }
  }

  # Retry Policy configuration
  dynamic "retry_policy" {
    for_each = (each.value.minimum_backoff != null || each.value.maximum_backoff != null) ? [1] : []
    content {
      minimum_backoff = each.value.minimum_backoff
      maximum_backoff = each.value.maximum_backoff
    }
  }

  # Message Transforms (JavaScript UDFs and AI Inferences)
  dynamic "message_transforms" {
    for_each = length(each.value.message_transforms) > 0 ? each.value.message_transforms : []
    content {
      disabled = message_transforms.value.disabled

      # JavaScript UDF Transform
      dynamic "javascript_udf" {
        for_each = message_transforms.value.javascript_udf != null ? [message_transforms.value.javascript_udf] : []
        content {
          function_name = javascript_udf.value.function_name
          code          = javascript_udf.value.code
        }
      }          
    }
  }


  # Push Subscription configuration
  dynamic "push_config" {
    for_each = each.value.push_config != null ? [1] : []
    content {
      push_endpoint = each.value.push_config.push_endpoint
      attributes    = each.value.push_config.attributes

      dynamic "oidc_token" {
        for_each = each.value.push_config.oidc_token != null ? [1] : []
        content {
          service_account_email = each.value.push_config.oidc_token.service_account_email
          audience              = each.value.push_config.oidc_token.audience
        }
      }
    }
  }

  # BigQuery Direct Ingestion configuration
  dynamic "bigquery_config" {
    for_each = each.value.bigquery_config != null ? [1] : []
    content {
      table                 = each.value.bigquery_config.table
      use_topic_schema      = each.value.bigquery_config.use_topic_schema
      write_metadata        = each.value.bigquery_config.write_metadata
      drop_unknown_fields   = each.value.bigquery_config.drop_unknown_fields
      service_account_email = each.value.bigquery_config.service_account_email
    }
  }

  # Cloud Storage Direct Ingestion configuration
  dynamic "cloud_storage_config" {
    for_each = each.value.cloud_storage_config != null ? [1] : []
    content {
      bucket                = each.value.cloud_storage_config.bucket
      filename_prefix       = each.value.cloud_storage_config.filename_prefix
      filename_suffix       = each.value.cloud_storage_config.filename_suffix
      max_duration          = each.value.cloud_storage_config.max_duration
      max_bytes             = each.value.cloud_storage_config.max_bytes
      service_account_email = each.value.cloud_storage_config.service_account_email
    }
  }
}