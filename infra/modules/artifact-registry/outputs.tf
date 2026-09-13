output "repository_id" {
  value = google_artifact_registry_repository.repo.id
}

output "repository_name" {
  value = google_artifact_registry_repository.repo.name
}

output "rule_ids" {
  description = "Map of rule_id => fully qualified rule resource ID."
  value       = { for k, r in google_artifact_registry_rule.this : k => r.id }
}

output "project_config_name" {
  value = try(google_artifact_registry_project_config.this[0].name, null)
}

output "vpcsc_config_name" {
  value = try(google_artifact_registry_vpcsc_config.this[0].id, null)
}