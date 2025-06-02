variable "display_name" {
  type    = string
  default = ""
}

variable "combiner" {
  type    = string
  default = ""
}

variable "enabled" {
  type    = string
  default = false
}

variable "notification_channels" {
  type    = list(string)
  default = []
}

variable "auto_close" {
  type    = string
  default = ""
}

variable "conditions" {
  type = list(object({
    display_name    = string
    filter          = string
    duration        = string
    comparison      = string
    threshold_value = number
    aggregations = object({
      alignment_period   = string
      per_series_aligner = string
    })
  }))
  default = []
}
