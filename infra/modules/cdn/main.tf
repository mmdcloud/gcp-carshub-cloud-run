# Add the bucket as a CDN backend
resource "google_compute_backend_bucket" "cdn" {
  name        = var.name
  description = var.description
  bucket_name = var.bucket_name
  enable_cdn  = var.enable_cdn
}
