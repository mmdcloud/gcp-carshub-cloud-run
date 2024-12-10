locals {
  port = 3000
}

resource "google_cloud_run_v2_service" "carshub_backend_service" {
  name                = "carshub-backend-service"
  location            = var.location
  deletion_protection = false
  ingress             = "INGRESS_TRAFFIC_ALL"

  template {
    scaling {
      max_instance_count = 2
    }

    volumes {
      name = "cloudsql"
      cloud_sql_instance {
        instances = [google_sql_database_instance.carshub_db_instance.connection_name]
      }
    }

    containers {
      image = "${var.location}-docker.pkg.dev/${data.google_project.project.project_id}/carshub-backend/carshub-backend:latest"
      ports {
        container_port = local.port
        # name           = "carshub-backend"
      }
      env {
        name  = "DB_PATH"
        value = google_sql_database_instance.carshub_db_instance.first_ip_address
      }
      env {
        name  = "UN"
        value = "mohit"
      }
      env {
        name = "CREDS"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.carshub_db_password_secret.secret_id
            version = "1"
          }
        }
      }
      volume_mounts {
        name       = "cloudsql"
        mount_path = "/cloudsql"
      }
    }
  }

  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }
  depends_on = [google_secret_manager_secret_version.carshub_db_secret_version_data, null_resource.push_backend_artifact]
}

data "google_iam_policy" "carshub_backend_run_policy" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}

resource "google_cloud_run_v2_service_iam_policy" "carshub_backend_run_iam_policy" {
  name        = google_cloud_run_v2_service.carshub_backend_service.name
  policy_data = data.google_iam_policy.carshub_backend_run_policy.policy_data
}

resource "google_cloud_run_v2_service" "carshub_frontend_service" {
  name                = "carshub-frontend-service"
  location            = var.location
  deletion_protection = false
  ingress             = "INGRESS_TRAFFIC_ALL"

  template {
    scaling {
      max_instance_count = 2
    }

    containers {
      image = "${var.location}-docker.pkg.dev/${data.google_project.project.project_id}/carshub-frontend/carshub-frontend:latest"
      ports {
        container_port = local.port
        # name           = "carshub-frontend"
      }
      env {
        name  = "BASE_URL"
        value = google_cloud_run_v2_service.carshub_backend_service.uri
      }
    }

  }

  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }

  depends_on = [null_resource.push_frontend_artifact]
}

data "google_iam_policy" "carshub_frontend_run_policy" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}

resource "google_cloud_run_v2_service_iam_policy" "carshub_frontend_run_iam_policy" {
  name        = google_cloud_run_v2_service.carshub_frontend_service.name
  policy_data = data.google_iam_policy.carshub_frontend_run_policy.policy_data
}
