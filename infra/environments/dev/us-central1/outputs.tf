output "frontend_lb_url" {
  value = module.carshub_frontend_service_lb.ip_address
}

output "backend_lb_url" {
  value = module.carshub_backend_service_lb.ip_address
}
