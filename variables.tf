variable "prefix" {
  type = string
  default = "sysdig-fargate"
}

variable "sysdig_access_key" {
  type = string
  default = ""
  sensitive = true
}