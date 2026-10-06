output "function_name" {
  description = "The name of the deployed Cloud Function."
  value       = google_cloudfunctions2_function.function.name
}

output "function_id" {
  description = "The fully qualified resource ID of the function."
  value       = google_cloudfunctions2_function.function.id
}

output "service_name" {
  description = "The name of the underlying Cloud Run service handling events."
  value       = google_cloudfunctions2_function.function.service_config[0].service
}

output "event_trigger" {
  description = "The effective event trigger attributes."
  value       = google_cloudfunctions2_function.function.event_trigger
}

output "function_url" {
  description = "The HTTPS trigger URL (populated for HTTP-triggered functions)."
  value       = try(google_cloudfunctions2_function.function.service_config[0].uri, null)
}