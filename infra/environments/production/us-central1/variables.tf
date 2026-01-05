variable "location" {
  type = string
}

variable "backup_location" {
  type = string
}

variable "project_id" {
  type        = string
  description = "GCP Project ID"
}

variable "public_subnets" {
  type = list(string)
}

variable "private_subnets" {
  type = list(string)
}

variable "notification_channel_email" {
  type        = string
  description = "Email notification channel for alerts"
}

variable "environment" {
  type        = string
  description = "Environment name"
}