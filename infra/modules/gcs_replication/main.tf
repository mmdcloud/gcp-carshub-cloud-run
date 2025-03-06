resource "google_storage_transfer_job" "storage_replication_service" {
  description = "Storage Replication Service"

  replication_spec {
    transfer_options {
      delete_objects_unique_in_sink = false
    }
    gcs_data_source {
      bucket_name = var.source_bucket
    }
    gcs_data_sink {
      bucket_name = var.dest_bucket
    }
    
  }
}
