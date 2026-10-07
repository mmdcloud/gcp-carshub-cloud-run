variable "location" {
  type = string
}

variable "project_id" {
  type        = string
  description = "GCP Project ID"
}

variable "notification_channel_email" {
  type        = string
  description = "Email notification channel for alerts"
}

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "frontend_image" {
  type    = string
  default = "us-docker.pkg.dev/cloudrun/container/hello"
}
variable "backend_image" {
  type    = string
  default = "us-docker.pkg.dev/cloudrun/container/hello"
}