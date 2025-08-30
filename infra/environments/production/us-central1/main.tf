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
  source = "../../../modules/apis"
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
  source                  = "../../../modules/network/vpc"
  auto_create_subnetworks = false
  vpc_name                = "carshub-vpc"
}

# Subnets Creation
module "carshub_public_subnets" {
  source                   = "../../../modules/network/subnet"
  name                     = "carshub-public-subnet"
  subnets                  = var.public_subnets
  vpc_id                   = module.carshub_vpc.vpc_id
  private_ip_google_access = false
  location                 = var.location
}

module "carshub_private_subnets" {
  source                   = "../../../modules/network/subnet"
  name                     = "carshub-private-subnet"
  subnets                  = var.private_subnets
  vpc_id                   = module.carshub_vpc.vpc_id
  private_ip_google_access = true
  location                 = var.location
}

# Serverless VPC Creation
module "carshub_vpc_connectors" {
  source   = "../../../modules/network/vpc-connector"
  vpc_name = module.carshub_vpc.vpc_name
  serverless_vpc_connectors = [
    {
      name          = "carshub-connector"
      ip_cidr_range = "10.8.0.0/28"
      min_instances = 2
      max_instances = 3
      machine_type  = "e2-micro"
    }
  ]
}

# Service Account
module "carshub_function_app_service_account" {
  source        = "../../../modules/service-account"
  account_id    = "carshub-service-account"
  display_name  = "CarsHub Service Account"
  project_id    = data.google_project.project.project_id
  member_prefix = "serviceAccount"
  permissions = [
    "roles/run.invoker",
    "roles/eventarc.eventReceiver",
    "roles/cloudsql.client",
    "roles/artifactregistry.reader",
    "roles/secretmanager.admin",
    "roles/pubsub.publisher"
  ]
}

module "carshub_cloudbuild_service_account" {
  source        = "../../../modules/service-account"
  account_id    = "carshub-cloudbuild-sa"
  display_name  = "CarsHub Cloudbuild Service Account"
  project_id    = data.google_project.project.project_id
  member_prefix = "serviceAccount"
  permissions = [
    "roles/run.developer",
    "roles/logging.logWriter",
    "roles/iam.serviceAccountUser",
    "roles/artifactregistry.reader",
    "roles/artifactregistry.writer"
  ]
}

module "carshub_cloud_run_service_account" {
  source        = "../../../modules/service-account"
  account_id    = "carshub-cloud-run-sa"
  display_name  = "CarsHub Cloud Run Service Account"
  project_id    = data.google_project.project.project_id
  member_prefix = "serviceAccount"
  permissions = [
    "roles/secretmanager.secretAccessor",
    "roles/storage.admin",
    "roles/iam.serviceAccountTokenCreator"
  ]
}

# Cloud Armor WAF protection for Load Balancers
# module "cloud_armor" {
#   source  = "GoogleCloudPlatform/cloud-armor/google"
#   version = "~> 5.0"

#   project_id                           = data.google_project.project.project_id
#   name                                 = "carshub-security-policy"
#   description                          = "CarHub Cloud Armor security policy with WAF rules"
#   default_rule_action                  = "allow"
#   type                                 = "CLOUD_ARMOR"
#   layer_7_ddos_defense_enable          = true
#   layer_7_ddos_defense_rule_visibility = "STANDARD"
#   user_ip_request_headers              = ["True-Client-IP"]

#   # Rate limiting rule
#   security_rules = {
#     "rate_limit_rule" = {
#       action      = "rate_based_ban"
#       priority    = 1
#       description = "Rate limiting rule"
#       rate_limit_options = {
#         conform_action = "allow"
#         exceed_action  = "deny(429)"
#         enforce_on_key = "IP"
#         rate_limit_threshold = {
#           count        = 100
#           interval_sec = 60
#         }
#         ban_duration_sec = 300
#       }
#       match = {
#         versioned_expr = "SRC_IPS_V1"
#         config = {
#           src_ip_ranges = ["*"]
#         }
#       }
#     }
#   }

#   # Preconfigured WAF rules
#   pre_configured_rules = {
#     "xss-stable_level_2" = {
#       action            = "deny(403)"
#       priority          = 2
#       target_rule_set   = "xss-v33-stable"
#       sensitivity_level = 2
#     }
#     "sqli-stable_level_2" = {
#       action            = "deny(403)"
#       priority          = 3
#       target_rule_set   = "sqli-v33-stable"
#       sensitivity_level = 2
#     }
#   }
# }

// Creating a Pub/Sub topic.
resource "google_pubsub_topic_iam_binding" "binding" {
  topic   = module.carshub_media_bucket_pubsub.topic_id
  role    = "roles/pubsub.publisher"
  members = ["serviceAccount:${data.google_storage_project_service_account.carshub_gcs_account.email_address}"]
}

# Creating a Pub/Sub topic to send cloud storage events
module "carshub_media_bucket_pubsub" {
  source = "../../../modules/pubsub"
  topic  = "carshub_media_bucket_events"
}

# Artifact Registry
module "carshub_frontend_artifact_registry" {
  source        = "../../../modules/artifact-registry"
  location      = var.location
  description   = "CarHub frontend repository"
  repository_id = "carshub-frontend"
  shell_command = "bash ${path.cwd}/../../../../src/frontend/artifact_push.sh http://${module.carshub_backend_service_lb.ip_address} ${module.carshub_cdn.cdn_ip_address} ${data.google_project.project.project_id}"
  depends_on    = [module.carshub_backend_service, module.carshub_apis]
}

module "carshub_backend_artifact_registry" {
  source        = "../../../modules/artifact-registry"
  location      = var.location
  description   = "CarHub backend repository"
  repository_id = "carshub-backend"
  shell_command = "bash ${path.cwd}/../../../../src/backend/api/artifact_push.sh ${data.google_project.project.project_id}"
  depends_on    = [module.carshub_db, module.carshub_apis]
}

# GCS
module "carshub_media_bucket" {
  source   = "../../../modules/gcs"
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

module "carshub_media_bucket_code" {
  source   = "../../../modules/gcs"
  location = var.location
  name     = "carshub-media-code"
  cors     = []
  contents = [
    {
      name        = "carshub_media_function_code.zip"
      source_path = "${path.root}/../../../files/carshub_media_function_code.zip"
      content     = ""
    }
  ]
  force_destroy               = true
  uniform_bucket_level_access = true
}

# Cloud storage IAM binding
resource "google_storage_bucket_iam_binding" "storage_iam_binding" {
  bucket = module.carshub_media_bucket.bucket_name
  role   = "roles/storage.objectViewer"

  members = [
    "allUsers"
  ]
}

# CDN for handling media files
module "carshub_cdn" {
  source                = "../../../modules/cdn"
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
  source      = "../../../modules/secret-manager"
  secret_data = tostring(data.vault_generic_secret.sql.data["password"])
  secret_id   = "carshub_db_password_secret"
  depends_on  = [module.carshub_apis]
}

module "carshub_sql_username_secret" {
  source      = "../../../modules/secret-manager"
  secret_data = tostring(data.vault_generic_secret.sql.data["username"])
  secret_id   = "carshub_db_username_secret"
  depends_on  = [module.carshub_apis]
}

# Cloud SQL
module "carshub_db" {
  source                      = "../../../modules/cloud-sql"
  name                        = "carshub-db-instance"
  db_name                     = "carshub"
  db_user                     = module.carshub_sql_username_secret.secret_data
  db_version                  = "MYSQL_8_0"
  location                    = var.location
  tier                        = "db-custom-2-8192"
  availability_type           = "REGIONAL"
  disk_size                   = 100 # GB
  disk_type                   = "PD_SSD"
  disk_autoresize             = true
  disk_autoresize_limit       = 500 # GB
  ipv4_enabled                = false
  deletion_protection_enabled = false
  backup_configuration = [
    {
      enabled                        = true
      binary_log_enabled             = true
      start_time                     = "03:00"
      location                       = var.location
      point_in_time_recovery_enabled = false
      backup_retention_settings = [
        {
          retained_backups = 30
          retention_unit   = "COUNT"
        }
      ]
    }
  ]
  database_flags = [
    {
      name  = "max_connections"
      value = "1000"
    },
    {
      name  = "skip_show_database"
      value = "on"
    }
    # {
    #   name  = "innodb_buffer_pool_size"
    #   value = "20GB"
    # },
    # {
    #   name  = "query_cache_size"
    #   value = "256MB"
    # }
  ]
  vpc_self_link = module.carshub_vpc.self_link
  vpc_id        = module.carshub_vpc.vpc_id
  password      = module.carshub_sql_password_secret.secret_data
  depends_on    = [module.carshub_sql_password_secret]
}

# Cloud Run

# Cloud Run IAM Permissions
module "carshub_run_iam_permissions" {
  source = "../../../modules/cloud-run-iam"
  members = [
    module.carshub_backend_service.name,
    module.carshub_frontend_service.name
  ]
}

# Cloud Run Frontend Service
module "carshub_frontend_service" {
  source                           = "../../../modules/cloud-run"
  deletion_protection              = false
  ingress                          = "INGRESS_TRAFFIC_ALL"
  vpc_connector_name               = module.carshub_vpc_connectors.vpc_connectors[0].id
  service_account                  = module.carshub_cloud_run_service_account.sa_email
  location                         = var.location
  min_instance_count               = 2
  max_instance_count               = 5
  max_instance_request_concurrency = 80
  name                             = "carshub-frontend-service"
  volumes                          = []
  traffic = [
    {
      traffic_type         = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
      traffic_type_percent = 100
    }
  ]
  containers = [
    {
      env               = []
      volume_mounts     = []
      cpu_idle          = true
      startup_cpu_boost = true
      image             = "${var.location}-docker.pkg.dev/${data.google_project.project.project_id}/carshub-frontend/carshub-frontend:latest"
    }
  ]
  depends_on = [module.carshub_frontend_artifact_registry, module.carshub_apis, module.carshub_cloud_run_service_account]
}

# Cloud Run Backend Service
module "carshub_backend_service" {
  source                           = "../../../modules/cloud-run"
  deletion_protection              = false
  vpc_connector_name               = module.carshub_vpc_connectors.vpc_connectors[0].id
  ingress                          = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"
  service_account                  = module.carshub_cloud_run_service_account.sa_email
  location                         = var.location
  min_instance_count               = 2
  max_instance_count               = 5
  max_instance_request_concurrency = 80
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
      image             = "${var.location}-docker.pkg.dev/${data.google_project.project.project_id}/carshub-backend/carshub-backend:latest"
      cpu_idle          = true
      startup_cpu_boost = true
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
          name  = "UN"
          value = ""
          value_source = [
            {
              secret_key_ref = [
                {
                  secret  = module.carshub_sql_username_secret.secret_id
                  version = "1"
                }
              ]
            }
          ]
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
  source                       = "../../../modules/cloud-run-function"
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
  max_instance_count                  = 10
  min_instance_count                  = 2
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
  source       = "../../../modules/network_endpoint_groups"
  neg_name     = "carshub-frontend-service-neg"
  neg_type     = "SERVERLESS"
  location     = var.location
  service_name = module.carshub_frontend_service.name
}

module "carshub_backend_service_neg" {
  source       = "../../../modules/network_endpoint_groups"
  neg_name     = "carshub-backend-service-neg"
  neg_type     = "SERVERLESS"
  location     = var.location
  service_name = module.carshub_backend_service.name
}

# Load Balancer with HTTPS
module "carshub_frontend_service_lb" {
  source                   = "../../../modules/load-balancer"
  forwarding_port_range    = "443"
  forwarding_rule_name     = "carshub-frontend-service-global-forwarding-rule"
  forwarding_scheme        = "EXTERNAL"
  global_address_type      = "EXTERNAL"
  url_map_name             = "carshub-frontend-service-compute-url-map"
  global_address_name      = "carshub-frontend-service-lb-global-address"
  target_proxy_name        = "carshub-frontend-service-target-proxy"
  backend_service_name     = "carshub-frontend-compute"
  backend_service_protocol = "HTTPS"
  backend_service_timeout  = 30
  # security_policy          = module.cloud_armor.policy.id
  # ssl_certificates         = [google_compute_managed_ssl_certificate.carshub_ssl_cert.id]
  backends = [
    {
      backend = module.carshub_frontend_service_neg.id
    }
  ]
  depends_on = [module.carshub_frontend_service]
}

# Backend Load Balancer with HTTPS
module "carshub_backend_service_lb" {
  source                   = "../../../modules/load-balancer"
  forwarding_port_range    = "443"
  forwarding_rule_name     = "carshub-backend-service-global-forwarding-rule"
  forwarding_scheme        = "EXTERNAL"
  global_address_type      = "EXTERNAL"
  url_map_name             = "carshub-backend-service-compute-url-map"
  global_address_name      = "carshub-backend-service-lb-global-address"
  target_proxy_name        = "carshub-backend-service-target-proxy"
  backend_service_name     = "carshub-backend-compute"
  backend_service_protocol = "HTTPS"
  backend_service_timeout  = 30
  # security_policy          = module.cloud_armor.policy.id
  # ssl_certificates         = [google_compute_managed_ssl_certificate.carshub_ssl_cert.id]
  backends = [
    {
      backend = module.carshub_backend_service_neg.id
    }
  ]
  depends_on = [module.carshub_backend_service]
}

# CloudBuild configuration
module "carshub_cloudbuild_frontend_trigger" {
  source       = "../../../modules/cloudbuild"
  trigger_name = "carshub-frontend-trigger"
  location     = var.location
  repo_name    = "mmdcloud-gcp-carshub-cloud-run"
  source_uri   = "https://github.com/mmdcloud/gcp-carshub-cloud-run"
  source_ref   = "frontend"
  repo_type    = "GITHUB"
  filename     = "cloudbuild.yaml"
  substitutions = {
    _PROJECT_ID         = "${data.google_project.project.project_id}"
    _BACKEND_IP_ADDRESS = "${module.carshub_backend_service_lb.ip_address}"
    _CDN_IP_ADDRESS     = "${module.carshub_cdn.cdn_ip_address}"
  }
  service_account = module.carshub_cloudbuild_service_account.id
}

module "carshub_cloudbuild_backend_trigger" {
  source       = "../../../modules/cloudbuild"
  trigger_name = "carshub-backend-trigger"
  location     = var.location
  repo_name    = "mmdcloud-gcp-carshub-cloud-run"
  source_uri   = "https://github.com/mmdcloud/gcp-carshub-cloud-run"
  source_ref   = "backend"
  repo_type    = "GITHUB"
  filename     = "cloudbuild.yaml"
  substitutions = {
    _PROJECT_ID = "${data.google_project.project.project_id}"
  }
  service_account = module.carshub_cloudbuild_service_account.id
}

# Uptime checks
module "frontend_uptime_check" {
  source              = "../../../modules/observability/uptime_checks"
  display_name        = "Frontend Uptime Check"
  timeout             = "30s"
  period              = "60s"
  http_path           = "/auth/signin"
  http_port           = "80"
  http_request_method = "GET"
  http_validate_ssl   = false
  resource_type       = "uptime_url"
  resource_host       = module.carshub_frontend_service_lb.ip_address
  checker_type        = "STATIC_IP_CHECKERS"
}

module "backend_uptime_check" {
  source              = "../../../modules/observability/uptime_checks"
  display_name        = "Backend Uptime Check"
  timeout             = "30s"
  period              = "60s"
  http_path           = "/"
  http_port           = "80"
  http_request_method = "GET"
  http_validate_ssl   = false
  resource_type       = "uptime_url"
  resource_host       = module.carshub_backend_service_lb.ip_address
  checker_type        = "STATIC_IP_CHECKERS"
}

# Observability Metrics for Production Monitoring
# module "http_4xx_errors" {
#   source       = "../../../modules/observability/metrics"
#   name         = "http_4xx_errors"
#   filter       = <<-EOT
#     resource.type="http_load_balancer"
#     httpRequest.status>=400
#     httpRequest.status<500
#   EOT
#   metric_kind  = "DELTA"
#   value_type   = "INT64"
#   display_name = "HTTP 4xx Errors"
#   label_extractors = {
#     "status_code" = "EXTRACT(httpRequest.status)"
#     "url_map"     = "EXTRACT(resource.labels.url_map_name)"
#   }
# }

# module "http_5xx_errors" {
#   source       = "../../../modules/observability/metrics"
#   name         = "http_5xx_errors"
#   filter       = <<-EOT
#     resource.type="http_load_balancer"
#     httpRequest.status>=500
#   EOT
#   metric_kind  = "DELTA"
#   value_type   = "INT64"
#   display_name = "HTTP 5xx Errors"
#   label_extractors = {
#     "status_code" = "EXTRACT(httpRequest.status)"
#     "url_map"     = "EXTRACT(resource.labels.url_map_name)"
#   }
# }

# module "database_connection_errors" {
#   source           = "../../../modules/observability/metrics"
#   name             = "database_connection_errors"
#   filter           = <<-EOT
#     resource.type="cloudsql_database"
#     (textPayload:"connection" OR textPayload:"timeout" OR textPayload:"failed")
#     severity="ERROR"
#   EOT
#   metric_kind      = "DELTA"
#   value_type       = "INT64"
#   display_name     = "Database Connection Errors"
#   label_extractors = {}
# }

# Alerting Policies
# module "high_error_rate_alert" {
#   source                = "../../../modules/observability/alerts"
#   display_name          = "High Error Rate Alert"
#   combiner              = "OR"
#   notification_channels = [var.notification_channel_email]
#   conditions = [
#     {
#       display_name = "HTTP 5xx Error Rate"
#       condition_threshold = {
#         filter          = "resource.type=\"http_load_balancer\" AND httpRequest.status>=500"
#         duration        = "300s"
#         comparison      = "COMPARISON_GREATER_THAN"
#         threshold_value = 10
#       }
#     }
#   ]
# }

# module "database_connection_alert" {
#   source                = "../../../modules/observability/alerts"
#   display_name          = "Database Connection Alert"
#   combiner              = "OR"
#   notification_channels = [var.notification_channel_email]
#   conditions = [
#     {
#       display_name = "Database Connection Errors"
#       condition_threshold = {
#         filter          = "resource.type=\"cloudsql_database\" AND severity=\"ERROR\""
#         duration        = "300s"
#         comparison      = "COMPARISON_GREATER_THAN"
#         threshold_value = 5
#       }
#     }
#   ]
# }