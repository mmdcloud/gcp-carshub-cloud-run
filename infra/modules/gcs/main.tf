resource "google_storage_bucket" "bucket" {
  name                        = var.name
  location                    = var.location
  force_destroy               = var.force_destroy
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
}
