output "ip_address" {
  value = google_compute_global_address.global_address.self_link
}