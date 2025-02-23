resource "google_cloudbuild_trigger" "cloudbuild_trigger" {
  source_to_build {
    uri       = var.source_uri
    ref       = var.source_ref
    repo_type = var.repo_type
  }
  git_file_source {
    path      = var.filename
    uri       = var.source_uri
    revision  = var.source_ref
    repo_type = var.repo_type
  }
  #   substitutions = {
  #     _FOO = "bar"
  #     _BAZ = "qux"
  #   }
}
