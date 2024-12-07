# data "google_storage_project_service_account" "carshub_gcs_account" {}

# resource "google_project_iam_member" "carshub_gcs_account_pubsub_publishing" {
#   project = "our-mediator-443812-i8"
#   role    = "roles/pubsub.publisher"
#   member  = "serviceAccount:${data.google_storage_project_service_account.carshub_gcs_account.email_address}"
# }

# resource "google_service_account" "carshub_service_account" {
#   account_id   = "carshub-service-account"
#   display_name = "CarsHub Service Account"
# }

# resource "google_project_iam_member" "invoking_permission" {
#   project    = "our-mediator-443812-i8"
#   role       = "roles/run.invoker"
#   member     = "serviceAccount:${google_service_account.carshub_service_account.email}"
#   depends_on = [google_project_iam_member.carshub_gcs_account_pubsub_publishing]
# }

# resource "google_project_iam_member" "event_receiving_permission" {
#   project    = "our-mediator-443812-i8"
#   role       = "roles/eventarc.eventReceiver"
#   member     = "serviceAccount:${google_service_account.carshub_service_account.email}"
#   depends_on = [google_project_iam_member.invoking_permission]
# }

# resource "google_project_iam_member" "artifactregistry_reader_permission" {
#   project    = "our-mediator-443812-i8"
#   role       = "roles/artifactregistry.reader"
#   member     = "serviceAccount:${google_service_account.carshub_service_account.email}"
#   depends_on = [google_project_iam_member.event_receiving_permission]
# }

# resource "google_cloudfunctions2_function" "carshub_media_function" {
#   depends_on = [
#     google_project_iam_member.event_receiving_permission,
#     google_project_iam_member.artifactregistry_reader_permission,
#   ]
  
#   name        = "carshub-media-function"
#   location    = "us-central1"
#   description = "A function to update media details in SQL database after the upload trigger"

#   build_config {
#     runtime     = "python312"
#     entry_point = "handler"
#     environment_variables = {
#     #   BUILD_CONFIG_TEST = "build_test"
#     }
#     source {
#       storage_source {
#         bucket = google_storage_bucket.carshub_media_code_bucket.name
#         object = google_storage_bucket_object.carshub_media_code_object.name
#       }
#     }
#   }

#   service_config {
#     max_instance_count = 3
#     min_instance_count = 1
#     available_memory   = "256M"
#     timeout_seconds    = 60
#     # environment_variables = {
#     #   SERVICE_CONFIG_TEST = "config_test"
#     # }
#     ingress_settings               = "ALLOW_INTERNAL_ONLY"
#     all_traffic_on_latest_revision = true
#     service_account_email          = google_service_account.carshub_service_account.email
#   }

#   event_trigger {
#     event_type            = "google.cloud.storage.object.v1.finalized"
#     retry_policy          = "RETRY_POLICY_RETRY"
#     service_account_email = google_service_account.carshub_service_account.email
#     event_filters {
#       attribute = "bucket"
#       value     = google_storage_bucket.carshub_media_bucket.name
#     }
#   }
# }