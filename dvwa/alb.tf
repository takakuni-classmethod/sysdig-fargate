# https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http
data "http" "ifconfig" {
  url = "http://ipv4.icanhazip.com/"
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group
resource "aws_security_group" "alb" {
  name        = "${var.prefix}-alb"
  description = "${var.prefix}-alb"
  vpc_id      = module.vpc.vpc_id
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule
resource "aws_security_group_rule" "alb_http_ingress" {
  security_group_id = aws_security_group.alb.id
  type              = "ingress"
  description       = "Allow to HTTP from My IP"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["${chomp(data.http.ifconfig.response_body)}/32"]
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule
resource "aws_security_group_rule" "alb_any_egress" {
  security_group_id = aws_security_group.alb.id
  type              = "egress"
  description       = "Allow to Any"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb
resource "aws_lb" "alb" {
  name               = "${var.prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = module.vpc.public_subnets
  enable_deletion_protection = false

  tags = {
    Environment = "${var.prefix}-alb"
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group
resource "aws_lb_target_group" "ecs_service" {
  vpc_id   = module.vpc.vpc_id
  name     = "${var.prefix}-alb-tg"
  port     = 80
  protocol = "HTTP"
  target_type = "ip"
  health_check {
    path = "/login.php"
    matcher = 200
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_service.arn
  }
}