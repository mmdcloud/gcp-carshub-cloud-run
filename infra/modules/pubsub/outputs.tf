output "topic_id" {
  description = "The ID of the created Pub/Sub topic."
  value       = google_pubsub_topic.topic.id
}

output "topic_name" {
  description = "The name of the created Pub/Sub topic."
  value       = google_pubsub_topic.topic.name
}

output "schema_id" {
  description = "The ID of the created Pub/Sub schema."
  value       = try(google_pubsub_schema.schema[0].id, null)
}

output "subscription_ids" {
  description = "Map of subscription IDs keyed by input subscription identifier."
  value       = { for k, v in google_pubsub_subscription.subscription : k => v.id }
}

output "subscription_names" {
  description = "Map of subscription names keyed by input subscription identifier."
  value       = { for k, v in google_pubsub_subscription.subscription : k => v.name }
}