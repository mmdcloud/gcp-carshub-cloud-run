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
    scaling {
      max_instance_count = var.max_instance_count
    }
    dynamic "volumes" {
      for_each = var.volumes
      content {
        name = volumes.value["name"]
        cloud_sql_instance {
          instances = volumes.value["cloud_sql_instance"] 
        }
        # dynamic "cloud_sql_instance" {
        #   for_each = volumes.value["cloud_sql_instance"]
        #   content {
        #     instances = volumes.value["cloud_sql_instance"].value
        #   }
        # }
      }
    }
    containers {
      image = var.image
      ports {
        container_port = local.port
      }
      dynamic "volume_mounts" {
        for_each = var.volume_mounts
        content {
          name       = volume_mounts.value["name"]
          mount_path = volume_mounts.value["mount_path"]
        }
      }
      dynamic "env" {
        for_each = var.env
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

  traffic {
    type    = var.traffic_type
    percent = var.traffic_type_percent
  }
}
