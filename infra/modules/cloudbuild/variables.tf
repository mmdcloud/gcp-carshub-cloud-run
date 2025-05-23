variable "source_uri" {}
variable "source_ref" {}
variable "repo_type" {}
variable "filename" {}
variable "location" {}
variable "trigger_name" {}
variable "service_account" {}
variable "repo_name" {}
variable "substitutions" {
  type = map(string)     
}