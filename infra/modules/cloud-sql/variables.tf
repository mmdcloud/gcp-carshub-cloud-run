variable "name" {}
variable "location" {}
variable "db_name" {}
variable "db_version" {}
variable "tier" {}
variable "db_user" {}
variable "password" {}
variable "vpc_id" {}
variable "vpc_self_link" {}
variable "ipv4_enabled" {}
variable "deletion_protection_enabled" {}
variable "backup_configuration" {
    type = list(object({
        enabled = bool
        start_time = string
        location = string
        point_in_time_recovery_enabled = bool
        backup_retention_settings = list(object({
            retained_backups = number
            retention_unit = string
        }))
    }))     
}