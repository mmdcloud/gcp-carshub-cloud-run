resource "google_compute_security_policy" "policy" {
  name        = var.name
  description = var.description

  # If custom rules are not provided, create a default rule
  dynamic "rule" {
    for_each = length(var.rules) > 0 ? var.rules : [
      {
        priority      = 2147483647 # Default rule is always last (max int32)
        action        = "allow"
        description   = "Default rule, higher priority overrides it"
        src_ip_ranges = ["*"]
        expression    = null
      }
    ]

    content {
      action      = rule.value.action
      priority    = rule.value.priority
      description = rule.value.description
      preview     = rule.value.preview

      match {
        # Use expression-based rules if provided, otherwise use IP-based rules
        dynamic "expr" {
          for_each = rule.value.expression != null ? [1] : []
          content {
            expression = rule.value.expression
          }
        }

        # Only create versioned_expr for IP-based rules
        dynamic "versioned_expr" {
          for_each = rule.value.expression == null ? ["SRC_IPS_V1"] : []
          content {
            versioned_expr = versioned_expr.value
          }
        }

        # Only create config for IP-based rules
        dynamic "config" {
          for_each = rule.value.expression == null ? [1] : []
          content {
            src_ip_ranges = rule.value.src_ip_ranges
          }
        }
      }
    }
  }

  # Optional security level configuration
  # dynamic "adaptive_protection_config" {
  #   for_each = var.enable_adaptive_protection ? [1] : []
  #   content {
  #     layer_7_ddos_defense_config {
  #       enable = true
  #       rule_visibility = var.adaptive_protection_rule_visibility
  #     }
  #   }
  # }

  # # Configure advanced options
  # advanced_options_config {
  #   dynamic "json_parsing" {
  #     for_each = var.json_parsing != null ? [var.json_parsing] : []
  #     content {
  #       allow_invalid_json = json_parsing.value.allow_invalid_json
  #     }
  #   }

  #   dynamic "log_level" {
  #     for_each = var.log_level != null ? [var.log_level] : []
  #     content {
  #       value = log_level.value
  #     }
  #   }
  # }

  # # Configure custom managed rules if provided
  # dynamic "managed_rules" {
  #   for_each = var.managed_rule_sets != null ? [1] : []
  #   content {
  #     dynamic "managed_rule_set" {
  #       for_each = var.managed_rule_sets
  #       content {
  #         rule_set_name = managed_rule_set.value.rule_set_name
  #         rule_set_version = managed_rule_set.value.rule_set_version

  #         dynamic "override_rule" {
  #           for_each = managed_rule_set.value.override_rules != null ? managed_rule_set.value.override_rules : []
  #           content {
  #             rule_id = override_rule.value.rule_id
  #             action = override_rule.value.action
  #             sensitivity = lookup(override_rule.value, "sensitivity", null)
  #           }
  #         }
  #       }
  #     }
  #   }
  # }

  # # Set edge security policy TTL
  # dynamic "recaptcha_options_config" {
  #   for_each = var.recaptcha_redirect_site_key != null ? [1] : []
  #   content {
  #     redirect_site_key = var.recaptcha_redirect_site_key
  #   }
  # }

  # type = var.security_policy_type

  # # Configuring user-defined security custom fields
  # dynamic "user_defined_fields" {
  #   for_each = var.user_defined_fields != null ? var.user_defined_fields : []
  #   content {
  #     name = user_defined_fields.value.name
  #     base = user_defined_fields.value.base
  #     index = user_defined_fields.value.index
  #     mask = lookup(user_defined_fields.value, "mask", null)
  #     offset = lookup(user_defined_fields.value, "offset", null)
  #     size = lookup(user_defined_fields.value, "size", null)
  #   }
  # }

  lifecycle {
    create_before_destroy = true
  }
}

# resource "google_compute_security_policy" "security_policy" {
#   name        = "carshub-security-policy"
#   description = "WAF security policy for CarHub applications"
#   dynamic "rule" {
#     for_each = var.rules
#     content {
#       action   = rule.value["action"]
#       priority = rule.value["priority"]
#       match {
#         versioned_expr = rule.value["match"]["versioned_expr"]
#         expr {
#             expression = rule.value["match"]["expression"] == null ? null : rule.value["match"]["expression"]
#         }
#         config {
#           src_ip_ranges = rule.value["src_ip_ranges"] == null ? [] : rule.value["src_ip_ranges"]
#         }
#       }
#       description = rule.value["description"]
#     }

#   }
#   # Default rule (required)
#   #   rule {
#   #     action   = "allow"
#   #     priority = "2147483647"  # Max int32 value - executes last
#   #     match {
#   #       versioned_expr = "SRC_IPS_V1"
#   #       config {
#   #         src_ip_ranges = ["*"]
#   #       }
#   #     }
#   #     description = "Default rule, allows all traffic"
#   #   }

#   #   # Block common web attacks
#   #   rule {
#   #     action   = "deny(403)"
#   #     priority = "1000"
#   #     match {
#   #       expr {
#   #         expression = "evaluatePreconfiguredExpr('xss-stable')"
#   #       }
#   #     }
#   #     description = "Block XSS attacks"
#   #   }

#   #   rule {
#   #     action   = "deny(403)"
#   #     priority = "1001"
#   #     match {
#   #       expr {
#   #         expression = "evaluatePreconfiguredExpr('sqli-stable')"
#   #       }
#   #     }
#   #     description = "Block SQL injection attacks"
#   #   }

#   # Rate limiting rule - example for API
#   #   rule {
#   #     action   = "rate_based_ban"
#   #     priority = "900"
#   #     match {
#   #       versioned_expr = "SRC_IPS_V1"
#   #       config {
#   #         src_ip_ranges = ["*"]
#   #       }
#   #     }
#   #     description = "Rate limiting for all IPs"
#   #     rate_limit_options {
#   #       rate_limit_threshold {
#   #         count        = 100
#   #         interval_sec = 60
#   #       }
#   #       conform_action = "allow"
#   #       exceed_action  = "deny(429)"
#   #       enforce_on_key = "IP"
#   #     }
#   #   }

#   # Optional: Geo-based restrictions
#   #   rule {
#   #     action   = "deny(403)"
#   #     priority = "800"
#   #     match {
#   #       expr {
#   #         expression = "origin.region_code == 'RU' || origin.region_code == 'CN'"
#   #       }
#   #     }
#   #     description = "Block traffic from specific countries - customize as needed"
#   #   }
# }
