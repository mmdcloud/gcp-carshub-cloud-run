# output "frontend_lb_url" {
#   value       = "https://${var.domain_name}"
#   description = "Frontend HTTPS URL"
# }

output "backend_lb_url" {
  value       = "https://${module.carshub_backend_service_lb.ip_address}"
  description = "Backend HTTPS URL"
}

output "frontend_lb_ip" {
  value       = module.carshub_frontend_service_lb.ip_address
  description = "Frontend Load Balancer IP Address"
}

output "backend_lb_ip" {
  value       = module.carshub_backend_service_lb.ip_address
  description = "Backend Load Balancer IP Address"
}

# output "cloud_armor_policy_id" {
#   value       = module.cloud_armor.policy.id
#   description = "Cloud Armor Security Policy ID"
# }

output "database_connection_name" {
  value       = module.carshub_db.db_connection_name
  description = "Cloud SQL Connection Name"
  sensitive   = true
}
