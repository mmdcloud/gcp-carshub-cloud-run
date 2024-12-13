# Cloud Build configuration
resource "google_cloudbuild_trigger" "carshub-cloudbuild-trigger" {
  name = "carshub-cloudbuild-trigger"
  github {
    owner = "mmdcloud"
    name  = "carshub-gcp-cloud-run"
    push {
      branch = "master"
    }
  }
  ignored_files   = [".gitignore"]
  service_account = "custom-ground-424107-q4@appspot.gserviceaccount.com"
  filename        = "cloudbuild.yaml"
}
