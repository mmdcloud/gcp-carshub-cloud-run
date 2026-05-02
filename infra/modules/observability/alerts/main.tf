resource "google_monitoring_alert_policy" "alert_policy" {
  display_name = var.display_name
  combiner     = var.combiner
  enabled      = var.enabled

  dynamic "conditions" {
    for_each = var.conditions
    content {
      display_name = conditions.value.display_name
      condition_threshold {
        filter          = conditions.value.filter
        duration        = conditions.value.duration
        comparison      = conditions.value.comparison
        threshold_value = conditions.value.threshold_value

        dynamic "aggregations" {
          for_each = [conditions.value.aggregations]
          content {
            alignment_period     = aggregations.value.alignment_period
            per_series_aligner   = aggregations.value.per_series_aligner
            # These were missing — required for DISTRIBUTION metrics and cross-series reduction
            cross_series_reducer = lookup(aggregations.value, "cross_series_reducer", null)
            group_by_fields      = lookup(aggregations.value, "group_by_fields", [])
          }
        }
      }
    }
  }

  notification_channels = var.notification_channels

  alert_strategy {
    auto_close = var.auto_close
  }
}