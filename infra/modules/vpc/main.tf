# VPC
resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = var.auto_create_subnetworks
}

# Subnets
resource "google_compute_subnetwork" "subnet" {
  count         = length(var.subnets)
  name          = element(var.subnets[*].name, count.index)
  ip_cidr_range = element(var.subnets[*].ip_cidr_range, count.index)
  region        = var.location
  private_ip_google_access = var.private_ip_google_access
  network       = google_compute_network.vpc.id
}

# allow access from health check ranges
resource "google_compute_firewall" "carshub_firewall" {
  count         = length(var.firewall_data)
  name          = element(var.firewall_data[*].firewall_name, count.index)
  direction     = element(var.firewall_data[*].firewall_direction, count.index)
  network       = google_compute_network.vpc.id
  source_ranges = element(var.firewall_data[*].source_ranges, count.index)
  dynamic "allow" {
    # for_each = var.firewall_data[*].allow_list
    for_each = flatten([for data in var.firewall_data : data.allow_list])
    content {
      ports    = allow.value["ports"]
      protocol = allow.value["protocol"]
    }
  }
  target_tags = element(var.firewall_data[*].target_tags, count.index)
}
