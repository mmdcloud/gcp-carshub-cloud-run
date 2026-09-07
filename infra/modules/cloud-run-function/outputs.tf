# output "function_url" {
#   value = google_cloudfunctions2_function.function.url
# }

output "function_id" {
  description = "Fully qualified resource ID of the function."
  value       = google_cloudfunctions2_function.function.id
}

output "function_name" {
  value = google_cloudfunctions2_function.function.name
}

output "function_url" {
  description = "The HTTPS trigger URL (populated for HTTP-triggered functions)."
  value       = try(google_cloudfunctions2_function.function.service_config[0].uri, null)
}

output "function_state" {
  value = google_cloudfunctions2_function.function.state
}

output "function_update_time" {
  value = google_cloudfunctions2_function.function.update_time
}