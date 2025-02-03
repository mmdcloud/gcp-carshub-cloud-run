resource "google_storage_bucket_object" "bucket_object" {
  name   = var.name
  bucket = var.bucket
  source = var.source_path != "" ? var.source_path : null
  content = var.content != "" ? var.content : null
  lifecycle {
    ignore_changes = [ content,source ]
  }
}