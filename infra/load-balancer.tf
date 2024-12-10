# Reserve an external IP for CDN
resource "google_compute_global_address" "carshub_cdn_lb_global_address" {
  name         = "carshub-cdn-lb-global-address"
  address_type = "EXTERNAL"
}

# GCP URL MAP
resource "google_compute_url_map" "carshub_cdn_compute_url_map" {
  name            = "carshub-cdn-compute-url-map"
  default_service = google_compute_backend_bucket.carshub_media_cdn.self_link
  host_rule {
    hosts        = ["*"]
    path_matcher = "allpaths"
  }
  path_matcher {
    name            = "allpaths"
    default_service = google_compute_backend_bucket.carshub_media_cdn.self_link
  }
}

# GCP target proxy
resource "google_compute_target_http_proxy" "carshub_cdn_target_proxy" {
  provider = google
  name     = "carshub-cdn-target-proxy"
  url_map  = google_compute_url_map.carshub_cdn_compute_url_map.self_link
}

# GCP forwarding rule
resource "google_compute_global_forwarding_rule" "carshub_cdn_global_forwarding_rule" {
  name                  = "carshub-cdn-global-forwarding-rule"
  load_balancing_scheme = "EXTERNAL"
  ip_address            = google_compute_global_address.carshub_cdn_lb_global_address.address
  port_range            = "80"
  target                = google_compute_target_http_proxy.carshub_cdn_target_proxy.self_link
}
