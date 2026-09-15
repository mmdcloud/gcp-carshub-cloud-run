# ---------------------------------------------------------------------------
# Dedicated runtime service account (optional, recommended for production).
#
# Cloud Run resources default to the Compute Engine default SA if none is
# given, which is almost always over-privileged. Setting
# var.create_service_account = true provisions a least-privilege SA scoped
# to this workload, and grants it the baseline roles every revision needs
# (write logs/metrics/traces, pull from Artifact Registry) plus anything in
# var.service_account_roles.
# ---------------------------------------------------------------------------
resource "google_service_account" "cloud_run_sa" {
  count        = var.create_service_account ? 1 : 0
  project      = var.project_id
  account_id   = var.service_account_id != null ? var.service_account_id : "${var.name}"
  display_name = "Runtime SA for Cloud Run ${var.type} ${var.name}"
}

resource "google_project_iam_member" "cloud_run_sa_baseline" {
  for_each = var.create_service_account ? toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/cloudtrace.agent",
    "roles/artifactregistry.reader",
  ]) : toset([])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.cloud_run_sa[0].email}"
}

resource "google_project_iam_member" "cloud_run_sa_extra" {
  for_each = var.create_service_account ? toset(var.service_account_roles) : toset([])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.cloud_run_sa[0].email}"
}

# ---------------------------------------------------------------------------
# Resource-level IAM bindings.
#
# var.iam_members is a flat list so callers can grant e.g. roles/run.invoker
# to a caller service account, roles/run.developer to an on-call group, etc,
# without needing to know which underlying resource (job / service /
# worker_pool) got created for this var.type.
#
# Example:
#   iam_members = [
#     { role = "roles/run.invoker", member = "serviceAccount:caller@project.iam.gserviceaccount.com" },
#     { role = "roles/run.viewer",  member = "group:on-call@example.com" },
#   ]
# ---------------------------------------------------------------------------
resource "google_cloud_run_v2_job_iam_member" "this" {
  for_each = var.type == "JOB" ? { for m in var.iam_members : "${m.role}|${m.member}" => m } : {}

  project  = var.project_id
  location = var.location
  name     = google_cloud_run_v2_job.job[0].name
  role     = each.value.role
  member   = each.value.member
}

resource "google_cloud_run_v2_service_iam_member" "this" {
  for_each = var.type == "SERVICE" ? { for m in var.iam_members : "${m.role}|${m.member}" => m } : {}

  project  = var.project_id
  location = var.location
  name     = google_cloud_run_v2_service.cloud_run_service[0].name
  role     = each.value.role
  member   = each.value.member
}

resource "google_cloud_run_v2_worker_pool_iam_member" "this" {
  for_each = var.type == "WORKER_POOL" ? { for m in var.iam_members : "${m.role}|${m.member}" => m } : {}

  project  = var.project_id
  location = var.location
  name     = google_cloud_run_v2_worker_pool.worker_pool[0].name
  role     = each.value.role
  member   = each.value.member
}