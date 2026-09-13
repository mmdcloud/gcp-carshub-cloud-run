# variable "type" {
#   description = "Which Cloud Run resource to create: \"JOB\" for google_cloud_run_v2_job, \"SERVICE\" for google_cloud_run_v2_service."
#   type        = string

#   validation {
#     condition     = contains(["JOB", "SERVICE"], var.type)
#     error_message = "var.type must be either \"JOB\" or \"SERVICE\"."
#   }
# }

# variable "name" {
#   description = "Name of the Cloud Run job/service."
#   type        = string
# }

# variable "location" {
#   description = "Region in which to deploy the Cloud Run job/service."
#   type        = string
# }

# variable "project_id" {
#   description = "GCP project ID in which to deploy the Cloud Run job/service."
#   type        = string
# }

# variable "deletion_protection" {
#   description = "Whether to enable deletion protection on the job/service."
#   type        = bool
#   default     = true
# }

# variable "client" {
#   description = "Client that created this resource."
#   type        = string
#   default     = null
# }

# variable "client_version" {
#   description = "Client version that created this resource."
#   type        = string
#   default     = null
# }

# variable "deletion_policy" {
#   description = "Deletion policy for the job/service (DELETE or ABANDON)."
#   type        = string
#   default     = "DELETE"
# }

# variable "launch_stage" {
#   description = "Launch stage of the job/service (e.g. GA, BETA, ALPHA)."
#   type        = string
#   default     = "GA"
# }

# variable "annotations" {
#   description = "Annotations to apply to the job/service and its template."
#   type        = map(string)
#   default     = {}
# }

# variable "tags" {
#   description = "Tags to apply to the job/service."
#   type        = map(string)
#   default     = {}
# }

# variable "labels" {
#   description = "Labels to apply to the job/service, merged with default labels on the SERVICE resource."
#   type        = map(string)
#   default     = {}
# }

# variable "binary_authorization" {
#   description = "Binary Authorization settings. Set to null to omit the block."
#   type = object({
#     breakglass_justification = optional(string)
#     policy                   = optional(string)
#     use_default              = optional(bool)
#   })
#   default = null
# }

# variable "parallelism" {
#   description = "Number of tasks that can run in parallel (JOB only)."
#   type        = number
#   default     = null
# }

# variable "task_count" {
#   description = "Number of tasks the job should run (JOB only)."
#   type        = number
#   default     = 1
# }

# variable "service_account" {
#   description = "Service account email used by the revision/execution."
#   type        = string
# }

# variable "gpu_zonal_redundancy_disabled" {
#   description = "Whether GPU zonal redundancy is disabled."
#   type        = bool
#   default     = null
# }

# variable "execution_environment" {
#   description = "Execution environment for the revision/execution (e.g. EXECUTION_ENVIRONMENT_GEN1, EXECUTION_ENVIRONMENT_GEN2)."
#   type        = string
#   default     = null
# }

# variable "max_retries" {
#   description = "Number of retries allowed per task (JOB only)."
#   type        = number
#   default     = 3
# }

# variable "encryption_key" {
#   description = "Customer-managed encryption key (CMEK) used to encrypt the revision/execution."
#   type        = string
#   default     = null
# }

# variable "timeout" {
#   description = "Max allowed duration for task/request execution, e.g. \"600s\"."
#   type        = string
#   default     = null
# }

# variable "node_selector" {
#   description = "Whether to include a node_selector block. Set to null to omit it; the accelerator value used comes from var.accelerator."
#   type = object({
#     accelerator = optional(string)
#   })
#   default = null
# }

# variable "accelerator" {
#   description = "GPU accelerator type to request (used when node_selector is set), e.g. \"nvidia-l4\"."
#   type        = string
#   default     = null
# }

# variable "volumes" {
#   description = "List of volumes to attach to the job/service."
#   type = list(object({
#     name = string
#     cloud_sql_instance = optional(object({
#       instances = list(string)
#     }))
#     empty_dir = optional(object({
#       medium     = optional(string)
#       size_limit = optional(string)
#     }))
#     gcs = optional(object({
#       bucket        = string
#       mount_options = optional(list(string))
#       read_only     = optional(bool)
#     }))
#     nfs = optional(object({
#       path      = optional(string)
#       read_only = optional(bool)
#       server    = string
#     }))
#     secret = optional(object({
#       default_mode = optional(number)
#       secret       = string
#       items = optional(list(object({
#         mode    = optional(number)
#         path    = string
#         version = optional(string)
#       })), [])
#     }))
#   }))
#   default = []
# }

# variable "vpc_access" {
#   description = "VPC access configuration. Set to null to omit the vpc_access block."
#   type = object({
#     vpc_connector_name = string
#     egress = string
#     network_interfaces = optional(list(object({
#       network    = string
#       subnetwork = string
#       tags       = optional(list(string))
#     })), [])
#   })
#   default = null
# }

# variable "containers" {
#   description = "List of containers to deploy in the job/service revision."
#   type = list(object({
#     name           = optional(string)
#     image          = string
#     args           = optional(list(string))
#     command        = optional(list(string))
#     working_dir    = optional(string)
#     base_image_uri = optional(string) # SERVICE only

#     # JOB uses resources.limits; SERVICE uses resources.cpu_idle / startup_cpu_boost
#     limits            = optional(map(string)) # JOB only
#     cpu_idle          = optional(bool, true)  # SERVICE only
#     startup_cpu_boost = optional(bool, false) # SERVICE only

#     ports = optional(list(object({
#       container_port = optional(number)
#       name           = optional(string)
#     })), [])

#     volume_mounts = optional(list(object({
#       sub_path   = optional(string)
#       name       = string
#       mount_path = string
#     })), [])

#     env = optional(list(object({
#       name  = string
#       value = optional(string)
#       value_source = optional(list(object({
#         secret_key_ref = list(object({
#           secret  = string
#           version = string
#         }))
#       })), [])
#     })), [])

#     # SERVICE only
#     readiness_probe = optional(list(object({
#       failure_threshold  = optional(number)
#       period_seconds      = optional(number)
#       success_threshold   = optional(number)
#       timeout_seconds      = optional(number)
#       grpc = optional(list(object({
#         port    = optional(number)
#         service = optional(string)
#       })), [])
#       http_get = optional(list(object({
#         path = optional(string)
#         port = optional(number)
#       })), [])
#     })), [])

#     # SERVICE only
#     liveness_probe = optional(list(object({
#       failure_threshold     = optional(number)
#       period_seconds         = optional(number)
#       timeout_seconds         = optional(number)
#       initial_delay_seconds   = optional(number)
#       grpc = optional(list(object({
#         port    = optional(number)
#         service = optional(string)
#       })), [])
#       http_get = optional(list(object({
#         path = optional(string)
#         port = optional(number)
#       })), [])
#       tcp_socket = optional(list(object({
#         port = optional(number)
#       })), [])
#     })), [])

#     # JOB and SERVICE
#     startup_probe = optional(list(object({
#       failure_threshold      = optional(number)
#       initial_delay_seconds   = optional(number)
#       period_seconds          = optional(number)
#       timeout_seconds          = optional(number)
#       grpc = optional(list(object({
#         port    = optional(number)
#         service = optional(string)
#       })), [])
#       http_get = optional(list(object({
#         path = optional(string)
#         port = optional(number)
#         http_headers = optional(list(object({
#           name  = string
#           value = optional(string)
#         })), [])
#       })), [])
#       tcp_socket = optional(list(object({
#         port = optional(number)
#       })), [])
#     })), [])
#   }))
# }

# variable "ingress" {
#   description = "Ingress settings for the service (SERVICE only)."
#   type        = string
#   default     = "INGRESS_TRAFFIC_ALL"
# }

# variable "custom_audiences" {
#   description = "List of custom audiences for the service (SERVICE only)."
#   type        = list(string)
#   default     = []
# }

# variable "default_uri_disabled" {
#   description = "Whether the default URI is disabled for the service (SERVICE only)."
#   type        = bool
#   default     = false
# }

# variable "description" {
#   description = "User-provided description of the service (SERVICE only)."
#   type        = string
#   default     = null
# }

# variable "iap_enabled" {
#   description = "Whether Identity-Aware Proxy is enabled for the service (SERVICE only)."
#   type        = bool
#   default     = false
# }

# variable "invoker_iam_disabled" {
#   description = "Whether the invoker IAM check is disabled for the service (SERVICE only)."
#   type        = bool
#   default     = false
# }

# variable "max_instance_request_concurrency" {
#   description = "Maximum number of concurrent requests per instance (SERVICE only)."
#   type        = number
#   default     = 80
# }

# variable "health_check_disabled" {
#   description = "Whether the automatic health check is disabled (SERVICE only)."
#   type        = bool
#   default     = false
# }

# variable "revision" {
#   description = "Revision name suffix for the service template (SERVICE only)."
#   type        = string
#   default     = null
# }

# variable "session_affinity" {
#   description = "Whether to enable session affinity for the service (SERVICE only)."
#   type        = bool
#   default     = false
# }

# variable "max_instance_count" {
#   description = "Maximum number of container instances (SERVICE only, scaling block)."
#   type        = number
#   default     = 100
# }

# variable "min_instance_count" {
#   description = "Minimum number of container instances (SERVICE only, scaling block)."
#   type        = number
#   default     = 0
# }

# variable "traffic" {
#   description = "Traffic split configuration for the service (SERVICE only)."
#   type = list(object({
#     traffic_type         = string
#     traffic_type_percent = optional(number)
#     revision             = optional(string)
#     tag                  = optional(string)
#   }))
#   default = []
# }

# variable "build_config" {
#   description = "Build configuration for source-based deployments (SERVICE only). Set to null to omit the block."
#   type = object({
#     base_image               = optional(string)
#     enable_automatic_updates = optional(bool)
#     environment_variables    = optional(map(string))
#     function_target          = optional(string)
#     image_uri                = optional(string)
#     service_account          = optional(string)
#     source_location          = optional(string)
#     worker_pool              = optional(string)
#   })
#   default = null
# }

# variable "multi_region_settings" {
#   description = "Multi-region settings for the service (SERVICE only). Set to null to omit the block."
#   type = object({
#     regions = list(string)
#   })
#   default = null
# }

# variable "conditions" {
#   description = "Condition to set/override on the service (SERVICE only). Set to null to omit the block."
#   type = object({
#     execution_reason     = optional(string)
#     last_transition_time = optional(string)
#     message               = optional(string)
#     reason                = optional(string)
#     revision_reason       = optional(string)
#     severity              = optional(string)
#     state                 = optional(string)
#     type                  = optional(string)
#   })
#   default = null
# }

# variable "scaling" {
#   description = "Scaling settings for the service (SERVICE only). Set to null to omit the block."
#   type = object({
#     manual_instance_count = optional(number)
#     max_instance_count    = optional(number)
#     min_instance_count    = optional(number)
#     scaling_mode          = optional(string)
#   })
#   default = null
# }

# variable "traffic_statuses" {
#   description = "Traffic status to set/override on the service (SERVICE only). Set to null to omit the block."
#   type = object({
#     percent  = optional(number)
#     revision = optional(string)
#     tag      = optional(string)
#     type     = optional(string)
#     uri      = optional(string)
#   })
#   default = null
# }

variable "type" {
  description = "Which Cloud Run v2 resource to create."
  type        = string
  validation {
    condition     = contains(["JOB", "SERVICE", "WORKER_POOL"], var.type)
    error_message = "var.type must be one of: JOB, SERVICE, WORKER_POOL."
  }
}

variable "name" {
  description = "Name of the Cloud Run resource."
  type        = string
}

variable "location" {
  description = "Region to deploy into, e.g. us-central1."
  type        = string
}

variable "project_id" {
  description = "Project the resource is created in."
  type        = string
}

variable "deletion_protection" {
  description = "Prevent accidental `terraform destroy` of this resource. Set false only for ephemeral/dev environments."
  type        = bool
  default     = true
}

variable "client" {
  description = "Client name performing the deployment (arbitrary, for annotation purposes)."
  type        = string
  default     = null
}

variable "client_version" {
  description = "Client version performing the deployment."
  type        = string
  default     = null
}

variable "launch_stage" {
  description = "Launch stage, e.g. GA, BETA, ALPHA. Worker pools currently require BETA or later."
  type        = string
  default     = "GA"
}

variable "annotations" {
  description = "Annotations to apply to the resource and its template."
  type        = map(string)
  default     = {}
}

variable "labels" {
  description = "Caller-supplied labels. Merged with the module's fixed baseline labels (application/managed_by/cost_center/compliance) in locals.common_labels."
  type        = map(string)
  default     = {}
}

variable "description" {
  description = "Human-readable description (service / worker pool only)."
  type        = string
  default     = null
}

variable "revision" {
  description = "Revision suffix (service / worker pool only)."
  type        = string
  default     = null
}

variable "binary_authorization" {
  description = "Binary Authorization settings. Not supported on worker pools."
  type = object({
    breakglass_justification = optional(string)
    policy                   = optional(string)
    use_default              = optional(bool)
  })
  default = null
}

# --- JOB-only -----------------------------------------------------------

variable "parallelism" {
  description = "Number of tasks that may run in parallel (job only)."
  type        = number
  default     = 1
}

variable "task_count" {
  description = "Number of tasks the job runs (job only)."
  type        = number
  default     = 1
}

variable "max_retries" {
  description = "Max retries per task before the job is marked failed (job only)."
  type        = number
  default     = 3
}

# --- SERVICE-only ---------------------------------------------------------

variable "ingress" {
  description = "Ingress traffic setting (service only), e.g. INGRESS_TRAFFIC_ALL, INGRESS_TRAFFIC_INTERNAL_ONLY."
  type        = string
  default     = "INGRESS_TRAFFIC_ALL"
}

variable "custom_audiences" {
  description = "Custom audiences for ID token validation (service / worker pool)."
  type        = list(string)
  default     = []
}

variable "invoker_iam_disabled" {
  description = "Disable IAM check for run.invoker on this service (service only). Leave false in production; grant roles/run.invoker via var.iam_members instead of disabling the check."
  type        = bool
  default     = false
}

variable "max_instance_request_concurrency" {
  description = "Max concurrent requests per instance (service only)."
  type        = number
  default     = 80
}

variable "session_affinity" {
  description = "Enable session affinity (service only)."
  type        = bool
  default     = false
}

variable "max_instance_count" {
  description = "Max autoscaling instance count (service only)."
  type        = number
  default     = 100
}

variable "min_instance_count" {
  description = "Min autoscaling instance count (service only)."
  type        = number
  default     = 0
}

variable "traffic" {
  description = "Traffic split configuration (service only)."
  type = list(object({
    traffic_type         = string
    traffic_type_percent = optional(number)
    revision             = optional(string)
    tag                  = optional(string)
  }))
  default = []
}

variable "build_config" {
  description = "Source-based build configuration (service only)."
  type = object({
    base_image               = optional(string)
    enable_automatic_updates = optional(bool)
    environment_variables    = optional(map(string))
    function_target          = optional(string)
    image_uri                = optional(string)
    service_account          = optional(string)
    source_location          = optional(string)
    worker_pool              = optional(string)
  })
  default = null
}

variable "scaling" {
  description = "Service scaling block (service only)."
  type = object({
    manual_instance_count = optional(number)
    min_instance_count    = optional(number)
    scaling_mode          = optional(string)
  })
  default = null
}

# --- WORKER_POOL-only -------------------------------------------------------

variable "worker_pool_scaling" {
  description = "Worker pool scaling settings. Worker pools currently only support MANUAL scaling."
  type = object({
    scaling_mode          = optional(string, "MANUAL")
    manual_instance_count = optional(number, 1)
    max_instance_count    = optional(number, 1)
    min_instance_count    = optional(number, 1)
  })
  default = {
    scaling_mode          = "MANUAL"
    manual_instance_count = 1
  }
}

# --- shared template settings ----------------------------------------------

variable "service_account" {
  description = "Email of an existing runtime service account. Leave null and set var.create_service_account = true to have the module create one for you."
  type        = string
  default     = null
}

variable "gpu_zonal_redundancy_disabled" {
  description = "Disable zonal redundancy when GPUs are attached."
  type        = bool
  default     = null
}

variable "execution_environment" {
  description = "EXECUTION_ENVIRONMENT_GEN1 or EXECUTION_ENVIRONMENT_GEN2 (job / service only)."
  type        = string
  default     = "EXECUTION_ENVIRONMENT_GEN2"
}

variable "encryption_key" {
  description = "CMEK key resource name to encrypt this resource."
  type        = string
  default     = null
}

variable "timeout" {
  description = "Request/task timeout, e.g. '300s' (job / service only)."
  type        = string
  default     = "300s"
}

variable "node_selector" {
  description = "Set to a non-null map (any values) to enable GPU node selection; actual accelerator type comes from var.accelerator."
  type        = map(string)
  default     = null
}

variable "accelerator" {
  description = "Accelerator type to request when var.node_selector is set, e.g. nvidia-l4."
  type        = string
  default     = null
}

variable "volumes" {
  description = "Volumes available to mount into containers."
  type        = any
  default     = []
}

variable "vpc_access" {
  description = "Direct VPC egress / VPC connector settings."
  type = object({
    vpc_connector_name = optional(string)
    egress             = optional(string)
    network_interfaces = optional(list(object({
      network    = optional(string)
      subnetwork = optional(string)
      tags       = optional(list(string))
    })), [])
  })
  default = null
}

variable "containers" {
  description = "List of containers to run. See the google_cloud_run_v2_service/job/worker_pool docs for the full nested shape (ports, env, probes, volume_mounts, resources, etc)."
  type        = any
}

# --- IAM ---------------------------------------------------------------

variable "create_service_account" {
  description = "If true, the module creates a dedicated runtime service account with baseline logging/monitoring/trace/artifact-registry roles instead of relying on the default compute SA."
  type        = bool
  default     = true
}

variable "service_account_id" {
  description = "Account ID for the module-managed service account. Defaults to '<name>-run-sa'. Ignored if var.create_service_account is false."
  type        = string
  default     = null
}

variable "service_account_roles" {
  description = "Extra project-level IAM roles to grant the module-managed service account, beyond the baseline logging/monitoring/trace/artifact-registry set."
  type        = list(string)
  default     = []
}

variable "iam_members" {
  description = "Resource-level IAM bindings applied to whichever resource var.type creates, e.g. [{ role = \"roles/run.invoker\", member = \"serviceAccount:caller@project.iam.gserviceaccount.com\" }]."
  type = list(object({
    role   = string
    member = string
  }))
  default = []
}
