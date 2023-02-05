# https://registry.terraform.io/modules/sysdiglabs/fargate-orchestrator-agent/aws/latest
module "fargate-orchestrator-agent" {
  source  = "sysdiglabs/fargate-orchestrator-agent/aws"
  version = "0.2.0"

  vpc_id  = module.vpc.vpc_id
  subnets = module.vpc.private_subnets

  access_key     = var.sysdig_access_key # Sysdig access key
  collector_host = var.collector_host    # Sysdig collector host (default:"collector.sysdigcloud.com")
  collector_port = "6443"                # Sysdig collector port (default:"6443")

  name        = "${var.prefix}-orchestrator"               # Identifier for module resources
  agent_image = "quay.io/sysdig/orchestrator-agent:latest" # Orchestrator agent image

  assign_public_ip = false # Provisions a public IP for the service. Required when using an Internet Gateway for egress.
}