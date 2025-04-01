resource "google_monitoring_uptime_check_config" "http" {
  display_name = "http-uptime-check"
  timeout      = "60s"
  user_labels  = {
    example-key = "example-value"
  }

  http_check {
    path = "some-path"
    port = "8010"
    request_method = "POST"
    content_type = "USER_PROVIDED"
    custom_content_type = "application/json"
    body = "Zm9vJTI1M0RiYXI="
    ping_config {
      pings_count = 1
    }
  }

  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = "my-project-name"
      host       = "192.168.1.1"
    }
  }

  content_matchers {
    content = "\"example\""
    matcher = "MATCHES_JSON_PATH"
    json_path_matcher {
      json_path = "$.path"
      json_matcher = "EXACT_MATCH"
    }
  }

  checker_type = "STATIC_IP_CHECKERS"
}