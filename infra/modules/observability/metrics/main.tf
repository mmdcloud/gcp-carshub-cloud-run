# Application error metric
resource "google_logging_metric" "metric" {
  name   = var.name
  filter = var.filter

  metric_descriptor {
    metric_kind = var.metric_kind
    value_type  = var.value_type
    display_name = var.display_name
  }

  label_extractors = var.label_extractors
}