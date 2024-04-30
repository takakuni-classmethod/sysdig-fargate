############################################
# Service Discovery
############################################
resource "aws_service_discovery_private_dns_namespace" "this" {
  name = "local"
  vpc  = module.vpc.vpc_id
}

############################################
# Fargate Orchestrator Agent
############################################
module "fargate_orchestrator_agent" {
  source = "./modules/fargate_orchestrator_agent"

  vpc_id         = module.vpc.vpc_id
  vpc_cidr       = module.vpc.vpc_cidr_block
  namespace_id   = aws_service_discovery_private_dns_namespace.this.id
  namespace_name = aws_service_discovery_private_dns_namespace.this.name
  subnets        = module.vpc.private_subnets

  access_key     = var.sysdig_access_key # Sysdig access key
  collector_host = var.collector_host    # Sysdig collector host (default:"collector.sysdigcloud.com")
  collector_port = "6443"                # Sysdig collector port (default:"6443")

  name        = "${var.prefix}-orchestrator"               # Identifier for module resources
  agent_image = "quay.io/sysdig/orchestrator-agent:latest" # Orchestrator agent image

  assign_public_ip = false # Provisions a public IP for the service. Required when using an Internet Gateway for egress.
}
