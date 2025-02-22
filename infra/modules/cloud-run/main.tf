data "google_project" "project" {}
locals {
  port = 3000
}
resource "google_cloud_run_v2_service" "cloud_run_service" {
  name                = var.name
  location            = var.location
  deletion_protection = var.deletion_protection
  ingress             = var.ingress

  template {
    service_account = var.service_account
    scaling {
      max_instance_count = var.max_instance_count
      min_instance_count = var.min_instance_count
    }
    dynamic "volumes" {
      for_each = var.volumes
      content {
        name = volumes.value["name"]
        cloud_sql_instance {
          instances = volumes.value["cloud_sql_instance"]
        }
      }
    }
    vpc_access {
      connector = var.vpc_connector_name
      egress    = "ALL_TRAFFIC"
    }
    dynamic "containers" {
      for_each = var.containers
      content {
        image = containers.value["image"]
        ports {
          container_port = local.port
        }
        dynamic "volume_mounts" {
          for_each = containers.value["volume_mounts"]
          content {
            name       = volume_mounts.value["name"]
            mount_path = volume_mounts.value["mount_path"]
          }
        }
        dynamic "env" {
          for_each = containers.value["env"]
          content {
            name  = env.value["name"]
            value = env.value["value"]
            dynamic "value_source" {
              for_each = env.value["value_source"]
              content {
                dynamic "secret_key_ref" {
                  for_each = value_source.value["secret_key_ref"]
                  content {
                    secret  = secret_key_ref.value["secret"]
                    version = secret_key_ref.value["version"]
                  }
                }
              }
            }
          }
        }
      }
    }
  }
  dynamic "traffic" {
    for_each = var.traffic
    content {
      type    = traffic.value["traffic_type"]
      percent = traffic.value["traffic_type_percent"]
    }
  }
}
