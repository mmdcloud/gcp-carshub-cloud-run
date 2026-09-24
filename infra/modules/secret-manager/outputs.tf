
# -----------------------------------------------------------------------------------------
# Identity outputs (resolved across regional/global variants)
# -----------------------------------------------------------------------------------------
output "secret_id" {
  description = "The short secret_id as passed in (not the full resource path)."
  value       = var.secret_id
}

output "id" {
  description = "The fully qualified Terraform resource ID of the created secret (regional or global, whichever was created)."
  value = var.is_regional ? (
    length(google_secret_manager_regional_secret.secret) > 0 ? google_secret_manager_regional_secret.secret[0].id : null
    ) : (
    length(google_secret_manager_secret.secret) > 0 ? google_secret_manager_secret.secret[0].id : null
  )
}

output "name" {
  description = "The full resource name of the secret, e.g. projects/{{project}}/secrets/{{secret_id}} or projects/{{project}}/locations/{{location}}/secrets/{{secret_id}}."
  value = var.is_regional ? (
    length(google_secret_manager_regional_secret.secret) > 0 ? google_secret_manager_regional_secret.secret[0].name : null
    ) : (
    length(google_secret_manager_secret.secret) > 0 ? google_secret_manager_secret.secret[0].name : null
  )
}

output "create_time" {
  description = "Timestamp at which the secret was created."
  value = var.is_regional ? (
    length(google_secret_manager_regional_secret.secret) > 0 ? google_secret_manager_regional_secret.secret[0].create_time : null
    ) : (
    length(google_secret_manager_secret.secret) > 0 ? google_secret_manager_secret.secret[0].create_time : null
  )
}

output "is_regional" {
  description = "Echoes which variant (regional or global) was created, for use by callers that need to branch on it (e.g. when passing this secret into a Cloud Run secret_key_ref)."
  value       = var.is_regional
}

output "location" {
  description = "The region the secret was created in. Null for global secrets."
  value       = var.is_regional ? var.location : null
}

# -----------------------------------------------------------------------------------------
# Version outputs
# -----------------------------------------------------------------------------------------
output "version_id" {
  description = "The fully qualified Terraform resource ID of the initial secret version."
  value = var.is_regional ? (
    length(google_secret_manager_regional_secret_version.secret_version) > 0 ? google_secret_manager_regional_secret_version.secret_version[0].id : null
    ) : (
    length(google_secret_manager_secret_version.secret_version) > 0 ? google_secret_manager_secret_version.secret_version[0].id : null
  )
}

output "version_name" {
  description = "The full resource name of the initial secret version, e.g. .../secrets/{{secret_id}}/versions/{{version}}. Useful for pinning a secret_key_ref version in a Cloud Run/Cloud Function env var."
  value = var.is_regional ? (
    length(google_secret_manager_regional_secret_version.secret_version) > 0 ? google_secret_manager_regional_secret_version.secret_version[0].name : null
    ) : (
    length(google_secret_manager_secret_version.secret_version) > 0 ? google_secret_manager_secret_version.secret_version[0].name : null
  )
}

output "version_number" {
  description = "Just the numeric version identifier (parsed from version_name), suitable for direct use in secret_key_ref.version."
  value = var.is_regional ? (
    length(google_secret_manager_regional_secret_version.secret_version) > 0 ?
    element(split("/", google_secret_manager_regional_secret_version.secret_version[0].name), length(split("/", google_secret_manager_regional_secret_version.secret_version[0].name)) - 1)
    : null
    ) : (
    length(google_secret_manager_secret_version.secret_version) > 0 ?
    element(split("/", google_secret_manager_secret_version.secret_version[0].name), length(split("/", google_secret_manager_secret_version.secret_version[0].name)) - 1)
    : null
  )
}

output "version_enabled" {
  description = "Whether the initial secret version is enabled."
  value = var.is_regional ? (
    length(google_secret_manager_regional_secret_version.secret_version) > 0 ? google_secret_manager_regional_secret_version.secret_version[0].enabled : null
    ) : (
    length(google_secret_manager_secret_version.secret_version) > 0 ? google_secret_manager_secret_version.secret_version[0].enabled : null
  )
}

# -----------------------------------------------------------------------------------------
# IAM outputs
# -----------------------------------------------------------------------------------------
output "default_accessor_member" {
  description = "The IAM member string granted roles/secretmanager.secretAccessor by default (the project's Compute Engine default service account)."
  value       = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"
}

# -----------------------------------------------------------------------------------------
# Secret data (sensitive — use only where a consumer genuinely needs the
# plaintext value, e.g. passing a generated DB password into google_sql_user).
# Marked sensitive so Terraform redacts it from plan/apply output and CLI
# `terraform output` (without -raw/-json); it is still written to state,
# so state must be treated as sensitive (encrypted backend, restricted
# access) regardless. Prefer wiring consumers to read via secret_key_ref
# at runtime instead of this output wherever that's an option.
# -----------------------------------------------------------------------------------------
output "secret_data" {
  description = "The plaintext secret value. Sensitive: redacted from CLI output, but present in state."
  value = var.is_regional ? (
    length(google_secret_manager_regional_secret_version.secret_version) > 0 ? google_secret_manager_regional_secret_version.secret_version[0].secret_data : null
    ) : (
    length(google_secret_manager_secret_version.secret_version) > 0 ? google_secret_manager_secret_version.secret_version[0].secret_data : null
  )
  sensitive = true
}