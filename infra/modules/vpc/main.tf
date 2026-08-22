resource "google_compute_network" "vpc" {
  name                            = var.vpc_name
  delete_default_routes_on_create = var.delete_default_routes_on_create
  auto_create_subnetworks         = var.auto_create_subnetworks
  routing_mode                    = var.routing_mode
}

resource "google_compute_subnetwork" "subnets" {
  count                    = length(var.subnets)
  name                     = var.subnets[count.index].name
  ip_cidr_range            = var.subnets[count.index].ip_cidr_range
  region                   = var.subnets[count.index].region
  network                  = google_compute_network.vpc.id
  private_ip_google_access = var.subnets[count.index].private_ip_google_access
  purpose                  = var.subnets[count.index].purpose
  role                     = var.subnets[count.index].role
}

resource "google_compute_firewall" "firewall" {
  for_each = { for fw in var.firewall_data : fw.name => fw }

  name        = each.value.name
  network     = google_compute_network.vpc.id
  description = try(each.value.description, null)
  priority    = try(each.value.priority, 1000)

  source_ranges      = try(each.value.source_ranges, null)
  source_tags        = try(each.value.source_tags, null)
  destination_ranges = try(each.value.destination_ranges, null)
  target_tags        = try(each.value.target_tags, null)

  dynamic "allow" {
    for_each = try(each.value.allow_list, [])
    content {
      protocol = allow.value.protocol
      ports    = try(allow.value.ports, null)
    }
  }

  dynamic "deny" {
    for_each = try(each.value.deny_list, [])
    content {
      protocol = deny.value.protocol
      ports    = try(deny.value.ports, null)
    }
  }
}
