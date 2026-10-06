locals {
  common_labels = merge(
    var.labels,
    {
      managed_by = "terraform"
    }
  )
}

resource "google_artifact_registry_repository" "repo" {
  project                = var.project_id
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

  dynamic "remote_repository_config" {
    for_each = var.remote_repository_config[*]
    content {
      description = remote_repository_config.value.description

      disable_upstream_validation = remote_repository_config.value.disable_upstream_validation

      dynamic "upstream_credentials" {
        for_each = remote_repository_config.value.upstream_credentials[*]
        content {
          username_password_credentials {
            username                = upstream_credentials.value.username
            password_secret_version = upstream_credentials.value.password_secret_version
          }
        }
      }

      dynamic "apt_repository" {
        for_each = remote_repository_config.value.apt_repository[*]
        content {
          dynamic "public_repository" {
            for_each = apt_repository.value.public_repository[*]
            content {
              repository_base = public_repository.value.repository_base
              repository_path = public_repository.value.repository_path
            }
          }
        }
      }

      dynamic "docker_repository" {
        for_each = remote_repository_config.value.docker_repository[*]
        content {
          public_repository = docker_repository.value.public_repository
          dynamic "custom_repository" {
            for_each = docker_repository.value.custom_repository[*]
            content {
              uri = custom_repository.value.uri
            }
          }
        }
      }

      dynamic "maven_repository" {
        for_each = remote_repository_config.value.maven_repository[*]
        content {
          public_repository = maven_repository.value.public_repository
          dynamic "custom_repository" {
            for_each = maven_repository.value.custom_repository[*]
            content {
              uri = custom_repository.value.uri
            }
          }
        }
      }

      dynamic "npm_repository" {
        for_each = remote_repository_config.value.npm_repository[*]
        content {
          public_repository = npm_repository.value.public_repository
          dynamic "custom_repository" {
            for_each = npm_repository.value.custom_repository[*]
            content {
              uri = custom_repository.value.uri
            }
          }
        }
      }

      dynamic "python_repository" {
        for_each = remote_repository_config.value.python_repository[*]
        content {
          public_repository = python_repository.value.public_repository
          dynamic "custom_repository" {
            for_each = python_repository.value.custom_repository[*]
            content {
              uri = custom_repository.value.uri
            }
          }
        }
      }

      dynamic "yum_repository" {
        for_each = remote_repository_config.value.yum_repository[*]
        content {
          dynamic "public_repository" {
            for_each = yum_repository.value.public_repository[*]
            content {
              repository_base = public_repository.value.repository_base
              repository_path = public_repository.value.repository_path
            }
          }
        }
      }
    }
  }

  dynamic "cleanup_policies" {
    for_each = var.cleanup_policies
    content {
      id     = cleanup_policies.key
      action = cleanup_policies.value.action

      dynamic "condition" {
        for_each = cleanup_policies.value.condition[*]
        content {
          tag_state             = condition.value.tag_state
          tag_prefixes          = condition.value.tag_prefixes
          older_than            = condition.value.older_than
          newer_than            = condition.value.newer_than
          version_name_prefixes = condition.value.version_name_prefixes
          package_name_prefixes = condition.value.package_name_prefixes
        }
      }

      dynamic "most_recent_versions" {
        for_each = cleanup_policies.value.most_recent_versions[*]
        content {
          keep_count            = most_recent_versions.value.keep_count
          package_name_prefixes = most_recent_versions.value.package_name_prefixes
        }
      }
    }
  }


  labels = local.common_labels
}

resource "google_artifact_registry_project_config" "this" {
  count    = var.enable_project_config ? 1 : 0
  provider = google-beta
  project  = var.project_id
  location = var.location

  platform_logs_config {
    logging_state  = var.platform_logs_config.logging_state
    severity_level = var.platform_logs_config.severity_level
  }
}

resource "google_artifact_registry_vpcsc_config" "this" {
  count        = var.enable_vpcsc_config ? 1 : 0
  provider     = google-beta
  project      = var.project_id
  location     = var.location
  vpcsc_policy = var.vpcsc_policy
}

resource "google_artifact_registry_rule" "this" {
  for_each      = { for r in var.rules : r.rule_id => r }
  provider      = google-beta
  project       = var.project_id
  location      = google_artifact_registry_repository.repo.location
  repository_id = google_artifact_registry_repository.repo.repository_id
  rule_id       = each.value.rule_id
  package_id    = each.value.package_id
  action        = each.value.action
  operation     = each.value.operation

  dynamic "condition" {
    for_each = each.value.condition != null ? [each.value.condition] : []
    content {
      expression  = condition.value.expression
      title       = condition.value.title
      description = condition.value.description
    }
  }
}

resource "google_artifact_registry_repository_iam_member" "readers" {
  for_each   = toset(contains(keys(var.members), "readers") ? var.members["readers"] : [])
  project    = google_artifact_registry_repository.repo.project
  location   = google_artifact_registry_repository.repo.location
  repository = google_artifact_registry_repository.repo.name

  role   = "roles/artifactregistry.reader"
  member = each.value

  depends_on = [
    google_artifact_registry_repository.repo
  ]
}

resource "google_artifact_registry_repository_iam_member" "writers" {
  for_each   = toset(contains(keys(var.members), "writers") ? var.members["writers"] : [])
  project    = google_artifact_registry_repository.repo.project
  location   = google_artifact_registry_repository.repo.location
  repository = google_artifact_registry_repository.repo.name

  role   = "roles/artifactregistry.writer"
  member = each.value

  depends_on = [
    google_artifact_registry_repository.repo
  ]
}