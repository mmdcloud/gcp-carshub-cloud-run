resource "google_logging_metric" "metric" {
  name   = var.name
  filter = var.filter

  metric_descriptor {
    metric_kind  = var.metric_kind
    value_type   = var.value_type
    display_name = var.display_name

    # Each key in label_extractors needs a matching descriptor here
    dynamic "labels" {
      for_each = var.label_extractors
      content {
        key        = labels.key
        value_type = "STRING"
      }
    }
  }

  label_extractors = var.label_extractors
}