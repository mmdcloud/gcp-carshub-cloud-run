resource "google_compute_region_network_endpoint_group" "neg" {
  name                  = var.neg_name
  description           = var.description
  network_endpoint_type = var.neg_type
  region                = var.location
  network               = var.network
  subnetwork            = var.subnetwork
}