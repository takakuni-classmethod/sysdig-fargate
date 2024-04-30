############################################
# IAM Role for ECS Task Execution
############################################
resource "aws_iam_role" "task_exec" {
  name               = "${var.prefix}-role-task-exection"
  assume_role_policy = file("${path.module}/policy_document/assume_ecs_task_exec.json")
}

resource "aws_iam_role_policy_attachment" "managed_task_exec" {
  role       = aws_iam_role.task_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

############################################
# IAM Role for ECS Task
############################################
resource "aws_iam_role" "task" {
  name               = "${var.prefix}-role-task"
  assume_role_policy = file("${path.module}/policy_document/assume_ecs_task_exec.json")
}

resource "aws_iam_policy" "task" {
  policy = file("${path.module}/policy_document/iam_task.json")
}

resource "aws_iam_role_policy_attachment" "task" {
  role       = aws_iam_role.task.name
  policy_arn = aws_iam_policy.task.arn
}

############################################
# CloudWatch Log Groups
############################################
resource "aws_cloudwatch_log_group" "task" {
  name              = "${var.prefix}-logs"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "workload_agent" {
  name              = "${var.prefix}-workload-agent-logs"
  retention_in_days = 7
}

############################################
# Workload Agent for DVWA
############################################
data "sysdig_fargate_workload_agent" "instrumented_dvwa" {
  container_definitions = templatefile("${path.module}/task_definition/dvwa.json", {
    region            = data.aws_region.current.name
    log_group_name    = aws_cloudwatch_log_group.task.name
    log_stream_prefix = "${var.prefix}-event-generator"
  })

  sysdig_access_key    = var.sysdig_access_key
  workload_agent_image = "quay.io/sysdig/workload-agent:latest"
  orchestrator_host    = module.fargate_orchestrator_agent.orchestrator_host
  orchestrator_port    = module.fargate_orchestrator_agent.orchestrator_port

  log_configuration {
    region        = data.aws_region.current.name
    group         = aws_cloudwatch_log_group.workload_agent.name
    stream_prefix = "${var.prefix}-workload-agent"
  }
}

############################################
# Task Definition for DVWA
############################################
resource "aws_ecs_task_definition" "dvwa" {
  family = "${var.prefix}-td-dvwa"

  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "1024"
  memory                   = "2048"
  container_definitions    = data.sysdig_fargate_workload_agent.instrumented_dvwa.output_container_definitions
  execution_role_arn       = aws_iam_role.task_exec.arn
  task_role_arn            = aws_iam_role.task.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
}

############################################
# ECS Cluster
############################################
resource "aws_ecs_cluster" "cluster" {
  name = "${var.prefix}-cluster"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

############################################
# Security Group for ECS Service
############################################
resource "aws_security_group" "ecs_service" {
  name        = "${var.prefix}-ecs-service"
  description = "${var.prefix}-ecs-service"
  vpc_id      = module.vpc.vpc_id
}

resource "aws_vpc_security_group_egress_rule" "ecs" {
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  security_group_id = aws_security_group.ecs_service.id
}

resource "aws_vpc_security_group_ingress_rule" "ecs" {
  security_group_id            = aws_security_group.ecs_service.id
  description                  = "Allow to HTTP from ALB"
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.alb.id
}

############################################
# ECS Service
############################################
resource "aws_ecs_service" "service" {
  name                   = "${var.prefix}-service"
  cluster                = aws_ecs_cluster.cluster.id
  launch_type            = "FARGATE"
  task_definition        = aws_ecs_task_definition.dvwa.arn
  desired_count          = 1
  enable_execute_command = true

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_service.arn
    container_name   = "dvwa"
    container_port   = 80
  }

  network_configuration {
    security_groups  = [aws_security_group.ecs_service.id]
    subnets          = module.vpc.private_subnets
    assign_public_ip = false
  }
}
