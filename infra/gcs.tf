resource "google_storage_bucket" "carshub_media_bucket" {
  name                        = "carshub-media"
  location                    = var.location
  force_destroy               = true
  uniform_bucket_level_access = true
}

resource "google_storage_bucket" "carshub_media_code_bucket" {
  name                        = "carshub-media-code"
  location                    = var.location
  uniform_bucket_level_access = true
  force_destroy               = true
}

resource "google_storage_bucket_object" "carshub_media_code_object" {
  name   = "code.zip"
  bucket = google_storage_bucket.carshub_media_code_bucket.name
  source = "./files/code.zip"
}