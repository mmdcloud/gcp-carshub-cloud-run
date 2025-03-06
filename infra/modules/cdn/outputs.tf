output "cdn_self_link" {
  value = google_compute_backend_bucket.cdn.self_link
}

output "cdn_ip_address" {
  value = google_compute_global_address.cdn_global_address.address
}
