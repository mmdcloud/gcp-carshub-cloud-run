variable "account_id" {}
variable "display_name" {}
variable "project_id" {}
variable "member_prefix" {}
variable "permissions" {
    type = list(string)
}