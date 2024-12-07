resource "google_cloud_run_v2_service" "carshub_backend_service" {
  name                = "carshub-backend-service"
  location            = "us-central1"
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
      image = "us-central1-docker.pkg.dev/our-mediator-443812-i8/carshub-backend/carshub-backend:latest"
      ports {
        container_port = 3000
        # name           = "carshub-backend"
      }
      env {
        name  = "USERNAME"
        value = "root"
      }
      env {
        name = "PASSWORD"
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

resource "google_cloud_run_v2_service" "carshub_frontend_service" {
  name                = "carshub-frontend-service"
  location            = "us-central1"
  deletion_protection = false
  ingress             = "INGRESS_TRAFFIC_ALL"

  template {
    scaling {
      max_instance_count = 2
    }

    containers {
      image = "us-central1-docker.pkg.dev/our-mediator-443812-i8/carshub-backend/carshub-backend:latest"
      ports {
        container_port = 3000
        # name           = "carshub-frontend"
      }
    }
  }

  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }

  depends_on = [null_resource.push_frontend_artifact]
}
