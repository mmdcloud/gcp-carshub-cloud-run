resource "google_sql_database_instance" "db_instance" {
  name             = var.name
  region           = var.location
  database_version = var.db_version
  root_password    = var.password
  settings {
    tier = var.tier
    ip_configuration {
      authorized_networks {
        name  = "all"
        value = "0.0.0.0/0"
      }
    }
  }

  deletion_protection = false
}

resource "google_sql_database" "db" {
  name     = var.db_name
  instance = google_sql_database_instance.db_instance.name
}

resource "google_sql_user" "db_user" {
  name     = var.db_user
  instance = google_sql_database_instance.db_instance.name
  password = var.password
  host     = "%"
}
