# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role
resource "aws_iam_role" "task_exec" {
  name = "${var.prefix}-role-task-exection"
  assume_role_policy = file("${path.module}/policy_document/assume_ecs_task_exec.json")
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment
resource "aws_iam_role_policy_attachment" "managed_task_exec" {
  role = aws_iam_role.task_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group
resource "aws_cloudwatch_log_group" "task" {
  name = "${var.prefix}-logs"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "workload_agent" {
  name = "${var.prefix}-workload-agent-logs"
  retention_in_days = 7
}

# https://registry.terraform.io/providers/sysdiglabs/sysdig/latest/docs/data-sources/fargate_workload_agent
data "sysdig_fargate_workload_agent" "instrumented_envent_generator" {
  container_definitions = templatefile("${path.module}/task_definition/event_generator.json", {
    region = data.aws_region.current.name
    log_group_name = aws_cloudwatch_log_group.task.name
    log_stream_prefix = "${var.prefix}-event-generator"
  })

  sysdig_access_key     = var.sysdig_access_key
  workload_agent_image  = "quay.io/sysdig/workload-agent:latest"
  orchestrator_host     = module.fargate-orchestrator-agent.orchestrator_host
  orchestrator_port     = module.fargate-orchestrator-agent.orchestrator_port

  log_configuration {
    region = data.aws_region.current.name
    group = aws_cloudwatch_log_group.workload_agent.name
    stream_prefix = "${var.prefix}-workload-agent"
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition
resource "aws_ecs_task_definition" "envent_generator" {
  family = "${var.prefix}-td-event-generator"

  requires_compatibilities = [ "FARGATE" ]
  network_mode = "awsvpc"
  cpu = "1024"
  memory = "2048"
  container_definitions = data.sysdig_fargate_workload_agent.instrumented_envent_generator.output_container_definitions
  execution_role_arn = aws_iam_role.task_exec.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture = "X86_64"
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster
resource "aws_ecs_cluster" "cluster" {
  name = "${var.prefix}-cluster"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group
resource "aws_security_group" "ecs_service" {
  name        = "${var.prefix}-ecs-service"
  description = "${var.prefix}-ecs-service"
  vpc_id      = module.vpc.vpc_id
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule
resource "aws_security_group_rule" "ecs_any_egress" {
  security_group_id = aws_security_group.ecs_service.id
  type = "egress"
  description = "Allow to Any"
  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service
resource "aws_ecs_service" "service" {
  name = "${var.prefix}-service"
  cluster = aws_ecs_cluster.cluster.id
  launch_type = "FARGATE"
  task_definition = aws_ecs_task_definition.envent_generator.arn
  desired_count = 1

  network_configuration {
    security_groups = [ aws_security_group.ecs_service.id ]
    subnets = module.vpc.private_subnets
    assign_public_ip = false
  }
}