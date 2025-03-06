resource "google_compute_region_network_endpoint_group" "serverless_neg" {
  name                  = var.neg_name
  network_endpoint_type = var.neg_type
  region                = var.location
  
  cloud_run {
    service = var.service_name
  }
}