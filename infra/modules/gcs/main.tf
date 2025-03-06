resource "google_storage_bucket" "bucket" {
  name          = var.name
  location      = var.location
  force_destroy = var.force_destroy
  versioning {
    enabled = var.versioning
  }
  uniform_bucket_level_access = var.uniform_bucket_level_access
  dynamic "cors" {
    for_each = var.cors
    content {
      max_age_seconds = cors.value["max_age_seconds"]
      method          = cors.value["method"]
      origin          = cors.value["origin"]
      response_header = cors.value["response_header"]
    }
  }
  dynamic "lifecycle_rule" {
    for_each = var.lifecycle_rules
    content {
      condition {
        age = lifecycle_rule.value["condition"]["age"]
      }
      action {
        type          = lifecycle_rule.value["action"]["type"]
        storage_class = lifecycle_rule.value["action"]["storage_class"]
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
  count          = length(var.notifications)
  bucket         = google_storage_bucket.bucket.name
  payload_format = "JSON_API_V1"
  topic          = var.notifications[count.index].topic_id
}
