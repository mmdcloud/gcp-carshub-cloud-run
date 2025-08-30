variable "location" {
  type    = string
  default = "us-central1"
}

variable "backup_location" {
  type    = string
  default = "us-east1"
}

variable "project_id" {
  type        = string
  description = "GCP Project ID"
  default     = "encoded-alpha-457108-e8"
  # Remove default for production - must be explicitly set
}

variable "public_subnets" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnets" {
  type    = list(string)
  default = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}

# variable "domain_name" {
#   type        = string
#   description = "Domain name for SSL certificate"
# }

variable "notification_channel_email" {
  type        = string
  description = "Email notification channel for alerts"
  default     = "admin@mohitcloud.xyz"
}

variable "environment" {
  type        = string
  default     = "production"
  description = "Environment name"
}