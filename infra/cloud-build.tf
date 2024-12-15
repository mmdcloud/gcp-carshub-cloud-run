# Cloud Build configuration
resource "google_cloudbuild_trigger" "carshub-frontend-cloudbuild-trigger" {
  name = "carshub-frontend-cloudbuild-trigger"
  github {
    owner = "mmdcloud"
    name  = "carshub-gcp-cloud-run"
    push {
      branch = "master"
    }
  }
  ignored_files   = [".gitignore"]
  service_account = "projects/our-mediator-443812-i8/serviceAccounts/carshub-service-account@our-mediator-443812-i8.iam.gserviceaccount.com"
  filename        = "frontend/cloudbuild.yaml"
}

# # Cloud Build backend configuration
# resource "google_cloudbuild_trigger" "carshub-backend-cloudbuild-trigger" {
#   name = "carshub-backend-cloudbuild-trigger"
#   github {
#     owner = "mmdcloud"
#     name  = "carshub-gcp-cloud-run"
#     push {
#       branch = "master"
#     }
#   }
#   ignored_files   = [".gitignore"]
#   service_account = "projects/our-mediator-443812-i8/serviceAccounts/140735220076-compute@developer.gserviceaccount.com"
#   filename        = "backend/api/cloudbuild.yaml"
# }