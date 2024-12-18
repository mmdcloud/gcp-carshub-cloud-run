resource "google_project_iam_member" "iam_member" {
  project = var.project
  role    = var.role
  member  = var.member
}
