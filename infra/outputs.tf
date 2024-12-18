output "frontend_url" {
  value = module.carshub_frontend_service.service_uri
}

output "backend_url" {
  value = module.carshub_backend_service.service_uri
}
