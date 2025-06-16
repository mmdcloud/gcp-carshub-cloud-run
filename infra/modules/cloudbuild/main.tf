resource "google_cloudbuild_trigger" "cloudbuild_trigger" {
  name = var.trigger_name
  location = var.location
  trigger_template {
    branch_name = var.source_ref
    repo_name = var.repo_name    
  }
  substitutions = var.substitutions
  filename = var.filename
  # source_to_build {
  #   uri       = var.source_uri
  #   ref       = var.source_ref
  #   repo_type = var.repo_type
  # }
  # git_file_source {
  #   path      = var.filename
  #   uri       = var.source_uri
  #   revision  = var.source_ref
  #   repo_type = var.repo_type
  # }
  service_account = var.service_account
  approval_config {
     approval_required = true 
  }
  #   substitutions = {
  #     _FOO = "bar"
  #     _BAZ = "qux"
  #   }
}
