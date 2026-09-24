data "google_project" "project" {}

# ---------------------------------------------------------------------------------
# Regional Secret 
# ---------------------------------------------------------------------------------
resource "google_secret_manager_regional_secret" "secret" {
  count               = var.is_regional == true ? 1 : 0
  secret_id           = var.secret_id
  location            = var.location
  deletion_protection = var.deletion_protection
  expire_time         = var.expire_time
  version_aliases     = var.version_aliases
  version_destroy_ttl = var.version_destroy_ttl
  ttl                 = var.ttl

  dynamic "rotation" {
    for_each = var.rotation != null ? [var.rotation] : []
    content {
      next_rotation_time = rotation.value.next_rotation_time
      rotation_period    = rotation.value.rotation_period
    }
  }

  dynamic "topics" {
    for_each = var.topics
    content {
      name = topics.value.name
    }
  }

  dynamic "customer_managed_encryption" {
    for_each = var.customer_managed_encryption != null ? [var.customer_managed_encryption] : []
    content {
      kms_key_name = customer_managed_encryption.value.kms_key_name
    }
  }
}

resource "google_secret_manager_regional_secret_version" "secret_version" {
  count                 = var.is_regional == true ? 1 : 0
  secret                = google_secret_manager_regional_secret.secret[0].name
  is_secret_data_base64 = var.is_secret_data_base64
  enabled               = var.is_version_enabled
  secret_data           = var.secret_data
}

resource "google_secret_manager_regional_secret_iam_member" "secret_access" {
  count      = var.is_regional == true ? 1 : 0
  secret_id  = google_secret_manager_regional_secret.secret[0].id
  role       = "roles/secretmanager.secretAccessor"
  member     = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"
  depends_on = [google_secret_manager_regional_secret.secret]
}


# ---------------------------------------------------------------------------------
# Global Secret 
# ---------------------------------------------------------------------------------
resource "google_secret_manager_secret" "secret" {
  count               = var.is_regional == false ? 1 : 0
  secret_id           = var.secret_id
  deletion_protection = var.deletion_protection
  expire_time         = var.expire_time
  version_aliases     = var.version_aliases
  version_destroy_ttl = var.version_destroy_ttl
  ttl                 = var.ttl

  dynamic "rotation" {
    for_each = var.rotation != null ? [var.rotation] : []
    content {
      next_rotation_time = rotation.value.next_rotation_time
      rotation_period    = rotation.value.rotation_period
    }
  }

  dynamic "topics" {
    for_each = var.topics
    content {
      name = topics.value.name
    }
  }

  dynamic "replication" {
    for_each = var.replication != null ? [var.replication] : []
    content {
      dynamic "auto" {
        for_each = replication.value.auto != null ? [replication.value.auto] : []
        content {
          dynamic "customer_managed_encryption" {
            for_each = var.customer_managed_encryption != null ? [var.customer_managed_encryption] : []
            content {
              kms_key_name = customer_managed_encryption.value.kms_key_name
            }
          }
        }
      }

      dynamic "user_managed" {
        for_each = replication.value.user_managed != null ? [replication.value.user_managed] : []
        content {
          dynamic "replicas" {
            for_each = user_managed.value.replicas
            content {
              location = replicas.value.location
              dynamic "customer_managed_encryption" {
                for_each = user_managed.value.customer_managed_encryption != null ? [user_managed.value.customer_managed_encryption] : []
                content {
                  kms_key_name = customer_managed_encryption.value.kms_key_name
                }
              }
            }
          }
        }
      }
    }
  }
}

resource "google_secret_manager_secret_version" "secret_version" {
  count                  = var.is_regional == false ? 1 : 0
  secret                 = google_secret_manager_secret.secret[0].name
  enabled                = var.is_version_enabled
  is_secret_data_base64  = var.is_secret_data_base64
  secret_data_wo         = var.secret_data_wo
  secret_data_wo_version = var.secret_data_wo_version
  secret_data            = var.secret_data
}

resource "google_secret_manager_secret_iam_member" "secret_access" {
  count      = var.is_regional == false ? 1 : 0
  secret_id  = google_secret_manager_secret.secret[0].id
  role       = "roles/secretmanager.secretAccessor"
  member     = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"
  depends_on = [google_secret_manager_secret.secret]
}