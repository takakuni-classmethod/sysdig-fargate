variable "prefix" {
  type    = string
  default = "sysdig-fargate"
}

variable "sysdig_access_key" {
  type      = string
  default   = ""
  sensitive = true
}

variable "collector_host" {
  type    = string
  default = "ingest.au1.sysdig.com"
}