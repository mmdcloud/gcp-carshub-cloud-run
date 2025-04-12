# Registering vault provider
data "vault_generic_secret" "sql" {
  path = "secret/sql"
}

# Getting project information
data "google_project" "project" {}
data "google_storage_transfer_project_service_account" "default" {}
data "google_storage_project_service_account" "carshub_gcs_account" {}

# Enable APIS
module "carshub_apis" {
  source = "../../modules/apis"
  apis = [
    "servicenetworking.googleapis.com",
    "vpcaccess.googleapis.com",
    "compute.googleapis.com",
    "secretmanager.googleapis.com",
    "artifactregistry.googleapis.com",
    "run.googleapis.com",
    "cloudfunctions.googleapis.com",
    "eventarc.googleapis.com",
    "sqladmin.googleapis.com",
    "binaryauthorization.googleapis.com",
    "storagetransfer.googleapis.com"
  ]
  disable_on_destroy = false
  project_id         = data.google_project.project.project_id
}

# VPC Creation
module "carshub_vpc" {
  source                  = "../../modules/network/vpc"
  auto_create_subnetworks = false
  vpc_name                = "carshub-vpc"
}

# Subnets Creation
module "carshub_subnets" {
  source = "../../modules/network/subnet"
  subnets = [
    {
      name          = "carshub-subnet"
      ip_cidr_range = "10.0.1.0/24"
    }
  ]
  vpc_id                   = module.carshub_vpc.vpc_id
  private_ip_google_access = true
  location                 = var.location
}

# Firewall Creation
module "carshub_firewall" {
  source        = "../../modules/network/firewall"
  firewall_data = []
  vpc_id        = module.carshub_vpc.vpc_id
}

# Serverless VPC Creation
module "carshub_vpc_connectors" {
  source   = "../../modules/network/vpc-connector"
  vpc_name = module.carshub_vpc.vpc_name
  serverless_vpc_connectors = [
    {
      name          = "carshub-connector"
      ip_cidr_range = "10.8.0.0/28"
      min_instances = 2
      max_instances = 5
      machine_type  = "f1-micro"
    }
  ]
}

# Service Account
module "carshub_function_app_service_account" {
  source       = "../../modules/service-account"
  account_id   = "carshub-service-account"
  display_name = "CarsHub Service Account"
  project_id   = data.google_project.project.project_id
  permissions = [
    "roles/run.invoker",
    "roles/eventarc.eventReceiver",
    "roles/cloudsql.client",
    "roles/artifactregistry.reader",
    "roles/secretmanager.admin",
    "roles/pubsub.admin"
  ]
}

module "carshub_cloudbuild_service_account" {
  source       = "../../modules/service-account"
  account_id   = "carshub-cloudbuild-sa"
  display_name = "CarsHub Cloudbuild Service Account"
  project_id   = data.google_project.project.project_id
  permissions = [
    "roles/run.developer",
    "roles/logging.logWriter",
    "roles/iam.serviceAccountUser",
    "roles/artifactregistry.reader",
    "roles/artifactregistry.writer"
  ]
}

module "carshub_cloud_run_service_account" {
  source       = "../../modules/service-account"
  account_id   = "carshub-cloud-run-sa"
  display_name = "CarsHub Cloud Run Service Account"
  project_id   = data.google_project.project.project_id
  permissions = [
    "roles/secretmanager.secretAccessor",
    "roles/storage.admin",
    "roles/iam.serviceAccountTokenCreator"
  ]
}

// Creating a Pub/Sub topic.
resource "google_pubsub_topic_iam_binding" "binding" {
  topic   = module.carshub_media_bucket_pubsub.topic_id
  role    = "roles/pubsub.publisher"
  members = ["serviceAccount:${data.google_storage_project_service_account.carshub_gcs_account.email_address}"]
}

# Creating a Pub/Sub topic to send cloud storage events
module "carshub_media_bucket_pubsub" {
  source = "../../modules/pubsub"
  topic  = "carshub_media_bucket_events"
}

# Artifact Registry
module "carshub_frontend_artifact_registry" {
  source        = "../../modules/artifact-registry"
  location      = var.location
  description   = "CarHub frontend repository"
  repository_id = "carshub-frontend"
  shell_command = "bash ${path.cwd}/../../../frontend/artifact_push.sh http://${module.carshub_backend_service_lb.ip_address} ${module.carshub_cdn.cdn_ip_address}"
  depends_on    = [module.carshub_backend_service, module.carshub_apis]
}

module "carshub_backend_artifact_registry" {
  source        = "../../modules/artifact-registry"
  location      = var.location
  description   = "CarHub backend repository"
  repository_id = "carshub-backend"
  shell_command = "bash ${path.cwd}/../../../backend/api/artifact_push.sh"
  depends_on    = [module.carshub_db, module.carshub_apis]
}

# GCS
module "carshub_media_bucket" {
  source   = "../../modules/gcs"
  location = var.location
  name     = "carshub-media"
  cors = [
    {
      origin          = ["http://${module.carshub_frontend_service_lb.ip_address}"]
      max_age_seconds = 3600
      method          = ["GET", "POST", "PUT", "DELETE"]
      response_header = ["*"]
    }
  ]
  versioning = true
  lifecycle_rules = [
    {
      condition = {
        age = 1
      }
      action = {
        type          = "AbortIncompleteMultipartUpload"
        storage_class = null
      }
    },
    {
      condition = {
        age = 1095
      }
      action = {
        storage_class = "ARCHIVE"
        type          = "SetStorageClass"
      }
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
  notifications = [
    {
      topic_id = module.carshub_media_bucket_pubsub.topic_id
    }
  ]
  force_destroy               = true
  uniform_bucket_level_access = true
}

module "carshub_media_bucket_backup" {
  source   = "../../modules/gcs"
  location = var.backup_location
  name     = "carshub-media-backup"
  cors = [
    {
      origin          = [module.carshub_frontend_service_lb.ip_address]
      max_age_seconds = 3600
      method          = ["GET", "POST", "PUT", "DELETE"]
      response_header = ["*"]
    }
  ]
  versioning = true
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
  lifecycle_rules = [
    {
      condition = {
        age = 1
      }
      action = {
        type          = "AbortIncompleteMultipartUpload"
        storage_class = null
      }
    },
    {
      condition = {
        age = 1095
      }
      action = {
        storage_class = "ARCHIVE"
        type          = "SetStorageClass"
      }
    }
  ]
  notifications = [
    # {
    #   topic_id = module.carshub_media_bucket_pubsub.topic_id
    # }
  ]
  force_destroy               = true
  uniform_bucket_level_access = true
}


module "carshub_media_bucket_code" {
  source   = "../../modules/gcs"
  location = var.location
  name     = "carshub-media-code"
  cors     = []
  contents = [
    {
      name        = "code.zip"
      source_path = "${path.root}/../../files/code.zip"
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
  source                = "../../modules/cdn"
  bucket_name           = module.carshub_media_bucket.bucket_name
  enable_cdn            = true
  description           = "Content delivery network for media files"
  name                  = "carshub-media-cdn"
  forwarding_port_range = "80"
  forwarding_rule_name  = "carshub-cdn-global-forwarding-rule"
  forwarding_scheme     = "EXTERNAL"
  global_address_type   = "EXTERNAL"
  url_map_name          = "carshub-cdn-compute-url-map"
  global_address_name   = "carshub-cdn-lb-global-address"
  target_proxy_name     = "carshub-cdn-target-proxy"
}

# Secret Manager
module "carshub_sql_password_secret" {
  source      = "../../modules/secret-manager"
  secret_data = tostring(data.vault_generic_secret.sql.data["password"])
  secret_id   = "carshub_db_password_secret"
  depends_on  = [module.carshub_apis]
}

# Cloud SQL
module "carshub_db" {
  source                      = "../../modules/cloud-sql"
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
  source = "../../modules/cloud-run-iam"
  members = [
    module.carshub_backend_service.name,
    module.carshub_frontend_service.name
  ]
}

# Cloud Run Frontend Service
module "carshub_frontend_service" {
  source              = "../../modules/cloud-run"
  deletion_protection = false
  ingress             = "INGRESS_TRAFFIC_ALL"
  vpc_connector_name  = module.carshub_vpc_connectors.vpc_connectors[0].id
  service_account     = module.carshub_cloud_run_service_account.sa_email
  location            = var.location
  min_instance_count  = 1
  max_instance_count  = 2
  name                = "carshub-frontend-service"
  volumes             = []
  traffic = [
    {
      traffic_type         = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
      traffic_type_percent = 100
    }
  ]
  containers = [
    {
      env = [
        # {
        #   name         = "BASE_URL"
        #   value        = "http://${module.carshub_backend_service_lb.ip_address}"
        #   value_source = []
        # },
        # {
        #   name         = "CDN_URL"
        #   value        = "${module.carshub_cdn.cdn_ip_address}"
        #   value_source = []
        # },
      ]
      volume_mounts = []
      image         = "${var.location}-docker.pkg.dev/${data.google_project.project.project_id}/carshub-frontend/carshub-frontend:latest"
    }
  ]
  depends_on = [module.carshub_frontend_artifact_registry, module.carshub_apis, module.carshub_cloud_run_service_account]
}

# Cloud Run Backend Service
module "carshub_backend_service" {
  source              = "../../modules/cloud-run"
  deletion_protection = false
  vpc_connector_name  = module.carshub_vpc_connectors.vpc_connectors[0].id
  ingress             = "INGRESS_TRAFFIC_ALL"
  service_account     = module.carshub_cloud_run_service_account.sa_email
  location            = var.location
  min_instance_count  = 1
  max_instance_count  = 2
  volumes = [
    {
      name               = "cloudsql"
      cloud_sql_instance = [module.carshub_db.db_connection_name]
    }
  ]
  name = "carshub-backend-service"
  traffic = [
    {
      traffic_type         = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
      traffic_type_percent = 100
    }
  ]
  containers = [
    {
      image = "${var.location}-docker.pkg.dev/${data.google_project.project.project_id}/carshub-backend/carshub-backend:latest"
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
    }
  ]
  depends_on = [module.carshub_apis, module.carshub_sql_password_secret, module.carshub_backend_artifact_registry, module.carshub_cloud_run_service_account]
}

# Cloud Run Function (Any cloud run function can only have one trigger at a time)
module "carshub_media_update_function" {
  source                       = "../../modules/cloud-run-function"
  function_name                = "carshub-media-function"
  function_description         = "A function to update media details in SQL database after the upload trigger"
  handler                      = "handler"
  runtime                      = "python312"
  location                     = var.location
  storage_source_bucket        = module.carshub_media_bucket_code.bucket_name
  storage_source_bucket_object = module.carshub_media_bucket_code.object_name[0].name
  build_env_variables = {
    DB_USER     = module.carshub_db.db_user
    DB_NAME     = module.carshub_db.db_name
    SECRET_NAME = module.carshub_sql_password_secret.secret_name
    DB_PATH     = module.carshub_db.db_ip_address
  }
  all_traffic_on_latest_revision      = true
  vpc_connector                       = module.carshub_vpc_connectors.vpc_connectors[0].id
  vpc_connector_egress_settings       = "ALL_TRAFFIC"
  ingress_settings                    = "ALLOW_INTERNAL_ONLY"
  function_app_service_account_email  = module.carshub_function_app_service_account.sa_email
  max_instance_count                  = 3
  min_instance_count                  = 1
  available_memory                    = "256M"
  timeout_seconds                     = 60
  event_trigger_event_type            = "google.cloud.pubsub.topic.v1.messagePublished"
  event_trigger_topic                 = module.carshub_media_bucket_pubsub.topic_id
  event_trigger_retry_policy          = "RETRY_POLICY_RETRY"
  event_trigger_service_account_email = module.carshub_function_app_service_account.sa_email
  event_filters                       = []
  depends_on                          = [module.carshub_function_app_service_account]
}

# Network endpoint groups
module "carshub_frontend_service_neg" {
  source       = "../../modules/network_endpoint_groups"
  neg_name     = "carshub-frontend-service-neg"
  neg_type     = "SERVERLESS"
  location     = var.location
  service_name = module.carshub_frontend_service.name
}

module "carshub_backend_service_neg" {
  source       = "../../modules/network_endpoint_groups"
  neg_name     = "carshub-backend-service-neg"
  neg_type     = "SERVERLESS"
  location     = var.location
  service_name = module.carshub_backend_service.name
}

# Load Balancer
module "carshub_frontend_service_lb" {
  source                   = "../../modules/load-balancer"
  forwarding_port_range    = "80"
  forwarding_rule_name     = "carshub-frontend-service-global-forwarding-rule"
  forwarding_scheme        = "EXTERNAL"
  global_address_type      = "EXTERNAL"
  url_map_name             = "carshub-frontend-service-compute-url-map"
  global_address_name      = "carshub-frontend-service-lb-global-address"
  target_proxy_name        = "carshub-frontend-service-target-proxy"
  backend_service_name     = "carshub-frontend-compute"
  backend_service_protocol = "HTTP"
  backend_service_timeout  = 30
  backends = [
    {
      backend = module.carshub_frontend_service_neg.id
    }
  ]
  depends_on = [module.carshub_frontend_service]
}

# Load Balancer
module "carshub_backend_service_lb" {
  source                   = "../../modules/load-balancer"
  forwarding_port_range    = "80"
  forwarding_rule_name     = "carshub-backend-service-global-forwarding-rule"
  forwarding_scheme        = "EXTERNAL"
  global_address_type      = "EXTERNAL"
  url_map_name             = "carshub-backend-service-compute-url-map"
  global_address_name      = "carshub-backend-service-lb-global-address"
  target_proxy_name        = "carshub-backend-service-target-proxy"
  backend_service_name     = "carshub-backend-compute"
  backend_service_protocol = "HTTP"
  backend_service_timeout  = 30
  backends = [
    {
      backend = module.carshub_backend_service_neg.id
    }
  ]
  depends_on = [module.carshub_backend_service]
}

# CloudBuild configuration
module "carshub_cloudbuild_frontend_trigger" {
  source          = "../../modules/cloudbuild"
  trigger_name    = "carshub-frontend-trigger"
  location        = var.location
  repo_name       = "mmdcloud-carshub-gcp-cloud-run"
  source_uri      = "https://github.com/mmdcloud/carshub-gcp-cloud-run"
  source_ref      = "frontend"
  repo_type       = "GITHUB"
  filename        = "cloudbuild.yaml"
  service_account = module.carshub_cloudbuild_service_account.id
}

module "carshub_cloudbuild_backend_trigger" {
  source          = "../../modules/cloudbuild"
  trigger_name    = "carshub-backend-trigger"
  location        = var.location
  repo_name       = "mmdcloud-carshub-gcp-cloud-run"
  source_uri      = "https://github.com/mmdcloud/carshub-gcp-cloud-run"
  source_ref      = "backend"
  repo_type       = "GITHUB"
  filename        = "cloudbuild.yaml"
  service_account = module.carshub_cloudbuild_service_account.id
}
