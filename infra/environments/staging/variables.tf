variable "location" {
  type    = string
  default = "us-central1"
}

variable "backup_location" {
  type    = string
  default = "us-east1"
}

variable "project_id" {
  type    = string
  default = "encoded-alpha-457108-e8"
}

variable "public_subnets" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnets" {
  type    = list(string)
  default = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}