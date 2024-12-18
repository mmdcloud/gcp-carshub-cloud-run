locals {
  artifact_type = "DOCKER"
}

resource "google_artifact_registry_repository" "repo" {
  location      = var.location
  repository_id = var.repository_id
  description   = var.description
  format        = local.artifact_type
}

resource "null_resource" "push_artifact" {
  provisioner "local-exec" {
    command = var.shell_command
  }
}
