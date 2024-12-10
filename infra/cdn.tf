# Add the bucket as a CDN backend
resource "google_compute_backend_bucket" "carshub_media_cdn" {
  name        = "carshub-media-cdn"
  description = "Content delivery network for media files"
  bucket_name = google_storage_bucket.carshub_media_bucket.name
  enable_cdn  = true
}
