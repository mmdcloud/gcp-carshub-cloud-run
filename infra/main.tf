# Getting project information
data "google_project" "project" {}
data "google_storage_project_service_account" "carshub_gcs_account" {}

# Enable APIS
module "carshub_apis" {
  source = "./modules/apis"
  apis = [
    "compute.googleapis.com",
    "secretmanager.googleapis.com",
    "artifactregistry.googleapis.com",
    "run.googleapis.com",
    "cloudfunctions.googleapis.com",
    "eventarc.googleapis.com",
    "sqladmin.googleapis.com",
    "binaryauthorization.googleapis.com"
  ]
  disable_on_destroy = false
  project_id         = data.google_project.project.project_id
}

# VPC Module
module "carshub_vpc" {
  source                   = "./modules/vpc"
  auto_create_subnetworks  = false
  vpc_name                 = "carshub-vpc"
  private_ip_google_access = true
  location                 = var.location
  firewall_data            = []
  subnets = [
    {
      name          = "carshub-subnet"
      ip_cidr_range = "10.0.1.0/24"
    }
  ]
}

# Creating a Serverless VPC connector
module "carshub_connector" {
  source        = "./modules/serverless-vpc"
  name          = "carshub-connector"
  ip_cidr_range = "10.8.0.0/28"
  network_name  = module.carshub_vpc.vpc_name
  min_instances = 2
  max_instances = 5
  machine_type  = "f1-micro"
}

# Artifact Registry
module "carshub_frontend_artifact_registry" {
  source        = "./modules/artifact-registry"
  location      = var.location
  description   = "CarHub frontend repository"
  repository_id = "carshub-frontend"
  shell_command = "bash ${path.cwd}/../frontend/artifact_push.sh ${module.carshub_backend_service.service_uri} http://${module.cdn_lb.ip_address}"
  depends_on    = [module.carshub_backend_service, module.carshub_apis]
}

module "carshub_backend_artifact_registry" {
  source        = "./modules/artifact-registry"
  location      = var.location
  description   = "CarHub backend repository"
  repository_id = "carshub-backend"
  shell_command = "bash ${path.cwd}/../backend/api/artifact_push.sh"
  depends_on    = [module.carshub_db, module.carshub_apis]
}

# GCS
module "carshub_media_bucket" {
  source   = "./modules/gcs"
  location = var.location
  name     = "carshub-media"
  cors = [
    {
      origin          = [module.carshub_frontend_service.service_uri]
      max_age_seconds = 3600
      method          = ["GET", "POST", "PUT", "DELETE"]
      response_header = ["*"]
    }
  ]
  contents = [
    {
      name        = "images/"
      content     = " "
      source_path = ""
    },
    {
      name        = "documents/"
      content     = " "
      source_path = ""
    }
  ]
  force_destroy               = true
  uniform_bucket_level_access = true
}

module "carshub_media_bucket_backup" {
  source   = "./modules/gcs"
  location = var.location
  name     = "carshub-media-backup"
  cors = [
    {
      origin          = [module.carshub_frontend_service.service_uri]
      max_age_seconds = 3600
      method          = ["GET", "POST", "PUT", "DELETE"]
      response_header = ["*"]
    }
  ]
  contents = [
    {
      name        = "images/"
      content     = " "
      source_path = ""
    },
    {
      name        = "documents/"
      content     = " "
      source_path = ""
    }
  ]
  force_destroy               = true
  uniform_bucket_level_access = true
}

module "carshub_media_bucket_code" {
  source   = "./modules/gcs"
  location = var.location
  name     = "carshub-media-code"
  cors     = []
  contents = [
    {
      name        = "code.zip"
      source_path = "${path.root}/files/code.zip"
      content     = ""
    }
  ]
  force_destroy               = true
  uniform_bucket_level_access = true
}

# Cloud storage IAM binding
resource "google_storage_bucket_iam_binding" "storage_iam_binding" {
  bucket = module.carshub_media_bucket.bucket_name
  role   = "roles/storage.objectAdmin"

  members = [
    "allUsers"
  ]
}

# CDN for handling media files
module "carshub_cdn" {
  source      = "./modules/cdn"
  bucket_name = module.carshub_media_bucket.bucket_name
  enable_cdn  = true
  description = "Content delivery network for media files"
  name        = "carshub-media-cdn"
}

# Load Balancer
module "cdn_lb" {
  source                = "./modules/load-balancer"
  forwarding_port_range = "80"
  forwarding_rule_name  = "carshub-cdn-global-forwarding-rule"
  forwarding_scheme     = "EXTERNAL"
  global_address_type   = "EXTERNAL"
  url_map_name          = "carshub-cdn-compute-url-map"
  global_address_name   = "carshub-cdn-lb-global-address"
  target_proxy_name     = "carshub-cdn-target-proxy"
  url_map_service       = module.carshub_cdn.cdn_self_link
  depends_on            = [module.carshub_apis]
}

# Secret Manager
module "carshub_sql_password_secret" {
  source      = "./modules/secret-manager"
  secret_data = "Mohitdixit12345!"
  secret_id   = "carshub_db_password_secret"
  depends_on  = [module.carshub_apis]
}

# Cloud SQL
module "carshub_db" {
  source                      = "./modules/cloud-sql"
  name                        = "carshub-db-instance"
  db_name                     = "carshub"
  db_user                     = "mohit"
  db_version                  = "MYSQL_8_0"
  location                    = var.location
  tier                        = "db-f1-micro"
  ipv4_enabled                = false
  deletion_protection_enabled = false
  backup_configuration = [
    {
      enabled                        = true
      start_time                     = "03:00"
      location                       = var.location
      point_in_time_recovery_enabled = false
      backup_retention_settings = [
        {
          retained_backups = 7
          retention_unit   = "COUNT"
        }
      ]
    }
  ]
  vpc_self_link = module.carshub_vpc.self_link
  vpc_id        = module.carshub_vpc.vpc_id
  password      = module.carshub_sql_password_secret.secret_data
  depends_on    = [module.carshub_sql_password_secret]
}

# Cloud Run

# Cloud Run IAM Permissions
module "carshub_run_iam_permissions" {
  source = "./modules/cloud-run-iam"
  members = [
    module.carshub_backend_service.name,
    module.carshub_frontend_service.name
  ]
}

# Frontend Service
module "carshub_frontend_service" {
  source               = "./modules/cloud-run"
  deletion_protection  = false
  ingress              = "INGRESS_TRAFFIC_ALL"
  vpc_connector_name   = module.carshub_connector.connector_id
  volume_mounts        = []
  service_account      = module.carshub_cloud_run_service_account.sa_email
  location             = var.location
  image                = "${var.location}-docker.pkg.dev/${data.google_project.project.project_id}/carshub-frontend/carshub-frontend:latest"
  max_instance_count   = 2
  name                 = "carshub-frontend-service"
  traffic_type         = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
  volumes              = []
  traffic_type_percent = 100
  env                  = []
  depends_on           = [module.carshub_frontend_artifact_registry, module.carshub_apis, module.carshub_cloud_run_service_account]
}

# Backend Service
module "carshub_backend_service" {
  source              = "./modules/cloud-run"
  deletion_protection = false
  vpc_connector_name  = module.carshub_connector.connector_id
  ingress             = "INGRESS_TRAFFIC_ALL"
  service_account     = module.carshub_cloud_run_service_account.sa_email
  location            = var.location
  max_instance_count  = 2
  volumes = [
    {
      name               = "cloudsql"
      cloud_sql_instance = [module.carshub_db.db_connection_name]
    }
  ]
  image                = "${var.location}-docker.pkg.dev/${data.google_project.project.project_id}/carshub-backend/carshub-backend:latest"
  name                 = "carshub-backend-service"
  traffic_type         = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
  traffic_type_percent = 100
  volume_mounts = [
    {
      name       = "cloudsql"
      mount_path = "/cloudsql"
    }
  ]
  env = [
    {
      name         = "DB_PATH"
      value        = "${module.carshub_db.db_ip_address}"
      value_source = []
    },
    {
      name         = "UN"
      value        = "mohit"
      value_source = []
    },
    {
      name  = "CREDS"
      value = ""
      value_source = [
        {
          secret_key_ref = [
            {
              secret  = module.carshub_sql_password_secret.secret_id
              version = "1"
            }
          ]
        }
      ]
    }
  ]
  depends_on = [module.carshub_apis, module.carshub_sql_password_secret, module.carshub_backend_artifact_registry, module.carshub_connector, module.carshub_cloud_run_service_account]
}

# Service Account
module "carshub_service_account" {
  source       = "./modules/service-account"
  account_id   = "carshub-service-account"
  display_name = "CarsHub Service Account"
  project_id   = data.google_project.project.project_id
  permissions = [
    "roles/run.invoker",
    "roles/eventarc.eventReceiver",
    "roles/cloudsql.client",
    "roles/artifactregistry.reader"
  ]
}

module "carshub_cloud_run_service_account" {
  source       = "./modules/service-account"
  account_id   = "carshub-cloud-run-sa"
  display_name = "CarsHub Cloud Run Service Account"
  project_id   = data.google_project.project.project_id
  permissions = [
    "roles/secretmanager.secretAccessor",
    "roles/storage.admin",
    "roles/iam.serviceAccountTokenCreator"
  ]
}

# Service Account Permissions
module "carshub_gcs_account_pubsub_publishing" {
  source  = "./modules/service-account-iam"
  project = data.google_project.project.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${data.google_storage_project_service_account.carshub_gcs_account.email_address}"
}

# Cloud Run Function
module "carshub_media_update_function" {
  source               = "./modules/cloud-run-function"
  function_name        = "carshub-media-function"
  function_description = "A function to update media details in SQL database after the upload trigger"
  handler              = "handler"
  runtime              = "python312"
  location             = var.location
  storage_source = [
    {
      bucket = module.carshub_media_bucket_code.bucket_name
      object = module.carshub_media_bucket_code.object_name[0].name
    }
  ]
  build_env_variables = {
    INSTANCE_CONNECTION_NAME = "${data.google_project.project.project_id}:${var.location}:${module.carshub_db.db_name}"
    DB_USER                  = module.carshub_db.db_user
    DB_NAME                  = module.carshub_db.db_name
    DB_PASSWORD              = module.carshub_sql_password_secret.secret_data
    DB_PATH                  = module.carshub_db.db_ip_address
  }
  all_traffic_on_latest_revision = true
  vpc_connector                  = module.carshub_connector.connector_id
  vpc_connector_egress_settings  = "ALL_TRAFFIC"
  ingress_settings               = "ALLOW_INTERNAL_ONLY"
  sa                             = module.carshub_service_account.sa_email
  max_instance_count             = 3
  min_instance_count             = 1
  available_memory               = "256M"
  timeout_seconds                = 60
  event_triggers = [
    {
      event_type            = "google.cloud.storage.object.v1.finalized"
      retry_policy          = "RETRY_POLICY_RETRY"
      service_account_email = module.carshub_service_account.sa_email
      event_filters = [
        {
          attribute = "bucket"
          value     = module.carshub_media_bucket.bucket_name
        }
      ]
    }
  ]
  depends_on = [module.carshub_service_account]
}
