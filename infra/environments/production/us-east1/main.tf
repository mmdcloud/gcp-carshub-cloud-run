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
  vpc_name                        = "carshub-vpc-${var.environment}"
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
      name          = "carshub-connector-${var.environment}"
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
  account_id    = "carshub-function-app-sa-${var.environment}"
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
  account_id    = "carshub-cloudbuild-sa-${var.environment}"
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
  account_id    = "carshub-cloud-run-sa-${var.environment}"
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
# module "cloud_armor" {
#   source  = "GoogleCloudPlatform/cloud-armor/google"
#   version = "~> 5.0"

#   project_id  = data.google_project.project.project_id
#   name        = "carshub-security-policy"
#   description = "CarHub Cloud Armor security policy with WAF rules"

#   default_rule_action = "allow"
#   type                = "CLOUD_ARMOR"

#   layer_7_ddos_defense_enable          = true
#   layer_7_ddos_defense_rule_visibility = "STANDARD"
#   user_ip_request_headers              = ["True-Client-IP"]

#   security_rules = {
#     "rate_limit_rule" = {
#       action        = "rate_based_ban"
#       priority      = 1
#       description   = "Rate limiting rule"
#       src_ip_ranges = ["*"]

#       rate_limit_options = {
#         conform_action = "allow"
#         exceed_action  = "deny(429)"
#         enforce_on_key = "IP"
#         ban_duration_sec = 600

#         # Correct field names for module v5.x
#         rate_limit_http_request_count        = 100
#         rate_limit_http_request_interval_sec = 60
#         ban_http_request_count               = 1000
#         ban_http_request_interval_sec        = 600
#       }

#       match = {
#         versioned_expr = "SRC_IPS_V1"
#         config = {
#           src_ip_ranges = ["*"]
#         }
#       }
#     }
#   }

#   # geo_blocking uses CEL expression — must live in custom_rules, not security_rules
#   custom_rules = {
#     "geo_blocking" = {
#       action      = "deny(403)"
#       priority    = 10
#       description = "Block traffic from specific countries"
#       expression  = "origin.region_code in ['CN', 'RU']"
#     }
#   }

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

#     "lfi-stable_level_2" = {
#       action            = "deny(403)"
#       priority          = 4
#       target_rule_set   = "lfi-v33-stable"
#       sensitivity_level = 2
#     }

#     "rce-stable_level_2" = {
#       action            = "deny(403)"
#       priority          = 5
#       target_rule_set   = "rce-v33-stable"
#       sensitivity_level = 2
#     }

#     "rfi-stable_level_2" = {
#       action            = "deny(403)"
#       priority          = 6
#       target_rule_set   = "rfi-v33-stable"
#       sensitivity_level = 2
#     }

#     "scannerdetection-stable_level_2" = {
#       action            = "deny(403)"
#       priority          = 7
#       target_rule_set   = "scannerdetection-v33-stable"
#       sensitivity_level = 2
#     }

#     "protocolattack-stable_level_2" = {
#       action            = "deny(403)"
#       priority          = 8
#       target_rule_set   = "protocolattack-v33-stable"
#       sensitivity_level = 2
#     }

#     "sessionfixation-stable_level_2" = {
#       action            = "deny(403)"
#       priority          = 9
#       target_rule_set   = "sessionfixation-v33-stable"
#       sensitivity_level = 2
#     }
#   }
# }

# -----------------------------------------------------------------------------------------
# SECURITY: SSL/TLS Configuration
# -----------------------------------------------------------------------------------------
resource "google_compute_managed_ssl_certificate" "carshub_frontend_ssl_cert" {
  name = "carshub-frontend-ssl-cert-${var.environment}"
  managed {
    domains = ["carshub-frontend.${var.domain}"]
  }
}

resource "google_compute_managed_ssl_certificate" "carshub_backend_ssl_cert" {
  name = "carshub-backend-ssl-cert-${var.environment}"
  managed {
    domains = ["carshub-api.${var.domain}"]
  }
}

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
  topic  = "carshub-media-bucket-events-${var.environment}"
}

# -----------------------------------------------------------------------------------------
# Artifact Registry Configuration
# -----------------------------------------------------------------------------------------
module "carshub_frontend_artifact_registry" {
  source        = "../../../modules/artifact-registry"
  location      = var.location
  description   = "CarHub frontend repository"
  repository_id = "carshub-frontend-${var.environment}"
  depends_on    = [module.carshub_backend_service, module.carshub_apis]
}

resource "null_resource" "build_and_push_frontend" {
  provisioner "local-exec" {
    command = "bash ${path.cwd}/../../../../src/frontend/artifact_push.sh http://${module.carshub_backend_service_lb.ip_address} ${module.carshub_cdn.cdn_ip_address} ${data.google_project.project.project_id} ${var.environment}"
  }

  depends_on = [
    module.carshub_frontend_artifact_registry,
  ]
}

module "carshub_backend_artifact_registry" {
  source        = "../../../modules/artifact-registry"
  location      = var.location
  description   = "CarHub backend repository"
  repository_id = "carshub-backend-${var.environment}"
  depends_on    = [module.carshub_db, module.carshub_apis]
}

resource "null_resource" "build_and_push_backend" {
  provisioner "local-exec" {
    command = "bash ${path.cwd}/../../../../src/backend/api/artifact_push.sh ${data.google_project.project.project_id} ${var.environment}"
  }

  depends_on = [
    module.carshub_backend_artifact_registry,
  ]
}

# -----------------------------------------------------------------------------------------
# Google Cloud Storage (GCS) Configuration
# -----------------------------------------------------------------------------------------
module "carshub_media_bucket" {
  source   = "../../../modules/gcs"
  location = var.location
  name     = "carshub-media-${var.environment}"
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
  name     = "carshub-media-code-${var.environment}"
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
# resource "google_storage_bucket_iam_member" "cdn_sa_access" {
#   bucket = module.carshub_media_bucket.bucket_name
#   role   = "roles/storage.objectViewer"
#   member = "serviceAccount:service-${data.google_project.project.number}@cloud-cdn-fill.iam.gserviceaccount.com"

#   # ✅ CRITICAL: Wait for backend to create the service account
#   depends_on = [
#     google_compute_backend_bucket.media_backend
#   ]
# }

# resource "google_storage_bucket_iam_member" "backend_access" {
#   bucket = module.carshub_media_bucket.bucket_name
#   role   = "roles/storage.objectAdmin"
#   member = "serviceAccount:${module.carshub_cloud_run_service_account.sa_email}"
# }

resource "google_storage_bucket_iam_binding" "storage_iam_binding" {
  bucket = module.carshub_media_bucket.bucket_name
  role   = "roles/storage.objectViewer"

  members = [
    "allUsers"
  ]
}

# -----------------------------------------------------------------------------------------
# CDN Configuration
# -----------------------------------------------------------------------------------------
module "carshub_cdn" {
  source                = "../../../modules/cdn"
  bucket_name           = module.carshub_media_bucket.bucket_name
  enable_cdn            = true
  description           = "Content delivery network for media files"
  name                  = "carshub-media-cdn-${var.environment}"
  forwarding_port_range = "80"
  forwarding_rule_name  = "carshub-cdn-global-forwarding-rule-${var.environment}"
  forwarding_scheme     = "EXTERNAL"
  global_address_type   = "EXTERNAL"
  url_map_name          = "carshub-cdn-compute-url-map-${var.environment}"
  global_address_name   = "carshub-cdn-lb-global-address-${var.environment}"
  target_proxy_name     = "carshub-cdn-target-proxy-${var.environment}"
}

# -----------------------------------------------------------------------------------------
# Secret Manager Configuration
# -----------------------------------------------------------------------------------------
module "carshub_sql_password_secret" {
  source      = "../../../modules/secret-manager"
  secret_data = tostring(data.vault_generic_secret.sql.data["password"])
  secret_id   = "carshub-db-password-secret-${var.environment}"
  depends_on  = [module.carshub_apis]
}

module "carshub_sql_username_secret" {
  source      = "../../../modules/secret-manager"
  secret_data = tostring(data.vault_generic_secret.sql.data["username"])
  secret_id   = "carshub-db-username-secret-${var.environment}"
  depends_on  = [module.carshub_apis]
}

# -----------------------------------------------------------------------------------------
# Cloud SQL Configuration
# -----------------------------------------------------------------------------------------
module "carshub_db" {
  source                      = "../../../modules/cloud-sql"
  name                        = "carshub-db-instance-${var.environment}"
  db_name                     = "carshub-${var.environment}"
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
  name                             = "carshub-frontend-service-${var.environment}"
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
      image             = "${var.location}-docker.pkg.dev/${data.google_project.project.project_id}/carshub-frontend/carshub-frontend-${var.environment}:latest"
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
  name = "carshub-backend-service-${var.environment}"
  traffic = [
    {
      traffic_type         = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
      traffic_type_percent = 100
    }
  ]
  containers = [
    {
      image             = "${var.location}-docker.pkg.dev/${data.google_project.project.project_id}/carshub-backend/carshub-backend-${var.environment}:latest"
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
  function_name                = "carshub-media-function-${var.environment}"
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
  neg_name     = "carshub-frontend-service-neg-${var.environment}"
  neg_type     = "SERVERLESS"
  location     = var.location
  service_name = module.carshub_frontend_service.name
}

module "carshub_backend_service_neg" {
  source       = "../../../modules/network_endpoint_groups"
  neg_name     = "carshub-backend-service-neg-${var.environment}"
  neg_type     = "SERVERLESS"
  location     = var.location
  service_name = module.carshub_backend_service.name
}

# -----------------------------------------------------------------------------------------
# Load Balancer Configuration
# -----------------------------------------------------------------------------------------
module "carshub_frontend_service_lb" {
  source                   = "../../../modules/load-balancer"
  forwarding_port_range    = "443"
  forwarding_rule_name     = "carshub-frontend-service-global-forwarding-rule-${var.environment}"
  forwarding_scheme        = "EXTERNAL"
  global_address_type      = "EXTERNAL"
  url_map_name             = "carshub-frontend-service-compute-url-map-${var.environment}"
  global_address_name      = "carshub-frontend-service-lb-global-address-${var.environment}"
  target_proxy_name        = "carshub-frontend-service-target-proxy-${var.environment}"
  backend_service_name     = "carshub-frontend-compute-${var.environment}"
  backend_service_protocol = "HTTP"
  backend_service_timeout  = 30
  # security_policy          = module.cloud_armor.policy.id
  ssl_certificates = [google_compute_managed_ssl_certificate.carshub_frontend_ssl_cert.id]
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
  forwarding_rule_name     = "carshub-backend-service-global-forwarding-rule-${var.environment}"
  forwarding_scheme        = "EXTERNAL"
  global_address_type      = "EXTERNAL"
  url_map_name             = "carshub-backend-service-compute-url-map-${var.environment}"
  global_address_name      = "carshub-backend-service-lb-global-address-${var.environment}"
  target_proxy_name        = "carshub-backend-service-target-proxy-${var.environment}"
  backend_service_name     = "carshub-backend-compute-${var.environment}"
  backend_service_protocol = "HTTP"
  backend_service_timeout  = 30
  # security_policy          = module.cloud_armor.policy.id
  ssl_certificates = [google_compute_managed_ssl_certificate.carshub_backend_ssl_cert.id]
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
    "url_map" = "EXTRACT(resource.labels.url_map_name)"
  }
}

# HTTP 5xx errors
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
    "url_map" = "EXTRACT(resource.labels.url_map_name)"
  }
}

# Database connection errors (log-based)
module "database_connection_errors" {
  source           = "../../../modules/observability/metrics"
  name             = "database_connection_errors"
  filter           = <<-EOT
    resource.type="cloudsql_database"
    severity="ERROR"
    textPayload:"connection"
  EOT
  metric_kind      = "DELTA"
  value_type       = "INT64"
  display_name     = "Database Connection Errors"
  label_extractors = {}
}

# Database slow queries (log-based — textPayload OR not allowed, use two separate filters or single match)
module "database_slow_queries" {
  source       = "../../../modules/observability/metrics"
  name         = "database_slow_queries"
  filter       = <<-EOT
    resource.type="cloudsql_database"
    severity>="WARNING"
    textPayload:"Query_time"
  EOT
  metric_kind  = "DELTA"
  value_type   = "INT64"
  display_name = "Database Slow Queries"
  label_extractors = {
    "database_id" = "EXTRACT(resource.labels.database_id)"
  }
}

# Cloud Armor blocked requests (log-based)
module "cloud_armor_blocked_requests" {
  source       = "../../../modules/observability/metrics"
  name         = "cloud_armor_blocked_requests"
  filter       = <<-EOT
    resource.type="http_load_balancer"
    jsonPayload.enforcedSecurityPolicy.outcome="DENY"
  EOT
  metric_kind  = "DELTA"
  value_type   = "INT64"
  display_name = "Cloud Armor Blocked Requests"
  label_extractors = {
    "policy_name" = "EXTRACT(jsonPayload.enforcedSecurityPolicy.name)"
  }
}

# Application errors (log-based)
module "application_errors" {
  source       = "../../../modules/observability/metrics"
  name         = "application_errors"
  filter       = <<-EOT
    resource.type="cloud_run_revision"
    severity="ERROR"
  EOT
  metric_kind  = "DELTA"
  value_type   = "INT64"
  display_name = "Application Errors"
  label_extractors = {
    "service_name" = "EXTRACT(resource.labels.service_name)"
  }
}

# Cloud Function errors (log-based)
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

# LB request count (log-based)
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
  }
}

# NOTE: The following modules were REMOVED because they wrap native GCP metrics
# inside google_logging_metric which is invalid — they don't exist in logs:
#   cloud_run_container_cpu, cloud_run_container_memory, cloud_run_startup_latency,
#   cloud_run_high_latency, database_cpu_utilization, database_memory_utilization,
#   database_disk_utilization, database_active_connections, function_execution_count,
#   function_execution_times, gcs_request_count, lb_latency, database_connection_pool_alert
# These are queried directly via metric.type in alert policies below.

# -----------------------------------------------------------------------------------------
# Alert Policies
# -----------------------------------------------------------------------------------------

# Cloud Run — CPU (native metric, GAUGE/DISTRIBUTION → ALIGN_PERCENTILE_99)
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
        per_series_aligner   = "ALIGN_PERCENTILE_99"
        cross_series_reducer = "REDUCE_MEAN"
        group_by_fields      = ["resource.labels.service_name"]
      }
    }
  ]
}

# Cloud Run — Memory (native metric, GAUGE/DISTRIBUTION → ALIGN_PERCENTILE_99)
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
        per_series_aligner   = "ALIGN_PERCENTILE_99"
        cross_series_reducer = "REDUCE_MEAN"
        group_by_fields      = ["resource.labels.service_name"]
      }
    }
  ]
}

# Cloud Run — Latency (DELTA/DISTRIBUTION → must use ALIGN_PERCENTILE_95)
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
        per_series_aligner   = "ALIGN_PERCENTILE_95"
        cross_series_reducer = "REDUCE_MEAN"
        group_by_fields      = ["resource.labels.service_name"]
      }
    }
  ]
}

# Database — CPU
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

# Database — Memory
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

# Database — Disk
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

# Database — Connection pool (correct metric type for PostgreSQL; swap for mysql_connections if MySQL)
module "database_connection_pool_alert" {
  source                = "../../../modules/observability/alerts"
  display_name          = "Database Connection Pool Near Limit"
  combiner              = "OR"
  notification_channels = [google_monitoring_notification_channel.email_alerts.id]

  conditions = [
    {
      display_name    = "Active Connections > 800"
      filter          = "resource.type=\"cloudsql_database\" AND metric.type=\"cloudsql.googleapis.com/database/postgresql/num_backends\""
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

# Database — Slow queries (alert on log-based metric created above)
module "database_slow_queries_alert" {
  source                = "../../../modules/observability/alerts"
  display_name          = "Database Slow Queries Detected"
  combiner              = "OR"
  notification_channels = [google_monitoring_notification_channel.email_alerts.id]

  conditions = [
    {
      display_name    = "Slow Query Rate > 10/min"
      filter          = "metric.type=\"logging.googleapis.com/user/database_slow_queries\" AND resource.type=\"cloudsql_database\""
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

# LB — Latency (correct resource type is https_lb_rule, metric is DELTA/DISTRIBUTION)
module "lb_high_latency_alert" {
  source                = "../../../modules/observability/alerts"
  display_name          = "Load Balancer High Latency"
  combiner              = "OR"
  notification_channels = [google_monitoring_notification_channel.email_alerts.id]

  conditions = [
    {
      display_name    = "P95 Latency > 3 seconds"
      filter          = "resource.type=\"https_lb_rule\" AND metric.type=\"loadbalancing.googleapis.com/https/total_latencies\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 3000

      aggregations = {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_PERCENTILE_95"
        cross_series_reducer = "REDUCE_MEAN"
        group_by_fields      = ["resource.labels.url_map_name"]
      }
    }
  ]
}

# LB — 4xx rate (alert on log-based metric)
module "http_4xx_rate_alert" {
  source                = "../../../modules/observability/alerts"
  display_name          = "High 4xx Error Rate"
  combiner              = "OR"
  notification_channels = [google_monitoring_notification_channel.email_alerts.id]
  conditions = [
    {
      display_name    = "4xx Error Rate > 50/min"
      filter          = "metric.type=\"logging.googleapis.com/user/http_4xx_errors\" AND resource.type=\"l7_lb_rule\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 50
      aggregations = {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  ]
  depends_on = [module.http_4xx_errors]
}

# LB — 5xx / high error rate (alert on log-based metric)
module "high_error_rate_alert" {
  source                = "../../../modules/observability/alerts"
  display_name          = "High Error Rate Alert"
  combiner              = "OR"
  notification_channels = [google_monitoring_notification_channel.email_alerts.id]
  conditions = [
    {
      display_name    = "HTTP 5xx Error Rate > 10/min"
      filter          = "metric.type=\"logging.googleapis.com/user/http_5xx_errors\" AND resource.type=\"l7_lb_rule\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 10
      aggregations = {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  ]
  depends_on = [module.http_5xx_errors]
}

# Cloud Armor — high block rate (alert on log-based metric)
# module "cloud_armor_high_block_rate_alert" {
#   source                = "../../../modules/observability/alerts"
#   display_name          = "Cloud Armor High Block Rate"
#   combiner              = "OR"
#   notification_channels = [google_monitoring_notification_channel.email_alerts.id]

#   conditions = [
#     {
#       display_name    = "Blocked Requests > 100/min"
#       filter          = "metric.type=\"logging.googleapis.com/user/cloud_armor_blocked_requests\" AND resource.type=\"http_load_balancer\""
#       duration        = "300s"
#       comparison      = "COMPARISON_GT"
#       threshold_value = 100

#       aggregations = {
#         alignment_period   = "60s"
#         per_series_aligner = "ALIGN_RATE"
#       }
#     }
#   ]
# }

# Database — connection errors (alert on log-based metric)
module "database_connection_alert" {
  source                = "../../../modules/observability/alerts"
  display_name          = "Database Connection Alert"
  combiner              = "OR"
  notification_channels = [google_monitoring_notification_channel.email_alerts.id]

  conditions = [
    {
      display_name    = "Database Connection Errors > 5/min"
      filter          = "metric.type=\"logging.googleapis.com/user/database_connection_errors\" AND resource.type=\"cloudsql_database\""
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

# Cloud Function — error rate (alert on log-based metric)
module "function_error_rate_alert" {
  source                = "../../../modules/observability/alerts"
  display_name          = "Cloud Function High Error Rate"
  combiner              = "OR"
  notification_channels = [google_monitoring_notification_channel.email_alerts.id]
  conditions = [
    {
      display_name    = "Function Error Rate > 5/min"
      filter          = "metric.type=\"logging.googleapis.com/user/function_errors\" AND resource.type=\"cloud_function\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 5
      aggregations = {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_RATE"
        cross_series_reducer = "REDUCE_SUM"
        group_by_fields      = ["resource.labels.function_name"]
      }
    }
  ]
  depends_on = [module.function_errors]
}

# Cloud Function — execution time (DELTA/DISTRIBUTION → ALIGN_PERCENTILE_95)
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
        per_series_aligner   = "ALIGN_PERCENTILE_95"
        cross_series_reducer = "REDUCE_MEAN"
        group_by_fields      = ["resource.labels.function_name"]
      }
    }
  ]
}

# Application error spike (alert on log-based metric)
module "application_error_spike_alert" {
  source                = "../../../modules/observability/alerts"
  display_name          = "Application Error Spike"
  combiner              = "OR"
  notification_channels = [google_monitoring_notification_channel.email_alerts.id]

  conditions = [
    {
      display_name    = "Error Rate Spike > 20/min"
      filter          = "metric.type=\"logging.googleapis.com/user/application_errors\" AND resource.type=\"cloud_run_revision\""
      duration        = "180s"
      comparison      = "COMPARISON_GT"
      threshold_value = 20

      aggregations = {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_RATE"
        cross_series_reducer = "REDUCE_SUM"
        group_by_fields      = ["resource.labels.service_name"]
      }
    }
  ]
}