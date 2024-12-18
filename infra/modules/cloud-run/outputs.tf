output "service_uri" {
  value = google_cloud_run_v2_service.cloud_run_service.uri
}

output "name" {
  value = google_cloud_run_v2_service.cloud_run_service.name
}