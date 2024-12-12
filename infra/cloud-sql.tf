resource "google_sql_database_instance" "carshub_db_instance" {
  name             = "carshub-db-instance"
  region           = var.location
  database_version = "MYSQL_8_0"
  root_password    = google_secret_manager_secret_version.carshub_db_secret_version_data.secret_data
  settings {

    tier = "db-f1-micro"
    ip_configuration {
      authorized_networks {
        name  = "all"
        value = "0.0.0.0/0"
      }
    }
  }

  deletion_protection = false
  depends_on          = [google_secret_manager_secret_version.carshub_db_secret_version_data]
}

resource "google_sql_database" "carshub_db" {
  name     = "carshub"
  instance = google_sql_database_instance.carshub_db_instance.name
}

resource "google_sql_user" "carshub_db_user" {
  name     = "mohit"
  instance = google_sql_database_instance.carshub_db_instance.name
  password = google_secret_manager_secret_version.carshub_db_secret_version_data.secret_data
  host     = "%"
}
