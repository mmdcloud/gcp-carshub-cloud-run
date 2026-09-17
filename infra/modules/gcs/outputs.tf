# --------------------------------------------------------------------------------------------
# Bucket
# --------------------------------------------------------------------------------------------

output "bucket_id" {
  description = "The GCS bucket's ID (in the form project-name/bucket-name)."
  value       = google_storage_bucket.bucket.id
}

output "bucket_name" {
  description = "The name of the bucket."
  value       = google_storage_bucket.bucket.name
}

output "bucket_self_link" {
  description = "The URI of the bucket."
  value       = google_storage_bucket.bucket.self_link
}

output "bucket_url" {
  description = "The base URL of the bucket, in the format gs://<bucket-name>."
  value       = google_storage_bucket.bucket.url
}

output "bucket_location" {
  description = "The location of the bucket."
  value       = google_storage_bucket.bucket.location
}

output "bucket_storage_class" {
  description = "The storage class of the bucket."
  value       = google_storage_bucket.bucket.storage_class
}

output "bucket_project_number" {
  description = "The number of the project in which the bucket resides."
  value       = google_storage_bucket.bucket.project_number
}

# --------------------------------------------------------------------------------------------
# Objects
# --------------------------------------------------------------------------------------------

output "bucket_objects" {
  description = "Map of uploaded object names to their self_link and md5hash."
  value = {
    for k, obj in google_storage_bucket_object.bucket_object : k => {
      self_link = obj.self_link
      md5hash   = obj.md5hash
    }
  }
}

# --------------------------------------------------------------------------------------------
# Notifications
# --------------------------------------------------------------------------------------------

output "notification_ids" {
  description = "IDs of the Pub/Sub notifications created on the bucket."
  value       = google_storage_notification.notification[*].id
}

# --------------------------------------------------------------------------------------------
# Anywhere Cache
# --------------------------------------------------------------------------------------------

output "anywhere_cache_id" {
  description = "ID of the Anywhere Cache instance, if created."
  value       = try(google_storage_anywhere_cache.cache[0].id, null)
}

output "anywhere_cache_state" {
  description = "State of the Anywhere Cache instance, if created."
  value       = try(google_storage_anywhere_cache.cache[0].state, null)
}

# --------------------------------------------------------------------------------------------
# HMAC keys
# --------------------------------------------------------------------------------------------

output "hmac_keys_access_ids" {
  description = "Map of service account email to the generated HMAC key access ID."
  value = {
    for sa, key in google_storage_hmac_key.hmac_keys : sa => key.access_id
  }
}

output "hmac_keys_secrets" {
  description = "Map of service account email to the generated HMAC key secret."
  value = {
    for sa, key in google_storage_hmac_key.hmac_keys : sa => key.secret
  }
  sensitive = true
}

# --------------------------------------------------------------------------------------------
# IAM
# --------------------------------------------------------------------------------------------

output "admin_iam_binding_etags" {
  description = "Etags of the objectAdmin IAM bindings, keyed by bucket name."
  value = {
    for k, binding in google_storage_bucket_iam_binding.admins : k => binding.etag
  }
}

output "creator_iam_binding_etags" {
  description = "Etags of the objectCreator IAM bindings, keyed by bucket name."
  value = {
    for k, binding in google_storage_bucket_iam_binding.creators : k => binding.etag
  }
}

output "viewer_iam_binding_etags" {
  description = "Etags of the objectViewer IAM bindings, keyed by bucket name."
  value = {
    for k, binding in google_storage_bucket_iam_binding.viewers : k => binding.etag
  }
}

output "hmac_key_admin_iam_binding_etags" {
  description = "Etags of the hmacKeyAdmin IAM bindings, keyed by bucket name."
  value = {
    for k, binding in google_storage_bucket_iam_binding.hmac_key_admins : k => binding.etag
  }
}

output "storage_admin_iam_binding_etags" {
  description = "Etags of the storage.admin IAM bindings, keyed by bucket name."
  value = {
    for k, binding in google_storage_bucket_iam_binding.storage_admins : k => binding.etag
  }
}

# --------------------------------------------------------------------------------------------
# HNS / Managed folders
# --------------------------------------------------------------------------------------------

output "hns_folder_ids" {
  description = "Map of HNS folder name to its resource ID."
  value = {
    for k, f in google_storage_folder.folders : k => f.id
  }
}

output "managed_folder_ids" {
  description = "Map of managed folder name to its resource ID."
  value = {
    for k, f in google_storage_managed_folder.managed_folders : k => f.id
  }
}