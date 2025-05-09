resource "google_compute_security_policy" "security_policy" {
  name        = "carshub-security-policy"
  description = "WAF security policy for CarHub applications"
  dynamic "rule" {
    for_each = var.rules
    content {
      action   = rule.value["action"]
      priority = rule.value["priority"]
      match {
        versioned_expr = rule.value["match"]["versioned_expr"]
        expr {
            expression = rule.value["match"]["expression"] == null ? null : rule.value["match"]["expression"]
        }
        config {
          src_ip_ranges = rule.value["src_ip_ranges"] == null ? [] : rule.value["src_ip_ranges"]
        }
      }
      description = rule.value["description"]
    }

  }
  # Default rule (required)
  #   rule {
  #     action   = "allow"
  #     priority = "2147483647"  # Max int32 value - executes last
  #     match {
  #       versioned_expr = "SRC_IPS_V1"
  #       config {
  #         src_ip_ranges = ["*"]
  #       }
  #     }
  #     description = "Default rule, allows all traffic"
  #   }

  #   # Block common web attacks
  #   rule {
  #     action   = "deny(403)"
  #     priority = "1000"
  #     match {
  #       expr {
  #         expression = "evaluatePreconfiguredExpr('xss-stable')"
  #       }
  #     }
  #     description = "Block XSS attacks"
  #   }

  #   rule {
  #     action   = "deny(403)"
  #     priority = "1001"
  #     match {
  #       expr {
  #         expression = "evaluatePreconfiguredExpr('sqli-stable')"
  #       }
  #     }
  #     description = "Block SQL injection attacks"
  #   }

  # Rate limiting rule - example for API
  #   rule {
  #     action   = "rate_based_ban"
  #     priority = "900"
  #     match {
  #       versioned_expr = "SRC_IPS_V1"
  #       config {
  #         src_ip_ranges = ["*"]
  #       }
  #     }
  #     description = "Rate limiting for all IPs"
  #     rate_limit_options {
  #       rate_limit_threshold {
  #         count        = 100
  #         interval_sec = 60
  #       }
  #       conform_action = "allow"
  #       exceed_action  = "deny(429)"
  #       enforce_on_key = "IP"
  #     }
  #   }

  # Optional: Geo-based restrictions
  #   rule {
  #     action   = "deny(403)"
  #     priority = "800"
  #     match {
  #       expr {
  #         expression = "origin.region_code == 'RU' || origin.region_code == 'CN'"
  #       }
  #     }
  #     description = "Block traffic from specific countries - customize as needed"
  #   }
}
