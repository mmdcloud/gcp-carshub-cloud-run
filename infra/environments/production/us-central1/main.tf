# -----------------------------------------------------------------------------------------
# Registering vault provider
# -----------------------------------------------------------------------------------------
data "vault_generic_secret" "sql" {
  path = "secret/sql"
}

# -----------------------------------------------------------------------------------------
# Getting project information
# -----------------------------------------------------------------------------------------
data "google_project" "project" {}
data "google_storage_project_service_account" "carshub_gcs_account" {}

# -----------------------------------------------------------------------------------------
# Enabling APIS
# -----------------------------------------------------------------------------------------
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

# -----------------------------------------------------------------------------------------
# VPC
# -----------------------------------------------------------------------------------------
module "carshub_vpc" {
  source                          = "../../../modules/vpc"
  vpc_name                        = "carshub-vpc"
  delete_default_routes_on_create = false
  auto_create_subnetworks         = false
  routing_mode                    = "REGIONAL"
  region                          = var.location
  subnets                         = []
  firewall_data                   = []
}

# -----------------------------------------------------------------------------------------
# Serverless VPC Connectors
# -----------------------------------------------------------------------------------------
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

# -----------------------------------------------------------------------------------------
# Service Accounts
# -----------------------------------------------------------------------------------------
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
    # "roles/secretmanager.admin",
    "roles/secretmanager.secretAccessor",
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
    # "roles/storage.admin",
    "roles/storage.objectAdmin",
    "roles/iam.serviceAccountTokenCreator"
  ]
}

# -----------------------------------------------------------------------------------------
# Cloud Armor WAF protection for Load Balancers
# -----------------------------------------------------------------------------------------
module "cloud_armor" {
  source                               = "GoogleCloudPlatform/cloud-armor/google"
  version                              = "~> 5.0"
  project_id                           = data.google_project.project.project_id
  name                                 = "carshub-security-policy"
  description                          = "CarHub Cloud Armor security policy with WAF rules"
  default_rule_action                  = "allow"
  type                                 = "CLOUD_ARMOR"
  layer_7_ddos_defense_enable          = true
  layer_7_ddos_defense_rule_visibility = "STANDARD"
  user_ip_request_headers              = ["True-Client-IP"]

  security_rules = {
    # Rate limiting
    "rate_limit_rule" = {
      action      = "rate_based_ban"
      priority    = 1
      description = "Rate limiting rule"

      # REQUIRED by the module (even though it feels redundant)
      src_ip_ranges = ["*"]

      rate_limit_options = {
        conform_action = "allow"
        exceed_action  = "deny(429)"
        enforce_on_key = "IP"
        rate_limit_threshold = {
          count        = 100
          interval_sec = 60
        }
        ban_duration_sec = 600
      }

      match = {
        versioned_expr = "SRC_IPS_V1"
        config = {
          src_ip_ranges = ["*"]
        }
      }
    }

    # Block known bad IPs (you should maintain this list)
    "block_bad_ips" = {
      action        = "deny(403)"
      priority      = 10
      description   = "Block known malicious IPs"
      src_ip_ranges = ["*"]
      match = {
        versioned_expr = "SRC_IPS_V1"
        config = {
          src_ip_ranges = [
            # Add known malicious IPs here
            # "1.2.3.4/32",
          ]
        }
      }
    }

    # Geographic restrictions (if needed)
    "geo_blocking" = {
      action        = "deny(403)"
      priority      = 11
      description   = "Block traffic from specific countries"
      src_ip_ranges = ["*"]
      match = {
        expr = {
          expression = "origin.region_code in ['CN', 'RU']"
        }
        config = {
          src_ip_ranges = ["*"]
        }
      }
    }
  }

  pre_configured_rules = {
    "xss-stable_level_2" = {
      action            = "deny(403)"
      priority          = 2
      target_rule_set   = "xss-v33-stable"
      sensitivity_level = 2
    }
    "sqli-stable_level_2" = {
      action            = "deny(403)"
      priority          = 3
      target_rule_set   = "sqli-v33-stable"
      sensitivity_level = 2
    }
    "lfi-stable_level_2" = {
      action            = "deny(403)"
      priority          = 4
      target_rule_set   = "lfi-v33-stable"
      sensitivity_level = 2
    }
    "rce-stable_level_2" = {
      action            = "deny(403)"
      priority          = 5
      target_rule_set   = "rce-v33-stable"
      sensitivity_level = 2
    }
    "rfi-stable_level_2" = {
      action            = "deny(403)"
      priority          = 6
      target_rule_set   = "rfi-v33-stable"
      sensitivity_level = 2
    }
    "scannerdetection-stable_level_2" = {
      action            = "deny(403)"
      priority          = 7
      target_rule_set   = "scannerdetection-v33-stable"
      sensitivity_level = 2
    }
    "protocolattack-stable_level_2" = {
      action            = "deny(403)"
      priority          = 8
      target_rule_set   = "protocolattack-v33-stable"
      sensitivity_level = 2
    }
    "sessionfixation-stable_level_2" = {
      action            = "deny(403)"
      priority          = 9
      target_rule_set   = "sessionfixation-v33-stable"
      sensitivity_level = 2
    }
  }
}

# -----------------------------------------------------------------------------------------
# 2. SECURITY: SSL/TLS Configuration
# -----------------------------------------------------------------------------------------
# resource "google_compute_managed_ssl_certificate" "carshub_frontend_ssl_cert" {
#   name = "carshub-frontend-ssl-cert"
#   managed {
#     domains = ["frontend.carshub.example.com"]  # Replace with your domain
#   }
# }

# resource "google_compute_managed_ssl_certificate" "carshub_backend_ssl_cert" {
#   name = "carshub-backend-ssl-cert"
#   managed {
#     domains = ["api.carshub.example.com"]  # Replace with your domain
#   }
# }

# -----------------------------------------------------------------------------------------
# Pub/Sub Configuration
# -----------------------------------------------------------------------------------------
resource "google_pubsub_topic_iam_binding" "binding" {
  topic   = module.carshub_media_bucket_pubsub.topic_id
  role    = "roles/pubsub.publisher"
  members = ["serviceAccount:${data.google_storage_project_service_account.carshub_gcs_account.email_address}"]
}

module "carshub_media_bucket_pubsub" {
  source = "../../../modules/pubsub"
  topic  = "carshub_media_bucket_events"
}

# -----------------------------------------------------------------------------------------
# Artifact Registry Configuration
# -----------------------------------------------------------------------------------------
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

# -----------------------------------------------------------------------------------------
# Google Cloud Storage (GCS) Configuration
# -----------------------------------------------------------------------------------------
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
resource "google_storage_bucket_iam_member" "cdn_access" {
  bucket = module.carshub_media_bucket.bucket_name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:service-${data.google_project.project.number}@cloud-cdn-fill.iam.gserviceaccount.com"
}

resource "google_storage_bucket_iam_member" "backend_access" {
  bucket = module.carshub_media_bucket.bucket_name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${module.carshub_cloud_run_service_account.sa_email}"
}
# resource "google_storage_bucket_iam_binding" "storage_iam_binding" {
#   bucket = module.carshub_media_bucket.bucket_name
#   role   = "roles/storage.objectViewer"

#   members = [
#     "allUsers"
#   ]
# }

# -----------------------------------------------------------------------------------------
# CDN Configuration
# -----------------------------------------------------------------------------------------
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

# -----------------------------------------------------------------------------------------
# Secret Manager Configuration
# -----------------------------------------------------------------------------------------
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

# -----------------------------------------------------------------------------------------
# Cloud SQL Configuration
# -----------------------------------------------------------------------------------------
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
      name  = "general_log"
      value = "on"
    },
    {
      name  = "log_queries_not_using_indexes"
      value = "on"
    },
    {
      name  = "max_connections"
      value = "1000"
    },
    {
      name  = "skip_show_database"
      value = "on"
    },
    {
      name  = "slow_query_log"
      value = "on"
    },
    {
      name  = "long_query_time"
      value = "2"
    },
    {
      name  = "log_output"
      value = "FILE"
    },
    # Performance tuning
    {
      name  = "innodb_buffer_pool_size"
      value = "10737418240" # 10GB for 16GB instance
    },
    {
      name  = "innodb_log_file_size"
      value = "536870912" # 512MB
    }
  ]
  vpc_self_link = module.carshub_vpc.self_link
  vpc_id        = module.carshub_vpc.vpc_id
  password      = module.carshub_sql_password_secret.secret_data
  depends_on    = [module.carshub_sql_password_secret]
}

# -----------------------------------------------------------------------------------------
# Cloud Run Configuration
# -----------------------------------------------------------------------------------------
module "carshub_run_iam_permissions" {
  source = "../../../modules/cloud-run-iam"
  members = [
    module.carshub_backend_service.name,
    module.carshub_frontend_service.name
  ]
}

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

# -----------------------------------------------------------------------------------------
# Cloud Function Configuration
# -----------------------------------------------------------------------------------------
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

# -----------------------------------------------------------------------------------------
# Network endpoint groups Configuration
# -----------------------------------------------------------------------------------------
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

# -----------------------------------------------------------------------------------------
# Load Balancer Configuration
# -----------------------------------------------------------------------------------------
module "carshub_frontend_service_lb" {
  source                   = "../../../modules/load-balancer"
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
  # security_policy          = module.cloud_armor.policy.id
  # ssl_certificates         = [google_compute_managed_ssl_certificate.carshub_ssl_cert.id]
  backends = [
    {
      backend = module.carshub_frontend_service_neg.id
    }
  ]
  depends_on = [module.carshub_frontend_service]
}

# Backend Load Balancer with HTTP
module "carshub_backend_service_lb" {
  source                   = "../../../modules/load-balancer"
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
  # security_policy          = module.cloud_armor.policy.id
  # ssl_certificates         = [google_compute_managed_ssl_certificate.carshub_ssl_cert.id]
  backends = [
    {
      backend = module.carshub_backend_service_neg.id
    }
  ]
  depends_on = [module.carshub_backend_service]
}

# -----------------------------------------------------------------------------------------
# CloudBuild Configuration
# -----------------------------------------------------------------------------------------
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

# -----------------------------------------------------------------------------------------
# Uptime Checks Configuration
# -----------------------------------------------------------------------------------------
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

# -----------------------------------------------------------------------------------------
# Email notification channel
# -----------------------------------------------------------------------------------------
resource "google_monitoring_notification_channel" "email_alerts" {
  display_name = "Email Alerts"
  type         = "email"
  labels = {
    email_address = var.notification_channel_email
  }
  enabled = true
}

# -----------------------------------------------------------------------------------------
# Observability Metrics for Production Monitoring
# -----------------------------------------------------------------------------------------
module "http_4xx_errors" {
  source       = "../../../modules/observability/metrics"
  name         = "http_4xx_errors"
  filter       = <<-EOT
    resource.type="http_load_balancer"
    httpRequest.status>=400
    httpRequest.status<500
  EOT
  metric_kind  = "DELTA"
  value_type   = "INT64"
  display_name = "HTTP 4xx Errors"
  label_extractors = {
    "status_code" = "EXTRACT(httpRequest.status)"
    "url_map"     = "EXTRACT(resource.labels.url_map_name)"
  }
}

module "http_5xx_errors" {
  source       = "../../../modules/observability/metrics"
  name         = "http_5xx_errors"
  filter       = <<-EOT
    resource.type="http_load_balancer"
    httpRequest.status>=500
  EOT
  metric_kind  = "DELTA"
  value_type   = "INT64"
  display_name = "HTTP 5xx Errors"
  label_extractors = {
    "status_code" = "EXTRACT(httpRequest.status)"
    "url_map"     = "EXTRACT(resource.labels.url_map_name)"
  }
}

module "database_connection_errors" {
  source           = "../../../modules/observability/metrics"
  name             = "database_connection_errors"
  filter           = <<-EOT
    resource.type="cloudsql_database"
    (textPayload:"connection" OR textPayload:"timeout" OR textPayload:"failed")
    severity="ERROR"
  EOT
  metric_kind      = "DELTA"
  value_type       = "INT64"
  display_name     = "Database Connection Errors"
  label_extractors = {}
}

# Alerting Policies
module "high_error_rate_alert" {
  source                = "../../../modules/observability/alerts"
  display_name          = "High Error Rate Alert"
  combiner              = "OR"
  notification_channels = [google_monitoring_notification_channel.email_alerts.id]

  conditions = [
    {
      display_name    = "HTTP 5xx Error Rate"
      filter          = "resource.type=\"http_load_balancer\" AND httpRequest.status>=500"
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 10
      aggregations = {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  ]
}

module "database_connection_alert" {
  source                = "../../../modules/observability/alerts"
  display_name          = "Database Connection Alert"
  combiner              = "OR"
  notification_channels = [google_monitoring_notification_channel.email_alerts.id]

  conditions = [
    {
      display_name    = "Database Connection Errors"
      filter          = "resource.type=\"cloudsql_database\" AND severity=\"ERROR\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 5

      aggregations = {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  ]
}

# -----------------------------------------------------------------------------------------
# Additional Observability Metrics for Production Monitoring
# -----------------------------------------------------------------------------------------

# Cloud Run Performance Metrics
module "cloud_run_high_latency" {
  source       = "../../../modules/observability/metrics"
  name         = "cloud_run_high_latency"
  filter       = <<-EOT
    resource.type="cloud_run_revision"
    metric.type="run.googleapis.com/request_latencies"
  EOT
  metric_kind  = "DELTA"
  value_type   = "DISTRIBUTION"
  display_name = "Cloud Run High Latency Requests"
  label_extractors = {
    "service_name"  = "EXTRACT(resource.labels.service_name)"
    "revision_name" = "EXTRACT(resource.labels.revision_name)"
  }
}

module "cloud_run_container_cpu" {
  source       = "../../../modules/observability/metrics"
  name         = "cloud_run_container_cpu"
  filter       = <<-EOT
    resource.type="cloud_run_revision"
    metric.type="run.googleapis.com/container/cpu/utilizations"
  EOT
  metric_kind  = "GAUGE"
  value_type   = "DOUBLE"
  display_name = "Cloud Run Container CPU Utilization"
  label_extractors = {
    "service_name" = "EXTRACT(resource.labels.service_name)"
  }
}

module "cloud_run_container_memory" {
  source       = "../../../modules/observability/metrics"
  name         = "cloud_run_container_memory"
  filter       = <<-EOT
    resource.type="cloud_run_revision"
    metric.type="run.googleapis.com/container/memory/utilizations"
  EOT
  metric_kind  = "GAUGE"
  value_type   = "DOUBLE"
  display_name = "Cloud Run Container Memory Utilization"
  label_extractors = {
    "service_name" = "EXTRACT(resource.labels.service_name)"
  }
}

module "cloud_run_startup_latency" {
  source       = "../../../modules/observability/metrics"
  name         = "cloud_run_startup_latency"
  filter       = <<-EOT
    resource.type="cloud_run_revision"
    metric.type="run.googleapis.com/container/startup_latencies"
  EOT
  metric_kind  = "DELTA"
  value_type   = "DISTRIBUTION"
  display_name = "Cloud Run Container Startup Latency"
  label_extractors = {
    "service_name" = "EXTRACT(resource.labels.service_name)"
  }
}

# Database Performance Metrics
module "database_cpu_utilization" {
  source       = "../../../modules/observability/metrics"
  name         = "database_cpu_utilization"
  filter       = <<-EOT
    resource.type="cloudsql_database"
    metric.type="cloudsql.googleapis.com/database/cpu/utilization"
  EOT
  metric_kind  = "GAUGE"
  value_type   = "DOUBLE"
  display_name = "Cloud SQL CPU Utilization"
  label_extractors = {
    "database_id" = "EXTRACT(resource.labels.database_id)"
  }
}

module "database_memory_utilization" {
  source       = "../../../modules/observability/metrics"
  name         = "database_memory_utilization"
  filter       = <<-EOT
    resource.type="cloudsql_database"
    metric.type="cloudsql.googleapis.com/database/memory/utilization"
  EOT
  metric_kind  = "GAUGE"
  value_type   = "DOUBLE"
  display_name = "Cloud SQL Memory Utilization"
  label_extractors = {
    "database_id" = "EXTRACT(resource.labels.database_id)"
  }
}

module "database_disk_utilization" {
  source       = "../../../modules/observability/metrics"
  name         = "database_disk_utilization"
  filter       = <<-EOT
    resource.type="cloudsql_database"
    metric.type="cloudsql.googleapis.com/database/disk/utilization"
  EOT
  metric_kind  = "GAUGE"
  value_type   = "DOUBLE"
  display_name = "Cloud SQL Disk Utilization"
  label_extractors = {
    "database_id" = "EXTRACT(resource.labels.database_id)"
  }
}

module "database_active_connections" {
  source       = "../../../modules/observability/metrics"
  name         = "database_active_connections"
  filter       = <<-EOT
    resource.type="cloudsql_database"
    metric.type="cloudsql.googleapis.com/database/mysql/connections"
  EOT
  metric_kind  = "GAUGE"
  value_type   = "INT64"
  display_name = "Cloud SQL Active Connections"
  label_extractors = {
    "database_id" = "EXTRACT(resource.labels.database_id)"
  }
}

module "database_slow_queries" {
  source       = "../../../modules/observability/metrics"
  name         = "database_slow_queries"
  filter       = <<-EOT
    resource.type="cloudsql_database"
    (textPayload:"slow query" OR textPayload:"Query_time")
    severity>="WARNING"
  EOT
  metric_kind  = "DELTA"
  value_type   = "INT64"
  display_name = "Database Slow Queries"
  label_extractors = {
    "database_id" = "EXTRACT(resource.labels.database_id)"
  }
}

# Load Balancer Metrics
module "lb_request_count" {
  source       = "../../../modules/observability/metrics"
  name         = "lb_request_count"
  filter       = <<-EOT
    resource.type="http_load_balancer"
    httpRequest.requestMethod!=""
  EOT
  metric_kind  = "DELTA"
  value_type   = "INT64"
  display_name = "Load Balancer Request Count"
  label_extractors = {
    "url_map" = "EXTRACT(resource.labels.url_map_name)"
    "method"  = "EXTRACT(httpRequest.requestMethod)"
  }
}

module "lb_latency" {
  source       = "../../../modules/observability/metrics"
  name         = "lb_latency"
  filter       = <<-EOT
    resource.type="http_load_balancer"
    httpRequest.latency!=""
  EOT
  metric_kind  = "DELTA"
  value_type   = "DISTRIBUTION"
  display_name = "Load Balancer Latency"
  label_extractors = {
    "url_map" = "EXTRACT(resource.labels.url_map_name)"
  }
}

# Cloud Armor Security Metrics
module "cloud_armor_blocked_requests" {
  source       = "../../../modules/observability/metrics"
  name         = "cloud_armor_blocked_requests"
  filter       = <<-EOT
    resource.type="http_load_balancer"
    jsonPayload.enforcedSecurityPolicy.name!=""
    jsonPayload.enforcedSecurityPolicy.outcome="DENY"
  EOT
  metric_kind  = "DELTA"
  value_type   = "INT64"
  display_name = "Cloud Armor Blocked Requests"
  label_extractors = {
    "policy_name"   = "EXTRACT(jsonPayload.enforcedSecurityPolicy.name)"
    "rule_priority" = "EXTRACT(jsonPayload.enforcedSecurityPolicy.priority)"
  }
}

# Cloud Function Metrics
module "function_execution_count" {
  source       = "../../../modules/observability/metrics"
  name         = "function_execution_count"
  filter       = <<-EOT
    resource.type="cloud_function"
    metric.type="cloudfunctions.googleapis.com/function/execution_count"
  EOT
  metric_kind  = "DELTA"
  value_type   = "INT64"
  display_name = "Cloud Function Execution Count"
  label_extractors = {
    "function_name" = "EXTRACT(resource.labels.function_name)"
  }
}

module "function_execution_times" {
  source       = "../../../modules/observability/metrics"
  name         = "function_execution_times"
  filter       = <<-EOT
    resource.type="cloud_function"
    metric.type="cloudfunctions.googleapis.com/function/execution_times"
  EOT
  metric_kind  = "DELTA"
  value_type   = "DISTRIBUTION"
  display_name = "Cloud Function Execution Times"
  label_extractors = {
    "function_name" = "EXTRACT(resource.labels.function_name)"
  }
}

module "function_errors" {
  source       = "../../../modules/observability/metrics"
  name         = "function_errors"
  filter       = <<-EOT
    resource.type="cloud_function"
    severity="ERROR"
  EOT
  metric_kind  = "DELTA"
  value_type   = "INT64"
  display_name = "Cloud Function Errors"
  label_extractors = {
    "function_name" = "EXTRACT(resource.labels.function_name)"
  }
}

# Storage Metrics
module "gcs_request_count" {
  source       = "../../../modules/observability/metrics"
  name         = "gcs_request_count"
  filter       = <<-EOT
    resource.type="gcs_bucket"
    metric.type="storage.googleapis.com/api/request_count"
  EOT
  metric_kind  = "DELTA"
  value_type   = "INT64"
  display_name = "GCS Request Count"
  label_extractors = {
    "bucket_name" = "EXTRACT(resource.labels.bucket_name)"
    "method"      = "EXTRACT(metric.labels.method)"
  }
}

# Application-Level Metrics
module "application_errors" {
  source       = "../../../modules/observability/metrics"
  name         = "application_errors"
  filter       = <<-EOT
    resource.type="cloud_run_revision"
    severity="ERROR"
    (textPayload:"Exception" OR textPayload:"Error" OR jsonPayload.error!="")
  EOT
  metric_kind  = "DELTA"
  value_type   = "INT64"
  display_name = "Application Errors"
  label_extractors = {
    "service_name" = "EXTRACT(resource.labels.service_name)"
    "severity"     = "EXTRACT(severity)"
  }
}

# -----------------------------------------------------------------------------------------
# Enhanced Alerting Policies
# -----------------------------------------------------------------------------------------

# Cloud Run Performance Alerts
module "cloud_run_high_cpu_alert" {
  source                = "../../../modules/observability/alerts"
  display_name          = "Cloud Run High CPU Utilization"
  combiner              = "OR"
  notification_channels = [google_monitoring_notification_channel.email_alerts.id]

  conditions = [
    {
      display_name    = "CPU Utilization > 80%"
      filter          = "resource.type=\"cloud_run_revision\" AND metric.type=\"run.googleapis.com/container/cpu/utilizations\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.80

      aggregations = {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_MEAN"
        cross_series_reducer = "REDUCE_MEAN"
        group_by_fields      = ["resource.service_name"]
      }
    }
  ]
}

module "cloud_run_high_memory_alert" {
  source                = "../../../modules/observability/alerts"
  display_name          = "Cloud Run High Memory Utilization"
  combiner              = "OR"
  notification_channels = [google_monitoring_notification_channel.email_alerts.id]

  conditions = [
    {
      display_name    = "Memory Utilization > 85%"
      filter          = "resource.type=\"cloud_run_revision\" AND metric.type=\"run.googleapis.com/container/memory/utilizations\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.85

      aggregations = {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_MEAN"
        cross_series_reducer = "REDUCE_MEAN"
        group_by_fields      = ["resource.service_name"]
      }
    }
  ]
}

module "cloud_run_high_latency_alert" {
  source                = "../../../modules/observability/alerts"
  display_name          = "Cloud Run High Request Latency"
  combiner              = "OR"
  notification_channels = [google_monitoring_notification_channel.email_alerts.id]

  conditions = [
    {
      display_name    = "P95 Latency > 2 seconds"
      filter          = "resource.type=\"cloud_run_revision\" AND metric.type=\"run.googleapis.com/request_latencies\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 2000

      aggregations = {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_DELTA"
        cross_series_reducer = "REDUCE_PERCENTILE_95"
        group_by_fields      = ["resource.service_name"]
      }
    }
  ]
}

# Database Alerts
module "database_high_cpu_alert" {
  source                = "../../../modules/observability/alerts"
  display_name          = "Database High CPU Utilization"
  combiner              = "OR"
  notification_channels = [google_monitoring_notification_channel.email_alerts.id]

  conditions = [
    {
      display_name    = "CPU Utilization > 80%"
      filter          = "resource.type=\"cloudsql_database\" AND metric.type=\"cloudsql.googleapis.com/database/cpu/utilization\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.80

      aggregations = {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  ]
}

module "database_high_memory_alert" {
  source                = "../../../modules/observability/alerts"
  display_name          = "Database High Memory Utilization"
  combiner              = "OR"
  notification_channels = [google_monitoring_notification_channel.email_alerts.id]

  conditions = [
    {
      display_name    = "Memory Utilization > 85%"
      filter          = "resource.type=\"cloudsql_database\" AND metric.type=\"cloudsql.googleapis.com/database/memory/utilization\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.85

      aggregations = {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  ]
}

module "database_high_disk_alert" {
  source                = "../../../modules/observability/alerts"
  display_name          = "Database High Disk Utilization"
  combiner              = "OR"
  notification_channels = [google_monitoring_notification_channel.email_alerts.id]

  conditions = [
    {
      display_name    = "Disk Utilization > 80%"
      filter          = "resource.type=\"cloudsql_database\" AND metric.type=\"cloudsql.googleapis.com/database/disk/utilization\""
      duration        = "600s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.80

      aggregations = {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  ]
}

module "database_connection_pool_alert" {
  source                = "../../../modules/observability/alerts"
  display_name          = "Database Connection Pool Near Limit"
  combiner              = "OR"
  notification_channels = [google_monitoring_notification_channel.email_alerts.id]

  conditions = [
    {
      display_name    = "Active Connections > 800 (80% of max 1000)"
      filter          = "resource.type=\"cloudsql_database\" AND metric.type=\"cloudsql.googleapis.com/database/mysql/connections\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 800

      aggregations = {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  ]
}

module "database_slow_queries_alert" {
  source                = "../../../modules/observability/alerts"
  display_name          = "Database Slow Queries Detected"
  combiner              = "OR"
  notification_channels = [google_monitoring_notification_channel.email_alerts.id]

  conditions = [
    {
      display_name    = "Slow Query Rate > 10/min"
      filter          = "resource.type=\"cloudsql_database\" AND (textPayload:\"slow query\" OR textPayload:\"Query_time\") AND severity>=\"WARNING\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 10

      aggregations = {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  ]
}

# Load Balancer Alerts
module "lb_high_latency_alert" {
  source                = "../../../modules/observability/alerts"
  display_name          = "Load Balancer High Latency"
  combiner              = "OR"
  notification_channels = [google_monitoring_notification_channel.email_alerts.id]

  conditions = [
    {
      display_name    = "P95 Latency > 3 seconds"
      filter          = "resource.type=\"http_load_balancer\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 3000

      aggregations = {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_DELTA"
        cross_series_reducer = "REDUCE_PERCENTILE_95"
        group_by_fields      = ["resource.url_map_name"]
      }
    }
  ]
}

module "http_4xx_rate_alert" {
  source                = "../../../modules/observability/alerts"
  display_name          = "High 4xx Error Rate"
  combiner              = "OR"
  notification_channels = [google_monitoring_notification_channel.email_alerts.id]

  conditions = [
    {
      display_name    = "4xx Error Rate > 5%"
      filter          = "resource.type=\"http_load_balancer\" AND httpRequest.status>=400 AND httpRequest.status<500"
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.05

      aggregations = {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_RATE"
        cross_series_reducer = "REDUCE_SUM"
      }
    }
  ]
}

# Security Alerts
module "cloud_armor_high_block_rate_alert" {
  source                = "../../../modules/observability/alerts"
  display_name          = "Cloud Armor High Block Rate"
  combiner              = "OR"
  notification_channels = [google_monitoring_notification_channel.email_alerts.id]

  conditions = [
    {
      display_name    = "Blocked Requests > 100/min"
      filter          = "resource.type=\"http_load_balancer\" AND jsonPayload.enforcedSecurityPolicy.outcome=\"DENY\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 100

      aggregations = {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  ]
}

# Cloud Function Alerts
module "function_error_rate_alert" {
  source                = "../../../modules/observability/alerts"
  display_name          = "Cloud Function High Error Rate"
  combiner              = "OR"
  notification_channels = [google_monitoring_notification_channel.email_alerts.id]

  conditions = [
    {
      display_name    = "Function Error Rate > 5%"
      filter          = "resource.type=\"cloud_function\" AND severity=\"ERROR\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.05

      aggregations = {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_RATE"
        cross_series_reducer = "REDUCE_SUM"
        group_by_fields      = ["resource.function_name"]
      }
    }
  ]
}

module "function_execution_time_alert" {
  source                = "../../../modules/observability/alerts"
  display_name          = "Cloud Function High Execution Time"
  combiner              = "OR"
  notification_channels = [google_monitoring_notification_channel.email_alerts.id]

  conditions = [
    {
      display_name    = "P95 Execution Time > 30 seconds"
      filter          = "resource.type=\"cloud_function\" AND metric.type=\"cloudfunctions.googleapis.com/function/execution_times\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 30000

      aggregations = {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_DELTA"
        cross_series_reducer = "REDUCE_PERCENTILE_95"
        group_by_fields      = ["resource.function_name"]
      }
    }
  ]
}

# Uptime Check Alerts
# module "frontend_uptime_alert" {
#   source                = "../../../modules/observability/alerts"
#   display_name          = "Frontend Service Down"
#   combiner              = "OR"
#   notification_channels = [google_monitoring_notification_channel.email_alerts.id]

#   conditions = [
#     {
#       display_name    = "Uptime Check Failed"
#       filter          = "metric.type=\"monitoring.googleapis.com/uptime_check/check_passed\" AND resource.label.check_id=\"${module.frontend_uptime_check.uptime_check_id}\""
#       duration        = "300s"
#       comparison      = "COMPARISON_LT"
#       threshold_value = 1

#       aggregations = {
#         alignment_period   = "60s"
#         per_series_aligner = "ALIGN_NEXT_OLDER"
#       }
#     }
#   ]
# }

# module "backend_uptime_alert" {
#   source                = "../../../modules/observability/alerts"
#   display_name          = "Backend Service Down"
#   combiner              = "OR"
#   notification_channels = [google_monitoring_notification_channel.email_alerts.id]

#   conditions = [
#     {
#       display_name    = "Uptime Check Failed"
#       filter          = "metric.type=\"monitoring.googleapis.com/uptime_check/check_passed\" AND resource.label.check_id=\"${module.backend_uptime_check.uptime_check_id}\""
#       duration        = "300s"
#       comparison      = "COMPARISON_LT"
#       threshold_value = 1

#       aggregations = {
#         alignment_period   = "60s"
#         per_series_aligner = "ALIGN_NEXT_OLDER"
#       }
#     }
#   ]
# }

# Application-Level Alert
module "application_error_spike_alert" {
  source                = "../../../modules/observability/alerts"
  display_name          = "Application Error Spike"
  combiner              = "OR"
  notification_channels = [google_monitoring_notification_channel.email_alerts.id]

  conditions = [
    {
      display_name    = "Error Rate Spike > 20/min"
      filter          = "resource.type=\"cloud_run_revision\" AND severity=\"ERROR\""
      duration        = "180s"
      comparison      = "COMPARISON_GT"
      threshold_value = 20

      aggregations = {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_RATE"
        cross_series_reducer = "REDUCE_SUM"
        group_by_fields      = ["resource.service_name"]
      }
    }
  ]
}
