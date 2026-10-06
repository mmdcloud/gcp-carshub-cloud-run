resource "google_compute_region_network_endpoint_group" "neg" {
  name                  = var.neg_name
  description           = var.description
  network_endpoint_type = "SERVERLESS"
  region                = var.location
  network               = var.network
  subnetwork            = var.subnetwork

  dynamic "cloud_run" {
    for_each = var.cloud_run != null ? [var.cloud_run] : []
    content {
      service  = cloud_run.value.service
      tag      = cloud_run.value.tag
      url_mask = cloud_run.value.url_mask
    }
  }

  dynamic "cloud_function" {
    for_each = var.cloud_function != null ? [var.cloud_function] : []
    content {
      function = cloud_function.value.function
      url_mask = cloud_function.value.url_mask
    }
  }

  dynamic "app_engine" {
    for_each = var.app_engine != null ? [var.app_engine] : []
    content {
      service  = app_engine.value.service
      version  = app_engine.value.version
      url_mask = app_engine.value.url_mask
    }
  }
}