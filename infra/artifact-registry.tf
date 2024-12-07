resource "google_artifact_registry_repository" "carshub_frontend_repo" {
  location      = "us-central1"
  repository_id = "carshub-frontend"
  description   = "CarHub frontend repository"
  format        = "DOCKER"
}

resource "google_artifact_registry_repository" "carshub_backend_repo" {
  location      = "us-central1"
  repository_id = "carshub-backend"
  description   = "CarHub backend repository"
  format        = "DOCKER"
}

# Bash script to build the docker image and push it to ECR
resource "null_resource" "push_backend_artifact" {
  provisioner "local-exec" {
    command = "bash ${path.cwd}/../backend/api/artifact_push.sh ${google_sql_database_instance.carshub_db_instance.first_ip_address}"
  }
  depends_on = [google_sql_database_instance.carshub_db_instance]
}

resource "null_resource" "push_frontend_artifact" {
  provisioner "local-exec" {
    command = "bash ${path.cwd}/../frontend/artifact_push.sh ${google_cloud_run_v2_service.carshub_backend_service.uri}"
  }
  depends_on = [google_cloud_run_v2_service.carshub_backend_service]
}
