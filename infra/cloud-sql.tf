resource "google_sql_database_instance" "carshub_db_instance" {
  name                 = "carshub-db-instance"
  region               = "us-central1"
  database_version     = "MYSQL_8_0"
  root_password        = google_secret_manager_secret_version.carshub_db_secret_version_data.secret_data
  settings {
    tier = "db-f1-micro"
  }

  deletion_protection = false
  depends_on          = [google_secret_manager_secret_version.carshub_db_secret_version_data]
}

resource "google_sql_database" "carshub_db" {
  name     = "carshub"
  instance = google_sql_database_instance.carshub_db_instance.name
}
