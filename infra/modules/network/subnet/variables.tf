variable "location" {}
variable "private_ip_google_access" {}
variable "subnets" {
  type = list(object({
    name          = string
    ip_cidr_range = string
  }))
}
variable "vpc_id" {}