# resource "google_cloud_run_v2_job" "job" {
#   count               = var.type == "JOB" ? 1 : 0
#   name                = var.name
#   location            = var.location
#   deletion_protection = var.deletion_protection
#   client              = var.client
#   client_version      = var.client_version
#   launch_stage        = var.launch_stage
#   project             = var.project_id
#   annotations         = var.annotations
#   labels              = var.labels

#   dynamic "binary_authorization" {
#     for_each = var.binary_authorization != null ? [var.binary_authorization] : []
#     content {
#       breakglass_justification = binary_authorization.value.breakglass_justification
#       policy                   = binary_authorization.value.policy
#       use_default              = binary_authorization.value.useuse_default
#     }
#   }

#   template {
#     annotations = var.annotations
#     labels      = var.labels
#     parallelism = var.parallelism
#     task_count  = var.task_count

#     template {
#       service_account               = var.service_account
#       gpu_zonal_redundancy_disabled = var.gpu_zonal_redundancy_disabled
#       execution_environment         = var.execution_environment
#       max_retries                   = var.max_retries
#       encryption_key                = var.encryption_key
#       timeout                       = var.timeout

#       dynamic "node_selector" {
#         for_each = var.node_selector != null ? [var.node_selector] : []
#         content {
#           accelerator = var.accelerator
#         }
#       }

#       dynamic "volumes" {
#         for_each = var.volumes
#         content {
#           name = volumes.value.name

#           dynamic "cloud_sql_instance" {
#             for_each = volumes.value.cloud_sql_instance != null ? [volumes.value.cloud_sql_instance] : []
#             content {
#               instances = cloud_sql_instance.value.instances
#             }
#           }

#           dynamic "empty_dir" {
#             for_each = volumes.value.empty_dir != null ? [volumes.value.empty_dir] : []
#             content {
#               medium     = empty_dir.value.medium
#               size_limit = empty_dir.value.size_limit
#             }
#           }

#           dynamic "gcs" {
#             for_each = volumes.value.gcs != null ? [volumes.value.gcs] : []
#             content {
#               bucket        = gcs.value.bucket
#               read_only     = gcs.value.read_only
#             }
#           }

#           dynamic "nfs" {
#             for_each = volumes.value.nfs != null ? [volumes.value.nfs] : []
#             content {
#               path      = nfs.value.path
#               read_only = nfs.value.read_only
#               server    = nfs.value.server
#             }
#           }

#           dynamic "secret" {
#             for_each = volumes.value.secret != null ? [volumes.value.secret] : []
#             content {
#               default_mode = secret.value.default_mode
#               secret       = secret.value.secret

#               dynamic "items" {
#                 for_each = secret.value.items
#                 content {
#                   mode    = items.value.mode
#                   path    = items.value.path
#                   version = items.value.version
#                 }
#               }
#             }
#           }
#         }
#       }

#       dynamic "vpc_access" {
#       for_each = var.vpc_access != null ? [var.vpc_access] : []
#       content {
#         connector = vpc_access.value.vpc_connector_name
#         egress    = vpc_access.value.egress
#         # "ALL_TRAFFIC"
#         dynamic "network_interfaces" {
#           for_each = vpc_access.value.network_interfaces
#           content {
#             network    = network_interfaces.value.network
#             subnetwork = network_interfaces.value.subnetwork
#             tags       = network_interfaces.value.tags
#           }
#         }
#       }
#     }

#       dynamic "containers" {
#         for_each = var.containers
#         content {
#           name        = containers.value.name
#           image       = containers.value.image
#           args        = containers.value.args
#           command     = containers.value.command
#           working_dir = containers.value.working_dir

#           resources {
#             limits = containers.value.limits
#           }

#           dynamic "ports" {
#             for_each = containers.value.ports
#             content {
#               container_port = ports.value.container_port
#               name           = ports.value.name
#             }
#           }

#           dynamic "startup_probe" {
#             for_each = containers.value.startup_probe
#             content {
#               failure_threshold     = startup_probe.value.failure_threshold
#               initial_delay_seconds = startup_probe.value.initial_delay_seconds
#               period_seconds        = startup_probe.value.period_seconds
#               timeout_seconds       = startup_probe.value.timeout_seconds

#               dynamic "grpc" {
#                 for_each = startup_probe.value.grpc
#                 content {
#                   port    = grpc.value.port
#                   service = grpc.value.service
#                 }
#               }

#               dynamic "http_get" {
#                 for_each = startup_probe.value.http_get
#                 content {
#                   path = http_get.value.path
#                   port = http_get.value.port
#                   dynamic "http_headers" {
#                     for_each = http_get.value.http_headers
#                     content {
#                       name  = http_headers.value.name
#                       value = http_headers.value.value
#                     }
#                   }
#                 }
#               }

#               dynamic "tcp_socket" {
#                 for_each = startup_probe.value.tcp_socket
#                 content {
#                   port = tcp_socket.value.port
#                 }
#               }
#             }
#           }

#           dynamic "volume_mounts" {
#             for_each = containers.value["volume_mounts"]
#             content {
#               name       = volume_mounts.value.name
#               mount_path = volume_mounts.value.mount_path
#             }
#           }

#           dynamic "env" {
#             for_each = containers.value.env
#             content {
#               name  = env.value["name"]
#               value = env.value["value"]

#               dynamic "value_source" {
#                 for_each = env.value["value_source"]
#                 content {
#                   dynamic "secret_key_ref" {
#                     for_each = value_source.value["secret_key_ref"]
#                     content {
#                       secret  = secret_key_ref.value["secret"]
#                       version = secret_key_ref.value["version"]
#                     }
#                   }
#                 }
#               }
#             }
#           }
#         }
#       }
#     }
#   }
# }

# resource "google_cloud_run_v2_service" "cloud_run_service" {
#   count                = var.type == "SERVICE" ? 1 : 0
#   name                 = var.name
#   location             = var.location
#   deletion_protection  = var.deletion_protection
#   ingress              = var.ingress
#   custom_audiences     = var.custom_audiences
#   client               = var.client
#   client_version       = var.client_version
#   description          = var.description
#   invoker_iam_disabled = var.invoker_iam_disabled
#   launch_stage         = var.launch_stage
#   project              = var.project_id
#   annotations          = var.annotations

#   template {
#     service_account                  = var.service_account
#     max_instance_request_concurrency = var.max_instance_request_concurrency
#     gpu_zonal_redundancy_disabled    = var.gpu_zonal_redundancy_disabled
#     execution_environment            = var.execution_environment
#     encryption_key                   = var.encryption_key
#     labels                           = var.labels
#     revision                         = var.revision
#     session_affinity                 = var.session_affinity
#     timeout                          = var.timeout
#     annotations                      = var.annotations

#     scaling {
#       max_instance_count = var.max_instance_count
#       min_instance_count = var.min_instance_count
#     }

#     dynamic "volumes" {
#       for_each = var.volumes
#       content {
#         name = volumes.value.name

#         dynamic "cloud_sql_instance" {
#           for_each = volumes.value.cloud_sql_instance != null ? [volumes.value.cloud_sql_instance] : []
#           content {
#             instances = cloud_sql_instance.value.instances
#           }
#         }

#         dynamic "empty_dir" {
#           for_each = volumes.value.empty_dir != null ? [volumes.value.empty_dir] : []
#           content {
#             medium     = empty_dir.value.medium
#             size_limit = empty_dir.value.size_limit
#           }
#         }

#         dynamic "gcs" {
#           for_each = volumes.value.gcs != null ? [volumes.value.gcs] : []
#           content {
#             bucket        = gcs.value.bucket
#             read_only     = gcs.value.read_only
#           }
#         }

#         dynamic "nfs" {
#           for_each = volumes.value.nfs != null ? [volumes.value.nfs] : []
#           content {
#             path      = nfs.value.path
#             read_only = nfs.value.read_only
#             server    = nfs.value.server
#           }
#         }

#         dynamic "secret" {
#           for_each = volumes.value.secret != null ? [volumes.value.secret] : []
#           content {
#             default_mode = secret.value.default_mode
#             secret       = secret.value.secret

#             dynamic "items" {
#               for_each = secret.value.items
#               content {
#                 mode    = items.value.mode
#                 path    = items.value.path
#                 version = items.value.version
#               }
#             }
#           }
#         }
#       }
#     }

#     dynamic "vpc_access" {
#       for_each = var.vpc_access != null ? [var.vpc_access] : []
#       content {
#         connector = vpc_access.value.vpc_connector_name
#         egress    = vpc_access.value.egress
#         # "ALL_TRAFFIC"
#         dynamic "network_interfaces" {
#           for_each = vpc_access.value.network_interfaces
#           content {
#             network    = network_interfaces.value.network
#             subnetwork = network_interfaces.value.subnetwork
#             tags       = network_interfaces.value.tags
#           }
#         }
#       }
#     }

#     dynamic "node_selector" {
#       for_each = var.node_selector != null ? [var.node_selector] : []
#       content {
#         accelerator = var.accelerator
#       }
#     }

#     dynamic "containers" {
#       for_each = var.containers
#       content {
#         name           = containers.value.name
#         image          = containers.value.image
#         args           = containers.value.args
#         command        = containers.value.command
#         working_dir    = containers.value.working_dir
#         base_image_uri = containers.value.base_image_uri

#         resources {
#           cpu_idle          = containers.value["cpu_idle"]
#           startup_cpu_boost = containers.value["startup_cpu_boost"]
#         }

#         dynamic "ports" {
#           for_each = containers.value.ports
#           content {
#             container_port = ports.value.container_port
#             name           = ports.value.name
#           }
#         }

#         # dynamic "readiness_probe" {
#         #   for_each = containers.value.readiness_probe
#         #   content {
#         #     failure_threshold = readiness_probe.value.failure_threshold
#         #     period_seconds    = readiness_probe.value.period_seconds
#         #     success_threshold = readiness_probe.value.success_threshold
#         #     timeout_seconds   = readiness_probe.value.timeout_seconds

#         #     dynamic "grpc" {
#         #       for_each = readiness_probe.value.grpc
#         #       content {
#         #         port    = grpc.value.port
#         #         service = grpc.value.service
#         #       }
#         #     }

#         #     dynamic "http_get" {
#         #       for_each = readiness_probe.value.http_get
#         #       content {
#         #         path = http_get.value.path
#         #         port = http_get.value.port
#         #       }
#         #     }
#         #   }
#         # }

#         dynamic "liveness_probe" {
#           for_each = containers.value.liveness_probe
#           content {
#             failure_threshold     = liveness_probe.value.failure_threshold
#             period_seconds        = liveness_probe.value.period_seconds
#             timeout_seconds       = liveness_probe.value.timeout_seconds
#             initial_delay_seconds = liveness_probe.value.initial_delay_seconds

#             dynamic "grpc" {
#               for_each = liveness_probe.value.grpc
#               content {
#                 port    = grpc.value.port
#                 service = grpc.value.service
#               }
#             }

#             dynamic "http_get" {
#               for_each = liveness_probe.value.http_get
#               content {
#                 path = http_get.value.path
#                 port = http_get.value.port
#               }
#             }

#             dynamic "tcp_socket" {
#               for_each = liveness_probe.value.tcp_socket
#               content {
#                 port = tcp_socket.value.port
#               }
#             }
#           }
#         }

#         dynamic "startup_probe" {
#           for_each = containers.value.startup_probe
#           content {
#             failure_threshold     = startup_probe.value.failure_threshold
#             initial_delay_seconds = startup_probe.value.initial_delay_seconds
#             period_seconds        = startup_probe.value.period_seconds
#             timeout_seconds       = startup_probe.value.timeout_seconds

#             dynamic "grpc" {
#               for_each = startup_probe.value.grpc
#               content {
#                 port    = grpc.value.port
#                 service = grpc.value.service
#               }
#             }

#             dynamic "http_get" {
#               for_each = startup_probe.value.http_get
#               content {
#                 path = http_get.value.path
#                 port = http_get.value.port
#                 dynamic "http_headers" {
#                   for_each = http_get.value.http_headers
#                   content {
#                     name  = http_headers.value.name
#                     value = http_headers.value.value
#                   }
#                 }
#               }
#             }

#             dynamic "tcp_socket" {
#               for_each = startup_probe.value.tcp_socket
#               content {
#                 port = tcp_socket.value.port
#               }
#             }
#           }
#         }

#         dynamic "volume_mounts" {
#           for_each = containers.value.volume_mounts
#           content {
#             name       = volume_mounts.value.name
#             mount_path = volume_mounts.value.mount_path
#           }
#         }

#         dynamic "env" {
#           for_each = containers.value.env
#           content {
#             name  = env.value.name
#             value = env.value.value

#             dynamic "value_source" {
#               for_each = env.value.value_source
#               content {
#                 dynamic "secret_key_ref" {
#                   for_each = value_source.value.secret_key_ref
#                   content {
#                     secret  = secret_key_ref.value.secret
#                     version = secret_key_ref.value.version
#                   }
#                 }
#               }
#             }
#           }
#         }
#       }
#     }
#   }

#   dynamic "traffic" {
#     for_each = var.traffic
#     content {
#       type     = traffic.value.traffic_type
#       percent  = traffic.value.traffic_type_percent
#       revision = traffic.value.revision
#       tag      = traffic.value.tag
#     }
#   }

#   dynamic "binary_authorization" {
#     for_each = var.binary_authorization != null ? [var.binary_authorization] : []
#     content {
#       breakglass_justification = binary_authorization.value.breakglass_justification
#       policy                   = binary_authorization.value.policy
#       use_default              = binary_authorization.value.useuse_default
#     }
#   }

#   dynamic "build_config" {
#     for_each = var.build_config != null ? [var.build_config] : []
#     content {
#       base_image               = build_config.value.base_image
#       enable_automatic_updates = build_config.value.enable_automatic_updates
#       environment_variables    = build_config.value.environment_variables
#       function_target          = build_config.value.function_target
#       image_uri                = build_config.value.image_uri
#       service_account          = build_config.value.service_account
#       source_location          = build_config.value.source_location
#       worker_pool              = build_config.value.worker_pool
#     }
#   }

#   # dynamic "multi_region_settings" {
#   #   for_each = var.multi_region_settings != null ? [var.multi_region_settings] : []
#   #   content {
#   #     regions = multi_region_settings.value.regions
#   #   }
#   # }

#   dynamic "scaling" {
#     for_each = var.scaling != null ? [var.scaling] : []
#     content {
#       manual_instance_count = scaling.value.manual_instance_count
#       min_instance_count    = scaling.value.min_instance_count
#       scaling_mode          = scaling.value.scaling_mode
#     }
#   }

#   labels = merge(
#     var.labels,
#     {
#       application = "carshub"
#       managed_by  = "terraform"
#       cost_center = "engineering"
#       compliance  = "pci-dss"
#     }
#   )
# }
locals {
  common_labels = merge(
    var.labels,
    {
      application = "carshub"
      managed_by  = "terraform"
      cost_center = "engineering"
      compliance  = "pci-dss"
    }
  )
}

resource "google_cloud_run_v2_job" "job" {
  count               = var.type == "JOB" ? 1 : 0
  name                = var.name
  location            = var.location
  deletion_protection = var.deletion_protection
  client              = var.client
  client_version      = var.client_version
  launch_stage        = var.launch_stage
  project             = var.project_id
  annotations         = var.annotations
  labels              = local.common_labels

  dynamic "binary_authorization" {
    for_each = var.binary_authorization != null ? [var.binary_authorization] : []
    content {
      breakglass_justification = binary_authorization.value.breakglass_justification
      policy                   = binary_authorization.value.policy
      use_default              = binary_authorization.value.use_default
    }
  }

  template {
    annotations = var.annotations
    labels      = local.common_labels
    parallelism = var.parallelism
    task_count  = var.task_count

    template {
      service_account               = var.service_account != null ? var.service_account : (var.create_service_account ? google_service_account.cloud_run_sa[0].email : null)
      gpu_zonal_redundancy_disabled = var.gpu_zonal_redundancy_disabled
      execution_environment         = var.execution_environment
      max_retries                   = var.max_retries
      encryption_key                = var.encryption_key
      timeout                       = var.timeout

      dynamic "node_selector" {
        for_each = var.node_selector != null ? [var.node_selector] : []
        content {
          accelerator = var.accelerator
        }
      }

      dynamic "volumes" {
        for_each = var.volumes
        content {
          name = volumes.value.name

          dynamic "cloud_sql_instance" {
            for_each = volumes.value.cloud_sql_instance != null ? [volumes.value.cloud_sql_instance] : []
            content {
              instances = cloud_sql_instance.value.instances
            }
          }

          dynamic "empty_dir" {
            for_each = volumes.value.empty_dir != null ? [volumes.value.empty_dir] : []
            content {
              medium     = empty_dir.value.medium
              size_limit = empty_dir.value.size_limit
            }
          }

          dynamic "gcs" {
            for_each = volumes.value.gcs != null ? [volumes.value.gcs] : []
            content {
              bucket    = gcs.value.bucket
              read_only = gcs.value.read_only
            }
          }

          dynamic "nfs" {
            for_each = volumes.value.nfs != null ? [volumes.value.nfs] : []
            content {
              path      = nfs.value.path
              read_only = nfs.value.read_only
              server    = nfs.value.server
            }
          }

          dynamic "secret" {
            for_each = volumes.value.secret != null ? [volumes.value.secret] : []
            content {
              default_mode = secret.value.default_mode
              secret       = secret.value.secret

              dynamic "items" {
                for_each = secret.value.items
                content {
                  mode    = items.value.mode
                  path    = items.value.path
                  version = items.value.version
                }
              }
            }
          }
        }
      }

      dynamic "vpc_access" {
        for_each = var.vpc_access != null ? [var.vpc_access] : []
        content {
          connector = vpc_access.value.vpc_connector_name
          egress    = vpc_access.value.egress
          # "ALL_TRAFFIC"
          dynamic "network_interfaces" {
            for_each = vpc_access.value.network_interfaces
            content {
              network    = network_interfaces.value.network
              subnetwork = network_interfaces.value.subnetwork
              tags       = network_interfaces.value.tags
            }
          }
        }
      }

      dynamic "containers" {
        for_each = var.containers
        content {
          name        = containers.value.name
          image       = containers.value.image
          args        = containers.value.args
          command     = containers.value.command
          working_dir = containers.value.working_dir

          resources {
            limits = containers.value.limits
          }

          dynamic "ports" {
            for_each = containers.value.ports
            content {
              container_port = ports.value.container_port
              name           = ports.value.name
            }
          }

          dynamic "startup_probe" {
            for_each = containers.value.startup_probe
            content {
              failure_threshold     = startup_probe.value.failure_threshold
              initial_delay_seconds = startup_probe.value.initial_delay_seconds
              period_seconds        = startup_probe.value.period_seconds
              timeout_seconds       = startup_probe.value.timeout_seconds

              dynamic "grpc" {
                for_each = startup_probe.value.grpc
                content {
                  port    = grpc.value.port
                  service = grpc.value.service
                }
              }

              dynamic "http_get" {
                for_each = startup_probe.value.http_get
                content {
                  path = http_get.value.path
                  port = http_get.value.port
                  dynamic "http_headers" {
                    for_each = http_get.value.http_headers
                    content {
                      name  = http_headers.value.name
                      value = http_headers.value.value
                    }
                  }
                }
              }

              dynamic "tcp_socket" {
                for_each = startup_probe.value.tcp_socket
                content {
                  port = tcp_socket.value.port
                }
              }
            }
          }

          dynamic "volume_mounts" {
            for_each = containers.value["volume_mounts"]
            content {
              name       = volume_mounts.value.name
              mount_path = volume_mounts.value.mount_path
            }
          }

          dynamic "env" {
            for_each = containers.value.env
            content {
              name  = env.value["name"]
              value = env.value["value"]

              dynamic "value_source" {
                for_each = env.value["value_source"]
                content {
                  dynamic "secret_key_ref" {
                    for_each = value_source.value["secret_key_ref"]
                    content {
                      secret  = secret_key_ref.value["secret"]
                      version = secret_key_ref.value["version"]
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}

resource "google_cloud_run_v2_service" "cloud_run_service" {
  count                = var.type == "SERVICE" ? 1 : 0
  name                 = var.name
  location             = var.location
  deletion_protection  = var.deletion_protection
  ingress              = var.ingress
  custom_audiences     = var.custom_audiences
  client               = var.client
  client_version       = var.client_version
  description          = var.description
  invoker_iam_disabled = var.invoker_iam_disabled
  launch_stage         = var.launch_stage
  project              = var.project_id
  annotations          = var.annotations

  template {
    service_account                  = var.service_account != null ? var.service_account : (var.create_service_account ? google_service_account.cloud_run_sa[0].email : null)
    max_instance_request_concurrency = var.max_instance_request_concurrency
    gpu_zonal_redundancy_disabled    = var.gpu_zonal_redundancy_disabled
    execution_environment            = var.execution_environment
    encryption_key                   = var.encryption_key
    labels                           = local.common_labels
    revision                         = var.revision
    session_affinity                 = var.session_affinity
    timeout                          = var.timeout
    annotations                      = var.annotations

    scaling {
      max_instance_count = var.max_instance_count
      min_instance_count = var.min_instance_count
    }

    dynamic "volumes" {
      for_each = var.volumes
      content {
        name = volumes.value.name

        dynamic "cloud_sql_instance" {
          for_each = volumes.value.cloud_sql_instance != null ? [volumes.value.cloud_sql_instance] : []
          content {
            instances = cloud_sql_instance.value.instances
          }
        }

        dynamic "empty_dir" {
          for_each = volumes.value.empty_dir != null ? [volumes.value.empty_dir] : []
          content {
            medium     = empty_dir.value.medium
            size_limit = empty_dir.value.size_limit
          }
        }

        dynamic "gcs" {
          for_each = volumes.value.gcs != null ? [volumes.value.gcs] : []
          content {
            bucket    = gcs.value.bucket
            read_only = gcs.value.read_only
          }
        }

        dynamic "nfs" {
          for_each = volumes.value.nfs != null ? [volumes.value.nfs] : []
          content {
            path      = nfs.value.path
            read_only = nfs.value.read_only
            server    = nfs.value.server
          }
        }

        dynamic "secret" {
          for_each = volumes.value.secret != null ? [volumes.value.secret] : []
          content {
            default_mode = secret.value.default_mode
            secret       = secret.value.secret

            dynamic "items" {
              for_each = secret.value.items
              content {
                mode    = items.value.mode
                path    = items.value.path
                version = items.value.version
              }
            }
          }
        }
      }
    }

    dynamic "vpc_access" {
      for_each = var.vpc_access != null ? [var.vpc_access] : []
      content {
        connector = vpc_access.value.vpc_connector_name
        egress    = vpc_access.value.egress
        # "ALL_TRAFFIC"
        dynamic "network_interfaces" {
          for_each = vpc_access.value.network_interfaces
          content {
            network    = network_interfaces.value.network
            subnetwork = network_interfaces.value.subnetwork
            tags       = network_interfaces.value.tags
          }
        }
      }
    }

    dynamic "node_selector" {
      for_each = var.node_selector != null ? [var.node_selector] : []
      content {
        accelerator = var.accelerator
      }
    }

    dynamic "containers" {
      for_each = var.containers
      content {
        name           = containers.value.name
        image          = containers.value.image
        args           = containers.value.args
        command        = containers.value.command
        working_dir    = containers.value.working_dir
        base_image_uri = containers.value.base_image_uri

        resources {
          cpu_idle          = containers.value["cpu_idle"]
          startup_cpu_boost = containers.value["startup_cpu_boost"]
        }

        dynamic "ports" {
          for_each = containers.value.ports
          content {
            container_port = ports.value.container_port
            name           = ports.value.name
          }
        }

        dynamic "liveness_probe" {
          for_each = containers.value.liveness_probe
          content {
            failure_threshold     = liveness_probe.value.failure_threshold
            period_seconds        = liveness_probe.value.period_seconds
            timeout_seconds       = liveness_probe.value.timeout_seconds
            initial_delay_seconds = liveness_probe.value.initial_delay_seconds

            dynamic "grpc" {
              for_each = liveness_probe.value.grpc
              content {
                port    = grpc.value.port
                service = grpc.value.service
              }
            }

            dynamic "http_get" {
              for_each = liveness_probe.value.http_get
              content {
                path = http_get.value.path
                port = http_get.value.port
              }
            }

            dynamic "tcp_socket" {
              for_each = liveness_probe.value.tcp_socket
              content {
                port = tcp_socket.value.port
              }
            }
          }
        }

        dynamic "startup_probe" {
          for_each = containers.value.startup_probe
          content {
            failure_threshold     = startup_probe.value.failure_threshold
            initial_delay_seconds = startup_probe.value.initial_delay_seconds
            period_seconds        = startup_probe.value.period_seconds
            timeout_seconds       = startup_probe.value.timeout_seconds

            dynamic "grpc" {
              for_each = startup_probe.value.grpc
              content {
                port    = grpc.value.port
                service = grpc.value.service
              }
            }

            dynamic "http_get" {
              for_each = startup_probe.value.http_get
              content {
                path = http_get.value.path
                port = http_get.value.port
                dynamic "http_headers" {
                  for_each = http_get.value.http_headers
                  content {
                    name  = http_headers.value.name
                    value = http_headers.value.value
                  }
                }
              }
            }

            dynamic "tcp_socket" {
              for_each = startup_probe.value.tcp_socket
              content {
                port = tcp_socket.value.port
              }
            }
          }
        }

        dynamic "volume_mounts" {
          for_each = containers.value.volume_mounts
          content {
            name       = volume_mounts.value.name
            mount_path = volume_mounts.value.mount_path
          }
        }

        dynamic "env" {
          for_each = containers.value.env
          content {
            name  = env.value.name
            value = env.value.value

            dynamic "value_source" {
              for_each = env.value.value_source
              content {
                dynamic "secret_key_ref" {
                  for_each = value_source.value.secret_key_ref
                  content {
                    secret  = secret_key_ref.value.secret
                    version = secret_key_ref.value.version
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  dynamic "traffic" {
    for_each = var.traffic
    content {
      type     = traffic.value.traffic_type
      percent  = traffic.value.traffic_type_percent
      revision = traffic.value.revision
      tag      = traffic.value.tag
    }
  }

  dynamic "binary_authorization" {
    for_each = var.binary_authorization != null ? [var.binary_authorization] : []
    content {
      breakglass_justification = binary_authorization.value.breakglass_justification
      policy                   = binary_authorization.value.policy
      use_default              = binary_authorization.value.use_default
    }
  }

  dynamic "build_config" {
    for_each = var.build_config != null ? [var.build_config] : []
    content {
      base_image               = build_config.value.base_image
      enable_automatic_updates = build_config.value.enable_automatic_updates
      environment_variables    = build_config.value.environment_variables
      function_target          = build_config.value.function_target
      image_uri                = build_config.value.image_uri
      service_account          = build_config.value.service_account
      source_location          = build_config.value.source_location
      worker_pool              = build_config.value.worker_pool
    }
  }

  dynamic "scaling" {
    for_each = var.scaling != null ? [var.scaling] : []
    content {
      manual_instance_count = scaling.value.manual_instance_count
      min_instance_count    = scaling.value.min_instance_count
      scaling_mode          = scaling.value.scaling_mode
    }
  }

  labels = local.common_labels
}

# ---------------------------------------------------------------------------
# google_cloud_run_v2_worker_pool
#
# Worker pools run containers that are NOT invoked over HTTP/gRPC (background
# workers, queue consumers, etc). They share the same container / volume /
# vpc_access / node_selector inputs as the job and service resources above so
# callers configure one module regardless of which `var.type` they pick.
#
# NOTE: the Worker Pool API is BETA. Field availability can change between
# provider releases, so pin the google provider version and re-check
# `terraform providers schema -json | jq '.provider_schemas[...].resource_schemas.google_cloud_run_v2_worker_pool'`
# before relying on any field not exercised here.
# ---------------------------------------------------------------------------
resource "google_cloud_run_v2_worker_pool" "worker_pool" {
  count        = var.type == "WORKER_POOL" ? 1 : 0
  name         = var.name
  location     = var.location
  project      = var.project_id
  launch_stage = var.launch_stage

  client         = var.client
  client_version = var.client_version
  description    = var.description

  deletion_protection = var.deletion_protection
  annotations         = var.annotations
  labels              = local.common_labels

  template {
    service_account               = var.service_account != null ? var.service_account : (var.create_service_account ? google_service_account.cloud_run_sa[0].email : null)
    encryption_key                = var.encryption_key
    gpu_zonal_redundancy_disabled = var.gpu_zonal_redundancy_disabled
    annotations                   = var.annotations
    labels                        = local.common_labels
    revision                      = var.revision

    dynamic "node_selector" {
      for_each = var.node_selector != null ? [var.node_selector] : []
      content {
        accelerator = var.accelerator
      }
    }

    dynamic "volumes" {
      for_each = var.volumes
      content {
        name = volumes.value.name

        dynamic "cloud_sql_instance" {
          for_each = volumes.value.cloud_sql_instance != null ? [volumes.value.cloud_sql_instance] : []
          content {
            instances = cloud_sql_instance.value.instances
          }
        }

        dynamic "empty_dir" {
          for_each = volumes.value.empty_dir != null ? [volumes.value.empty_dir] : []
          content {
            medium     = empty_dir.value.medium
            size_limit = empty_dir.value.size_limit
          }
        }

        dynamic "gcs" {
          for_each = volumes.value.gcs != null ? [volumes.value.gcs] : []
          content {
            bucket    = gcs.value.bucket
            read_only = gcs.value.read_only
          }
        }

        dynamic "nfs" {
          for_each = volumes.value.nfs != null ? [volumes.value.nfs] : []
          content {
            path      = nfs.value.path
            read_only = nfs.value.read_only
            server    = nfs.value.server
          }
        }

        dynamic "secret" {
          for_each = volumes.value.secret != null ? [volumes.value.secret] : []
          content {
            default_mode = secret.value.default_mode
            secret       = secret.value.secret

            dynamic "items" {
              for_each = secret.value.items
              content {
                mode    = items.value.mode
                path    = items.value.path
                version = items.value.version
              }
            }
          }
        }
      }
    }

    dynamic "vpc_access" {
      for_each = var.vpc_access != null ? [var.vpc_access] : []
      content {
        connector = vpc_access.value.vpc_connector_name
        egress    = vpc_access.value.egress

        dynamic "network_interfaces" {
          for_each = vpc_access.value.network_interfaces
          content {
            network    = network_interfaces.value.network
            subnetwork = network_interfaces.value.subnetwork
            tags       = network_interfaces.value.tags
          }
        }
      }
    }

    dynamic "containers" {
      for_each = var.containers
      content {
        name        = containers.value.name
        image       = containers.value.image
        args        = containers.value.args
        command     = containers.value.command
        working_dir = containers.value.working_dir

        resources {
          limits = containers.value.limits
        }

        dynamic "liveness_probe" {
          for_each = containers.value.liveness_probe
          content {
            failure_threshold     = liveness_probe.value.failure_threshold
            period_seconds        = liveness_probe.value.period_seconds
            timeout_seconds       = liveness_probe.value.timeout_seconds
            initial_delay_seconds = liveness_probe.value.initial_delay_seconds

            dynamic "grpc" {
              for_each = liveness_probe.value.grpc
              content {
                port    = grpc.value.port
                service = grpc.value.service
              }
            }

            dynamic "http_get" {
              for_each = liveness_probe.value.http_get
              content {
                path = http_get.value.path
                port = http_get.value.port
              }
            }

            dynamic "tcp_socket" {
              for_each = liveness_probe.value.tcp_socket
              content {
                port = tcp_socket.value.port
              }
            }
          }
        }

        dynamic "startup_probe" {
          for_each = containers.value.startup_probe
          content {
            failure_threshold     = startup_probe.value.failure_threshold
            initial_delay_seconds = startup_probe.value.initial_delay_seconds
            period_seconds        = startup_probe.value.period_seconds
            timeout_seconds       = startup_probe.value.timeout_seconds

            dynamic "grpc" {
              for_each = startup_probe.value.grpc
              content {
                port    = grpc.value.port
                service = grpc.value.service
              }
            }

            dynamic "http_get" {
              for_each = startup_probe.value.http_get
              content {
                path = http_get.value.path
                port = http_get.value.port
                dynamic "http_headers" {
                  for_each = http_get.value.http_headers
                  content {
                    name  = http_headers.value.name
                    value = http_headers.value.value
                  }
                }
              }
            }

            dynamic "tcp_socket" {
              for_each = startup_probe.value.tcp_socket
              content {
                port = tcp_socket.value.port
              }
            }
          }
        }

        dynamic "volume_mounts" {
          for_each = containers.value["volume_mounts"]
          content {
            name       = volume_mounts.value.name
            mount_path = volume_mounts.value.mount_path
          }
        }

        dynamic "env" {
          for_each = containers.value.env
          content {
            name  = env.value["name"]
            value = env.value["value"]

            dynamic "value_source" {
              for_each = env.value["value_source"]
              content {
                dynamic "secret_key_ref" {
                  for_each = value_source.value["secret_key_ref"]
                  content {
                    secret  = secret_key_ref.value["secret"]
                    version = secret_key_ref.value["version"]
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  dynamic "binary_authorization" {
    for_each = var.binary_authorization != null ? [var.binary_authorization] : []
    content {
      breakglass_justification = binary_authorization.value.breakglass_justification
      policy                   = binary_authorization.value.policy
      use_default              = binary_authorization.value.use_default
    }
  }

  # Worker pools only support MANUAL scaling today; min/max autoscaling
  # fields are reserved here for forward-compat but only wired up if your
  # provider version's schema exposes them (guard with `try()` if needed).
  scaling {
    scaling_mode          = coalesce(try(var.worker_pool_scaling.scaling_mode, null), "MANUAL")
    manual_instance_count = try(var.worker_pool_scaling.manual_instance_count, 1)
    max_instance_count    = var.max_instance_count
    min_instance_count    = var.min_instance_count
  }
}