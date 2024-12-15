#Cloud Deploy Delivery Pipeline
resource "google_clouddeploy_delivery_pipeline" "carshub-frontend-app" {
  name        = "carshub-frontend-app"
  location    = var.location
  description = "CarsHub frontend App Deployment Pipeline"
  serial_pipeline {
    stages {
      target_id = "staging"
      profiles  = ["staging"]
    }
    stages {
      target_id = "production"
      profiles  = ["production"]
    }
  }
}

# Cloud Deploy Target
resource "google_clouddeploy_target" "carshub_frontend_staging_deploy" {
  name        = "carshub-frontend-staging-deploy"
  location    = var.location
  description = "carshub-frontend-staging-deploy"
  run {
    location = "projects/${data.google_project.project.project_id}/locations/${var.location}"
  }
}

# Cloud Deploy Target
resource "google_clouddeploy_target" "carshub_frontend_production_deploy" {
  name        = "carshub-frontend-production-deploy"
  location    = var.location
  description = "carshub-frontend-production-deploy"
  run {
    location = "projects/${data.google_project.project.project_id}/locations/${var.location}"
  }
}


#Cloud Deploy Delivery Pipeline
# resource "google_clouddeploy_delivery_pipeline" "carshub-backend-app" {
#   name        = "carshub-backend-app"
#   location    = var.location
#   description = "CarsHub backend App Deployment Pipeline"
#   serial_pipeline {
#     stages {
#       target_id = "staging"
#       profiles  = ["staging"]
#     }
#     stages {
#       target_id = "production"
#       profiles  = ["production"]
#     }
#   }
# }

# # Cloud Deploy Target
# resource "google_clouddeploy_target" "carshub_backend_staging_deploy" {
#   name        = "carshub_backend_staging_deploy"
#   location    = var.location
#   description = "carshub_backend_staging_deploy"
#   run {
#     location = "projects/${data.google_project.project.project_id}/locations/${var.location}"
#   }
# }

# # Cloud Deploy Target
# resource "google_clouddeploy_target" "carshub_backend_production_deploy" {
#   name        = "carshub_backend_production_deploy"
#   location    = var.location
#   description = "carshub_backend_production_deploy"
#   run {
#     location = "projects/${data.google_project.project.project_id}/locations/${var.location}"
#   }
# }
