data "google_iam_policy" "cloud_run_policy" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}

resource "google_cloud_run_v2_service_iam_policy" "cloud_run_iam_policy" {
  count       = length(var.members)
  name        = var.members[count.index]
  policy_data = data.google_iam_policy.cloud_run_policy.policy_data
}
