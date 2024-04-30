terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.47.0"
    }
    sysdig = {
      source  = "sysdiglabs/sysdig"
      version = "1.24.1"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.4.2"
    }
  }
}

provider "aws" {
  region = "ap-northeast-1"
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region
data "aws_region" "current" {}
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity
data "aws_caller_identity" "self" {}

provider "sysdig" {
  sysdig_secure_url       = "https://app.au1.sysdig.com"
  sysdig_secure_api_token = var.sysdig_access_key
}
