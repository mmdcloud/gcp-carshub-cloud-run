output "frontend_url" {
  value = google_cloud_run_v2_service.carshub_frontend_service.uri
}

output "backend_url" {
  value = google_cloud_run_v2_service.carshub_backend_service.uri
}