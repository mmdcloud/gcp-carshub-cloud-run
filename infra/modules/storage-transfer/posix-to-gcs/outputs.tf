output "id" {
  description = "The unique identifier of the transfer job."
  value       = google_storage_transfer_job.storage_transfer_service.id
}

output "name" {
  description = "The name of the transfer job."
  value       = google_storage_transfer_job.storage_transfer_service.name
}

