resource "google_storage_bucket_object" "bucket_object" {
  name   = var.name
  bucket = var.bucket
  source = var.source_path
}
