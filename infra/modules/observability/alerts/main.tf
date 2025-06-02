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
            alignment_period   = aggregations.value.alignment_period
            per_series_aligner = aggregations.value.per_series_aligner
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