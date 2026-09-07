resource "google_artifact_registry_repository" "repo" {
  location               = var.location
  repository_id          = var.repository_id
  description            = var.description
  format                 = var.artifact_type
  cleanup_policy_dry_run = var.cleanup_policy_dry_run
  mode                   = var.mode
  kms_key_name           = var.kms_key_name

  dynamic "vulnerability_scanning_config" {
    for_each = var.vulnerability_scanning_config != null ? [var.vulnerability_scanning_config] : []
    content {
      enablement_config = vulnerability_scanning_config.value.enablement_config
    }
  }

  dynamic "maven_config" {
    for_each = var.maven_config != null ? [var.maven_config] : []
    content {
      allow_snapshot_overwrites = maven_config.value.allow_snapshot_overwrites
      version_policy            = maven_config.value.version_policy
    }
  }

  dynamic "docker_config" {
    for_each = var.docker_config != null ? [var.docker_config] : []
    content {
      immutable_tags = docker_config.value.immutable_tags
    }
  }

  dynamic "virtual_repository_config" {
    for_each = var.virtual_repository_config != null ? [var.virtual_repository_config] : []
    content {
      dynamic "upstream_policies" {
        for_each = virtual_repository_config.value.upstream_policies
        content {
          id         = upstream_policies.value.id
          priority   = upstream_policies.value.priority
          repository = upstream_policies.value.repository
        }
      }
    }
  }

  labels = var.labels
}