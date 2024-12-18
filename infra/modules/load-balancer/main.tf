# Reserve an external IP for CDN
resource "google_compute_global_address" "global_address" {
  name         = var.global_address_name
  address_type = var.global_address_type
}

# GCP URL MAP
resource "google_compute_url_map" "url_map" {
  name            = var.url_map_name
  default_service = var.url_map_service
  host_rule {
    hosts        = ["*"]
    path_matcher = "allpaths"
  }
  path_matcher {
    name            = "allpaths"
    default_service = var.url_map_service
  }
}

# GCP target proxy
resource "google_compute_target_http_proxy" "target_http_proxy" {
  name    = var.target_proxy_name
  url_map = google_compute_url_map.url_map.self_link
}

# GCP forwarding rule
resource "google_compute_global_forwarding_rule" "global_forwarding_rule" {
  name                  = var.forwarding_rule_name
  load_balancing_scheme = var.forwarding_scheme
  ip_address            = google_compute_global_address.global_address.address
  port_range            = var.forwarding_port_range
  target                = google_compute_target_http_proxy.target_http_proxy.self_link
}
