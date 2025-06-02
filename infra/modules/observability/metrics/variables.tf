variable "name" {
  type    = string
  default = ""  
}

variable "filter" {
  type    = string
  default = ""  
}

variable "metric_kind" {
  type    = string
  default = ""  
}

variable "value_type" {
  type    = string
  default = ""  
}

variable "display_name" {
  type    = string
  default = ""  
}

variable "label_extractors" {
  type    = map(string)
  default = {}  
}