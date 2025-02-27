# // Create a Pub/Sub notification.
# resource "google_storage_notification" "notification" {
#   bucket         = google_storage_bucket.bucket.name
#   payload_format = "JSON_API_V1"
#   topic          = google_pubsub_topic.topic.id
#   depends_on     = [google_pubsub_topic_iam_binding.binding]
# }

# resource "google_pubsub_topic" "topic" {
#   name     = "your_topic_name"
# }
