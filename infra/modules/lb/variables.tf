# ############################################
# # Core / naming
# ############################################

# variable "project_id" {
#   description = "GCP project ID to deploy resources into."
#   type        = string
# }

# variable "name" {
#   description = "Base name used to derive names for all LB resources (IP, backend service, URL map, proxies, forwarding rules, cert, security policy)."
#   type        = string

#   validation {
#     condition     = can(regex("^[a-z]([-a-z0-9]*[a-z0-9])?$", var.name))
#     error_message = "name must be a valid RFC1035 label: lowercase letters, numbers, hyphens; must start with a letter."
#   }
# }

# variable "labels" {
#   description = "Labels applied to supported resources (backend service, forwarding rules)."
#   type        = map(string)
#   default     = {}
# }

# ############################################
# # Frontend: IP, domains, TLS
# ############################################

# variable "create_static_ip" {
#   description = "Whether to reserve a new global static external IP. Set false and supply reserved_ip_address to reuse an existing one."
#   type        = bool
#   default     = true
# }

# variable "reserved_ip_address" {
#   description = "Existing reserved global IP address to use when create_static_ip = false."
#   type        = string
#   default     = null
# }

# variable "domains" {
#   description = "Domain names for the Google-managed SSL certificate (e.g. ['app.example.com']). Required when managed_ssl_certificate = true. Each domain must already have DNS pointed at the LB's IP for provisioning to succeed."
#   type        = list(string)
#   default     = []
# }

# variable "managed_ssl_certificate" {
#   description = "Whether to provision a Google-managed SSL certificate from var.domains. Set false to supply your own certificate(s) via ssl_certificate_ids."
#   type        = bool
#   default     = false
# }

# variable "ssl_certificate_ids" {
#   description = "Self links of pre-existing SSL certificates to attach to the HTTPS proxy, used when managed_ssl_certificate = false."
#   type        = list(string)
#   default     = []
# }

# variable "ssl_policy_min_tls_version" {
#   description = "Minimum TLS version enforced by the LB's SSL policy."
#   type        = string
#   default     = "TLS_1_2"

#   validation {
#     condition     = contains(["TLS_1_0", "TLS_1_1", "TLS_1_2"], var.ssl_policy_min_tls_version)
#     error_message = "ssl_policy_min_tls_version must be one of: TLS_1_0, TLS_1_1, TLS_1_2."
#   }
# }

# variable "ssl_policy_profile" {
#   description = "SSL policy profile controlling allowed cipher suites."
#   type        = string
#   default     = "MODERN"

#   validation {
#     condition     = contains(["COMPATIBLE", "MODERN", "RESTRICTED", "CUSTOM"], var.ssl_policy_profile)
#     error_message = "ssl_policy_profile must be one of: COMPATIBLE, MODERN, RESTRICTED, CUSTOM."
#   }
# }

# variable "enable_http_redirect" {
#   description = "Whether to provision a port-80 listener that permanently redirects all HTTP traffic to HTTPS. Recommended for production."
#   type        = bool
#   default     = true
# }

# variable "enable_ipv6" {
#   description = "Whether to also reserve/serve an IPv6 global address alongside IPv4."
#   type        = bool
#   default     = false
# }

# ############################################
# # Backend(s)
# ############################################

# variable "backends" {
#   description = <<-EOT
#     Map of backend services to create, keyed by a short logical name (used in resource naming).
#     Each backend maps to one google_compute_backend_service, fed by one or more instance groups
#     (typically MIG self_links, e.g. from the instance-group module's instance_group_self_link output).
#   EOT
#   type = map(object({
#     description = optional(string, "")
#     protocol    = optional(string, "HTTP") # HTTP, HTTPS, HTTP2
#     port_name   = optional(string, "http")
#     timeout_sec = optional(number, 30)
#     enable_cdn  = optional(bool, false)

#     # Existing health check ID/self_link to reuse (e.g. from the instance-group module).
#     # If null, a new HTTP health check is created for this backend.
#     health_check_id     = optional(string, null)
#     manage_health_check = optional(bool, true)
#     health_check = optional(object({
#       port                = optional(number, 80)
#       request_path        = optional(string, "/")
#       check_interval_sec  = optional(number, 10)
#       timeout_sec         = optional(number, 5)
#       healthy_threshold   = optional(number, 2)
#       unhealthy_threshold = optional(number, 3)
#     }), {})

#     groups = list(object({
#       group           = string # instance group / NEG self_link
#       balancing_mode  = optional(string, "UTILIZATION")
#       capacity_scaler = optional(number, 1.0)
#       max_utilization = optional(number, 0.8)
#     }))

#     log_sample_rate = optional(number, 1.0)

#     # Path patterns (URL map) that route to this backend. The backend listed with
#     # is_default = true (exactly one required) handles all otherwise-unmatched traffic.
#     is_default    = optional(bool, false)
#     host_patterns = optional(list(string), []) # e.g. ["app.example.com"]
#     path_patterns = optional(list(string), []) # e.g. ["/api/*"]
#   }))

#   validation {
#     condition     = length([for k, v in var.backends : k if v.is_default]) == 1
#     error_message = "Exactly one entry in var.backends must have is_default = true."
#   }
# }

# ############################################
# # Cloud Armor (WAF / rate limiting)
# ############################################

# variable "enable_cloud_armor" {
#   description = "Whether to create and attach a Cloud Armor security policy to all backend services."
#   type        = bool
#   default     = true
# }

# variable "cloud_armor_default_action" {
#   description = "Default action for the Cloud Armor policy when no rule matches: 'allow' or 'deny(403)' etc."
#   type        = string
#   default     = "allow"
# }

# variable "cloud_armor_rate_limit_threshold_count" {
#   description = "Number of requests allowed per client IP within the rate-limit interval before throttling/blocking."
#   type        = number
#   default     = 100
# }

# variable "cloud_armor_rate_limit_interval_sec" {
#   description = "Rate-limit sliding window, in seconds. Also used as the ban-threshold interval, which GCP restricts to one of: 60, 120, 180, 240, 300, 600, 900, 1200, 1800, 2700, 3600."
#   type        = number
#   default     = 60

#   validation {
#     condition     = contains([60, 120, 180, 240, 300, 600, 900, 1200, 1800, 2700, 3600], var.cloud_armor_rate_limit_interval_sec)
#     error_message = "cloud_armor_rate_limit_interval_sec must be one of: 60, 120, 180, 240, 300, 600, 900, 1200, 1800, 2700, 3600 (required for the ban_threshold interval)."
#   }
# }

# variable "cloud_armor_rate_limit_ban_duration_sec" {
#   description = "How long an offending client IP is banned after exceeding the rate limit."
#   type        = number
#   default     = 300
# }

# variable "cloud_armor_preconfigured_rules" {
#   description = "Preconfigured WAF rule sets (Cloud Armor managed rules) to enable, e.g. ['sqli-v33-stable', 'xss-v33-stable', 'lfi-v33-stable']. Empty list disables preconfigured WAF rules (rate limiting still applies if enabled)."
#   type        = list(string)
#   default     = ["sqli-v33-stable", "xss-v33-stable", "lfi-v33-stable", "rce-v33-stable"]
# }

# variable "cloud_armor_allowlist_ip_ranges" {
#   description = "Optional list of CIDR ranges always allowed, evaluated before WAF/rate-limit rules (e.g. office IPs, health-check ranges you want exempted)."
#   type        = list(string)
#   default     = []
# }

# variable "cloud_armor_denylist_ip_ranges" {
#   description = "Optional list of CIDR ranges always denied."
#   type        = list(string)
#   default     = []
# }

# ############################################
# # Logging
# ############################################

# variable "enable_logging" {
#   description = "Whether to enable backend service access logging (exported to Cloud Logging)."
#   type        = bool
#   default     = true
# }

# variable "enable_ssl" {
#   description = "Whether to enable SSL or not"
#   type        = bool
#   default     = true
# }

# variable "enable_http" {
#   description = "Whether to enable http or not"
#   type        = bool
#   default     = true
# }

# variable "https_redirect" {
#   description = "Whether to redirect http to https or not"
#   type        = bool
#   default     = true
# }

variable "project_id" {
  description = "Project in which to create the load balancer resources."
  type        = string
}

variable "name" {
  description = "Base name used to prefix all resources created by this module."
  type        = string
}

############################################
# EXTERNAL vs INTERNAL
############################################
variable "load_balancer_type" {
  description = "EXTERNAL creates a global external HTTP(S) LB. INTERNAL creates a regional internal HTTP(S) LB."
  type        = string
  default     = "EXTERNAL"

  validation {
    condition     = contains(["EXTERNAL", "INTERNAL"], var.load_balancer_type)
    error_message = "load_balancer_type must be either \"EXTERNAL\" or \"INTERNAL\"."
  }
}

variable "region" {
  description = "Region for regional resources. Required when load_balancer_type = INTERNAL."
  type        = string
  default     = null
}

variable "network" {
  description = "VPC network (self link or name) the internal LB attaches to. Required when load_balancer_type = INTERNAL."
  type        = string
  default     = null
}

variable "subnetwork" {
  description = "Subnetwork (self link or name) used for the internal forwarding rule and internal static address. Required when load_balancer_type = INTERNAL."
  type        = string
  default     = null
}

variable "allow_global_access" {
  description = "Allow clients from any region to reach an INTERNAL load balancer's forwarding rule. Ignored for EXTERNAL."
  type        = bool
  default     = false
}

variable "create_proxy_only_subnet" {
  description = "Whether to create the regional proxy-only subnet (purpose = REGIONAL_MANAGED_PROXY) required by INTERNAL L7 LBs. Set to false if one already exists in the network/region."
  type        = bool
  default     = false
}

variable "proxy_only_subnet_cidr" {
  description = "CIDR range for the proxy-only subnet, when create_proxy_only_subnet = true."
  type        = string
  default     = null
}

############################################
# Static IP
############################################
variable "create_static_ip" {
  description = "Whether to reserve a static IP for the load balancer. If false, var.reserved_ip_address is used instead."
  type        = bool
  default     = true
}

variable "reserved_ip_address" {
  description = "A pre-existing IP address to use when create_static_ip = false."
  type        = string
  default     = null
}

variable "enable_ipv6" {
  description = "Reserve and serve traffic on an IPv6 address in addition to IPv4. EXTERNAL only."
  type        = bool
  default     = false
}

############################################
# Backends
############################################
variable "backends" {
  description = "Map of backend services to create, keyed by an arbitrary short name."
  type = map(object({
    description         = optional(string, "")
    protocol            = string
    port_name           = optional(string, "http")
    timeout_sec         = optional(number, 30)
    is_default          = optional(bool, false)
    enable_cdn          = optional(bool, false)
    log_sample_rate     = optional(number, 1.0)
    host_patterns       = optional(list(string), [])
    path_patterns       = optional(list(string), [])
    health_check_id     = optional(string)
    manage_health_check = optional(bool, true)

    groups = list(object({
      group           = string
      balancing_mode  = optional(string, "UTILIZATION")
      capacity_scaler = optional(number, 1.0)
      max_utilization = optional(number, 0.8)
    }))

    health_check = optional(object({
      check_interval_sec  = optional(number, 10)
      timeout_sec         = optional(number, 5)
      healthy_threshold   = optional(number, 2)
      unhealthy_threshold = optional(number, 2)
      port                = optional(number, 80)
      request_path        = optional(string, "/")
    }), {})
  }))

  validation {
    condition     = length([for k, v in var.backends : k if v.is_default]) == 1
    error_message = "Exactly one backend in var.backends must have is_default = true."
  }
}

############################################
# Listeners / SSL
############################################
variable "enable_http" {
  description = "Create a port-80 listener (either serving directly or redirecting to HTTPS, per var.https_redirect)."
  type        = bool
  default     = true
}

variable "enable_ssl" {
  description = "Create a port-443 (HTTPS) listener."
  type        = bool
  default     = false
}

variable "https_redirect" {
  description = "When enable_ssl = true, redirect all port-80 traffic to HTTPS instead of serving it directly."
  type        = bool
  default     = true
}

variable "managed_ssl_certificate" {
  description = "Provision a Google-managed SSL certificate for var.domains. EXTERNAL only — set false for INTERNAL and supply var.ssl_certificate_ids instead."
  type        = bool
  default     = true
}

variable "domains" {
  description = "Domains covered by the Google-managed SSL certificate, when managed_ssl_certificate = true."
  type        = list(string)
  default     = []
}

variable "ssl_certificate_ids" {
  description = "Pre-existing SSL certificate resource ids to attach to the HTTPS proxy, used when managed_ssl_certificate = false (required for INTERNAL)."
  type        = list(string)
  default     = []
}

variable "ssl_policy_profile" {
  description = "SSL policy profile: COMPATIBLE, MODERN, RESTRICTED, or CUSTOM."
  type        = string
  default     = "MODERN"
}

variable "ssl_policy_min_tls_version" {
  description = "Minimum TLS version for the SSL policy."
  type        = string
  default     = "TLS_1_2"
}

############################################
# Cloud Armor (EXTERNAL only)
############################################
variable "enable_cloud_armor" {
  description = "Attach a Cloud Armor security policy to each backend service. EXTERNAL only."
  type        = bool
  default     = false
}

variable "cloud_armor_default_action" {
  description = "Default action for the Cloud Armor policy's catch-all rule (e.g. \"allow\" or \"deny(403)\")."
  type        = string
  default     = "allow"
}

variable "cloud_armor_allowlist_ip_ranges" {
  description = "IP ranges to explicitly allow, evaluated before deny/WAF rules."
  type        = list(string)
  default     = []
}

variable "cloud_armor_denylist_ip_ranges" {
  description = "IP ranges to explicitly deny."
  type        = list(string)
  default     = []
}

variable "cloud_armor_preconfigured_rules" {
  description = "List of Cloud Armor preconfigured WAF expression names (e.g. \"sqli-v33-stable\") to enable as deny rules."
  type        = list(string)
  default     = []
}

variable "cloud_armor_rate_limit_threshold_count" {
  description = "Request count threshold per interval before rate limiting kicks in."
  type        = number
  default     = 100
}

variable "cloud_armor_rate_limit_interval_sec" {
  description = "Interval, in seconds, over which the rate limit threshold is measured."
  type        = number
  default     = 60
}

variable "cloud_armor_rate_limit_ban_duration_sec" {
  description = "How long, in seconds, an offending client IP is banned once it exceeds the ban threshold."
  type        = number
  default     = 300
}

############################################
# Logging / misc
############################################
variable "enable_logging" {
  description = "Enable backend service access logging."
  type        = bool
  default     = true
}

variable "labels" {
  description = "Labels applied to forwarding rules."
  type        = map(string)
  default     = {}
}