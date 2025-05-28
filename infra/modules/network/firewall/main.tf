resource "google_compute_firewall" "carshub_firewall" {
  count         = length(var.firewall_data)
  name          = element(var.firewall_data[*].firewall_name, count.index)
  direction     = element(var.firewall_data[*].firewall_direction, count.index)
  network       = var.vpc_id
  priority      = element(var.firewall_data[*].priority, count.index)
  source_ranges = element(var.firewall_data[*].source_ranges, count.index)
  dynamic "allow" {
    for_each = element(var.firewall_data[*].allow_list, count.index)
    content {
      protocol = allow.value.protocol
      ports    = allow.value.ports
    }
  }
  target_tags = element(var.firewall_data[*].target_tags, count.index)
}
