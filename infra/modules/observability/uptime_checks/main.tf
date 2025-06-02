# Uptime check
resource "google_monitoring_uptime_check_config" "uptime" {
  display_name = var.display_name
  timeout      = var.timeout
  period       = var.period

  http_check {
    path         = var.http_path
    port         = var.http_port
    request_method = var.http_request_method
    validate_ssl = var.http_validate_ssl
  }

  monitored_resource {
    type = var.resource_type
    labels = {
      host       = var.resource_host
    }
  }
  
  checker_type = var.checker_type
}