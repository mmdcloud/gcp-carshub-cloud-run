resource "google_project_service" "project" {
  for_each           = toset(var.apis)
  project            = var.project_id
  service            = each.value
  disable_dependent_services = true
  disable_on_destroy = var.disable_on_destroy
}
