variable "prefix" {
  type    = string
  default = "sysdig-fargate"
}

variable "sysdig_access_key" {
  type      = string
  sensitive = true
}

variable "collector_host" {
  type    = string
}