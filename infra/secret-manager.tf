data "google_project" "project" {}

resource "google_secret_manager_secret" "carshub_db_password_secret" {
  secret_id = "carshub_db_password_secret"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "carshub_db_secret_version_data" {
  secret      = google_secret_manager_secret.carshub_db_password_secret.name
  secret_data = "Mohitdixit12345!"
}

resource "google_secret_manager_secret_iam_member" "carshub_secret_access" {
  secret_id  = google_secret_manager_secret.carshub_db_password_secret.id
  role       = "roles/secretmanager.secretAccessor"
  member     = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"
  depends_on = [google_secret_manager_secret.carshub_db_password_secret]
}
