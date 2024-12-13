#Cloud Deploy Delivery Pipeline
resource "google_clouddeploy_delivery_pipeline" "carshub-app" {
  name        = "carshub-app"
  location    = var.location
  description = "CarsHub App Deployment Pipeline"
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
resource "google_clouddeploy_target" "carshub_staging_deploy" {
  name        = "carshub_staging_deploy"
  location    = var.location
  description = "carshub_staging_deploy"
  run {
    location = "projects/${data.google_project.project.project_id}/locations/${var.location}/clusters/staging"
  }
}

# Cloud Deploy Target
resource "google_clouddeploy_target" "carshub_production_deploy" {
  name        = "carshub_production_deploy"
  location    = var.location
  description = "carshub_production_deploy"
  run {
    location = "projects/${data.google_project.project.project_id}/locations/${var.location}/clusters/staging"
  }
}
