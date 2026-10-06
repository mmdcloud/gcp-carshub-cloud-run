resource "google_compute_region_network_endpoint_group" "neg" {
  name                  = var.neg_name
  description           = var.description
  network_endpoint_type = var.neg_type
  region                = var.location
  network               = var.network
  subnetwork            = var.subnetwork

  dynamic "psc_data" {
    for_each = var.psc_data != null ? [var.psc_data] : []
    content {
      producer_port = psc_data.value.producer_port
    }
  }

  psc_target_service = var.psc_target_service
}