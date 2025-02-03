resource "google_compute_global_address" "carshub_sql_private_ip_address" {
  name          = "carshub-sql-private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = var.vpc_id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = var.vpc_id
  service                 = "servicenetworking.googleapis.com"
  update_on_creation_fail = true
  deletion_policy = "ABANDON"
  reserved_peering_ranges = [google_compute_global_address.carshub_sql_private_ip_address.name]
}

resource "google_sql_database_instance" "db_instance" {
  name             = var.name
  region           = var.location
  database_version = var.db_version
  root_password    = var.password
  settings {
    tier = var.tier
    ip_configuration {
      ipv4_enabled = var.ipv4_enabled
      private_network = var.vpc_self_link
      enable_private_path_for_google_cloud_services = true
      # authorized_networks {
      #   name  = "all"
      #   value = "0.0.0.0/0"
      # }
    }
  }

  deletion_protection = false
  depends_on = [ google_service_networking_connection.private_vpc_connection ]
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
