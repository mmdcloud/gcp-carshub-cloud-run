variable "name" {}
variable "description" {}
variable "rules" {
  description = "List of rules to be added to the security policy"
  type = list(object({
    priority      = number
    action        = string
    description   = string
    src_ip_ranges = list(string)
    expression    = string
    preview       = bool
  }))
  default = []
}
# variable "rate_limit_options" {
#   type = object({
#     rate_limit_threshold = object({
#       count        = number
#       interval_sec = number
#     })
#     conform_action = string
#     exceed_action  = string
#     enforce_on_key = string
#   })
# }
# variable "geo_restrictions" {
#   type = list(object({
#     action      = string
#     priority    = number
#     match       = object({ versioned_expr = string })
#     description = string
#   }))
# }
