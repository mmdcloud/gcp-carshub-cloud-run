resource "google_service_account" "service_account" {
  account_id   = var.account_id
  display_name = var.display_name
}

resource "google_project_iam_member" "iam_member" {
  count = length(var.permissions)
  project = var.project_id
  role    = var.permissions[count.index]
  member  = var.member_prefix == "serviceAccount" ? "serviceAccount:${google_service_account.service_account.email}" : "user:${google_service_account.service_account.email}" 
}
