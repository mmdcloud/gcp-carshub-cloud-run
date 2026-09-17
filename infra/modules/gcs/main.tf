locals {
  # Single-bucket module: wrap the bucket name in a one-element set so the
  # IAM `for_each` blocks below have a stable, unique key to iterate over.
  # (Kept as a set/map pattern rather than a bare bool so this can be
  # extended to multiple bucket names later without reshaping the IAM blocks.)
  names_set = toset([var.name])
}

resource "google_storage_bucket" "bucket" {
  name                         = var.name
  location                     = var.location
  force_destroy                = var.force_destroy
  storage_class                = var.storage_class
  uniform_bucket_level_access  = var.uniform_bucket_level_access
  default_event_based_hold     = var.default_event_based_hold
  rpo                          = var.rpo
  enable_object_retention      = var.enable_object_retention
  requester_pays                = var.requester_pays
  public_access_prevention     = var.public_access_prevention

  dynamic "custom_placement_config" {
    # FIX: was `each.value` (undefined here); this resource has no for_each,
    # so key the lookup off var.name directly.
    for_each = lookup(var.custom_placement_config, var.name, null) != null ? [var.custom_placement_config[var.name]] : []
    content {
      data_locations = lookup(custom_placement_config.value, "data_locations", null)
    }
  }

  dynamic "soft_delete_policy" {
    # FIX: same `each.value` issue.
    for_each = [lookup(var.soft_delete_policy, var.name, {
      retention_duration_seconds = null
    })]
    content {
      retention_duration_seconds = lookup(soft_delete_policy.value, "retention_duration_seconds", null)
    }
  }

  dynamic "retention_policy" {
    for_each = var.retention_policy != null ? [var.retention_policy] : []
    content {
      is_locked        = retention_policy.value.is_locked
      retention_period = retention_policy.value.retention_period
    }
  }

  dynamic "logging" {
    for_each = var.logging != null ? [var.logging] : []
    content {
      log_bucket        = logging.value.log_bucket
      log_object_prefix = logging.value.log_object_prefix
    }
  }

  dynamic "ip_filter" {
    for_each = var.ip_filter != null ? [var.ip_filter] : []
    content {
      allow_all_service_agent_access = ip_filter.value.allow_all_service_agent_access
      allow_cross_org_vpcs           = ip_filter.value.allow_cross_org_vpcs
      mode                           = ip_filter.value.mode

      dynamic "public_network_source" {
        for_each = ip_filter.value.public_network_source != null ? [ip_filter.value.public_network_source] : []
        content {
          allowed_ip_cidr_ranges = public_network_source.value.allowed_ip_cidr_ranges
        }
      }

      dynamic "vpc_network_sources" {
        for_each = ip_filter.value.vpc_network_sources != null ? [ip_filter.value.vpc_network_sources] : []
        content {
          allowed_ip_cidr_ranges = vpc_network_sources.value.allowed_ip_cidr_ranges
          network                = vpc_network_sources.value.network
        }
      }
    }
  }

  versioning {
    enabled = var.versioning
  }

  dynamic "cors" {
    for_each = var.cors
    content {
      max_age_seconds = cors.value.max_age_seconds
      method          = cors.value.method
      origin          = cors.value.origin
      response_header = cors.value.response_header
    }
  }

  dynamic "autoclass" {
    for_each = var.autoclass != null ? [var.autoclass] : []
    content {
      enabled                 = autoclass.value.enabled
      terminal_storage_class  = autoclass.value.terminal_storage_class
    }
  }

  dynamic "encryption" {
    # FIX: was `each.value` (undefined here); key off var.name directly.
    # If an encryption key name is set for this bucket name -> create a single encryption block.
    for_each = trimspace(lookup(var.encryption_key_names, lower(var.name), "")) != "" ? [true] : []
    content {
      default_kms_key_name = trimspace(
        lookup(
          var.encryption_key_names,
          lower(var.name),
          "Error retrieving kms key name", # Should be unreachable due to the for_each check
        )
      )
    }
  }

  hierarchical_namespace {
    enabled = var.enable_hierarchical_namespace
  }

  dynamic "website" {
    for_each = (var.website.main_page_suffix == null && var.website.not_found_page == null) ? toset([]) : toset([var.website])
    content {
      main_page_suffix = lookup(website.value, "main_page_suffix", null)
      not_found_page   = lookup(website.value, "not_found_page", null)
    }
  }

  dynamic "lifecycle_rule" {
    for_each = var.lifecycle_rules
    content {

      condition {
        # FIX: these were missing `.value.condition.` and referenced the
        # dynamic block itself instead of its current element.
        age                                      = lifecycle_rule.value.condition.age
        created_before                            = lifecycle_rule.value.condition.created_before
        custom_time_before                        = lifecycle_rule.value.condition.custom_time_before
        days_since_custom_time                    = lifecycle_rule.value.condition.days_since_custom_time
        days_since_noncurrent_time                = lifecycle_rule.value.condition.days_since_noncurrent_time
        matches_prefix                            = lifecycle_rule.value.condition.matches_prefix
        matches_storage_class                     = lifecycle_rule.value.condition.matches_storage_class
        matches_suffix                            = lifecycle_rule.value.condition.matches_suffix
        noncurrent_time_before                    = lifecycle_rule.value.condition.noncurrent_time_before
        num_newer_versions                        = lifecycle_rule.value.condition.num_newer_versions
        send_age_if_zero                          = lifecycle_rule.value.condition.send_age_if_zero
        send_days_since_custom_time_if_zero       = lifecycle_rule.value.condition.send_days_since_custom_time_if_zero
        send_days_since_noncurrent_time_if_zero   = lifecycle_rule.value.condition.send_days_since_noncurrent_time_if_zero
        send_num_newer_versions_if_zero           = lifecycle_rule.value.condition.send_num_newer_versions_if_zero
        with_state                                = lifecycle_rule.value.condition.with_state
      }

      action {
        type          = lifecycle_rule.value.action.type
        storage_class = lifecycle_rule.value.action.storage_class
      }
    }
  }
}

resource "google_storage_bucket_object" "bucket_object" {
  for_each = { for idx, obj in var.contents : obj.name => obj }
  name     = each.value.name
  bucket   = google_storage_bucket.bucket.name
  source   = each.value.source_path != "" ? each.value.source_path : null
  content  = each.value.content != "" ? each.value.content : null
  lifecycle {
    ignore_changes = [content, source]
  }
}

resource "google_storage_notification" "notification" {
  count              = length(var.notifications)
  bucket             = google_storage_bucket.bucket.name
  event_types        = var.notifications[count.index].event_types
  payload_format     = var.notifications[count.index].payload_format
  topic              = var.notifications[count.index].topic_id
  object_name_prefix = var.notifications[count.index].object_name_prefix
  custom_attributes  = var.notifications[count.index].custom_attributes
}

# --------------------------------------------------------------------------------------------
# Storage Anywhere Cache
# --------------------------------------------------------------------------------------------
resource "time_sleep" "destroy_wait_50_seconds" {
  depends_on        = [google_storage_bucket.bucket]
  destroy_duration  = "50s"
}

resource "google_storage_anywhere_cache" "cache" {
  # FIX: var.enable_storage_anywhere_cache is an object (it's accessed as
  # .zone/.ttl/.ingest_on_write below), so `== true` never matches. Gate on
  # non-null instead.
  count           = var.enable_storage_anywhere_cache != null ? 1 : 0
  bucket          = google_storage_bucket.bucket.name
  zone            = var.enable_storage_anywhere_cache.zone
  ttl             = var.enable_storage_anywhere_cache.ttl
  ingest_on_write = var.enable_storage_anywhere_cache.ingest_on_write
  depends_on      = [time_sleep.destroy_wait_50_seconds]
}

# --------------------------------------------------------------------------------------------
# HMAC Keys
# --------------------------------------------------------------------------------------------
resource "google_storage_hmac_key" "hmac_keys" {
  project               = var.project_id
  for_each              = var.set_hmac_access ? var.hmac_service_accounts : {}
  service_account_email = each.key
  state                 = each.value
}

# --------------------------------------------------------------------------------------------
# Bucket IAM
# --------------------------------------------------------------------------------------------
# FIX: `google_storage_bucket.buckets[each.value]` -> `google_storage_bucket.bucket`.
# This module only creates a single bucket (`google_storage_bucket.bucket`,
# no for_each), so there is no `buckets` map/resource to index into.
# `local.names_set` (defined in locals.tf) still drives the for_each here so
# the IAM member-merging logic (admins + bucket_admins lookup) is unchanged.
resource "google_storage_bucket_iam_binding" "admins" {
  for_each = var.set_admin_roles ? local.names_set : []
  bucket   = google_storage_bucket.bucket.name
  role     = "roles/storage.objectAdmin"
  members = compact(
    concat(
      var.admins,
      split(
        ",",
        lookup(var.bucket_admins, each.value, ""),
      ),
    ),
  )
}

resource "google_storage_bucket_iam_binding" "creators" {
  for_each = var.set_creator_roles ? local.names_set : toset([])
  bucket   = google_storage_bucket.bucket.name
  role     = "roles/storage.objectCreator"
  members = compact(
    concat(
      var.creators,
      split(
        ",",
        lookup(var.bucket_creators, each.value, ""),
      ),
    ),
  )
}

resource "google_storage_bucket_iam_binding" "viewers" {
  for_each = var.set_viewer_roles ? local.names_set : toset([])
  bucket   = google_storage_bucket.bucket.name
  role     = "roles/storage.objectViewer"
  members = compact(
    concat(
      var.viewers,
      split(
        ",",
        lookup(var.bucket_viewers, each.value, ""),
      ),
    ),
  )
}

resource "google_storage_bucket_iam_binding" "hmac_key_admins" {
  for_each = var.set_hmac_key_admin_roles ? local.names_set : toset([])
  bucket   = google_storage_bucket.bucket.name
  role     = "roles/storage.hmacKeyAdmin"
  members = compact(
    concat(
      var.hmac_key_admins,
      split(
        ",",
        lookup(var.bucket_hmac_key_admins, each.key, ""),
      ),
    ),
  )
}

resource "google_storage_bucket_iam_binding" "storage_admins" {
  for_each = var.set_storage_admin_roles ? local.names_set : toset([])
  bucket   = google_storage_bucket.bucket.name
  role     = "roles/storage.admin"
  members = compact(
    concat(
      var.storage_admins,
      split(
        ",",
        lookup(var.bucket_storage_admins, each.value, ""),
      ),
    ),
  )
}

# --------------------------------------------------------------------------------------------
# HNS folders
# --------------------------------------------------------------------------------------------
# FIX: `for_each` was set to a *list* (var.hns_folders) while the block body
# used `count.index`, which doesn't exist under for_each. Convert the list to
# a map keyed by folder name so each.value is the folder object.
# Only create root-level folders.
resource "google_storage_folder" "folders" {
  for_each      = { for f in var.hns_folders : f.name => f }
  bucket        = google_storage_bucket.bucket.name
  name          = each.value.name
  force_destroy = each.value.force_destroy
}

# --------------------------------------------------------------------------------------------
# Managed folders
# --------------------------------------------------------------------------------------------
# FIX: same list-vs-for_each/count.index issue as above.
# Only create root-level folders.
resource "google_storage_managed_folder" "managed_folders" {
  for_each      = { for f in var.managed_folders : f.name => f }
  bucket        = google_storage_bucket.bucket.name
  name          = each.value.name
  force_destroy = each.value.force_destroy
}