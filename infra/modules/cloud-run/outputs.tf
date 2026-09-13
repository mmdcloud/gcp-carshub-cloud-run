output "job_id" {
  description = "Fully qualified ID of the Cloud Run job, if var.type == \"JOB\"."
  value       = try(google_cloud_run_v2_job.job[0].id, null)
}

output "job_name" {
  value = try(google_cloud_run_v2_job.job[0].name, null)
}

output "service_id" {
  description = "Fully qualified ID of the Cloud Run service, if var.type == \"SERVICE\"."
  value       = try(google_cloud_run_v2_service.cloud_run_service[0].id, null)
}

output "service_name" {
  value = try(google_cloud_run_v2_service.cloud_run_service[0].name, null)
}

output "service_uri" {
  description = "HTTPS URI of the Cloud Run service, if var.type == \"SERVICE\"."
  value       = try(google_cloud_run_v2_service.cloud_run_service[0].uri, null)
}

output "worker_pool_id" {
  description = "Fully qualified ID of the Cloud Run worker pool, if var.type == \"WORKER_POOL\"."
  value       = try(google_cloud_run_v2_worker_pool.worker_pool[0].id, null)
}

output "worker_pool_name" {
  value = try(google_cloud_run_v2_worker_pool.worker_pool[0].name, null)
}

output "service_account_email" {
  description = "Email of the module-managed runtime service account, if var.create_service_account is true."
  value       = try(google_service_account.cloud_run_sa[0].email, null)
}