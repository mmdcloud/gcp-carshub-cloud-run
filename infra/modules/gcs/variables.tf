variable "contents" {
  type = list(object({
    name        = string
    source_path = string
    content     = string
  }))
}
variable "location" {}
variable "name" {}
variable "versioning" {
  default = false
}
variable "lifecycle_rules" {
  type = list(object({
    action = object({
      type = string
      storage_class = string
    })
    condition = object({
      age = number
    })
  }))
  default = []
}
variable "force_destroy" {}
variable "notifications" {
  type = list(object({
    topic_id = string
  }))
  default = []
}
variable "uniform_bucket_level_access" {
  type    = bool
  default = true
}
# variable "contents" {
#   type = list(object({
#     name        = string
#     source_path = string
#     content     = string
#   }))
# }
variable "cors" {
  type = list(object({
    max_age_seconds = string
    method          = list(string)
    origin          = list(string)
    response_header = list(string)
  }))
}
