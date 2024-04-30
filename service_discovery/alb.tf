############################################
# Retrieve the public IP address of the machine
############################################
data "http" "ifconfig" {
  url = "http://ipv4.icanhazip.com/"
}

############################################
# Create a security group for the ALB
############################################
resource "aws_security_group" "alb" {
  name        = "${var.prefix}-alb"
  description = "${var.prefix}-alb"
  vpc_id      = module.vpc.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "${chomp(data.http.ifconfig.response_body)}/32"
  security_group_id = aws_security_group.alb.id
}

resource "aws_vpc_security_group_egress_rule" "alb" {
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  security_group_id = aws_security_group.alb.id
}

############################################
# Create an Application Load Balancer
############################################
resource "aws_lb" "alb" {
  name                       = "${var.prefix}-alb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb.id]
  subnets                    = module.vpc.public_subnets
  enable_deletion_protection = false

  tags = {
    Environment = "${var.prefix}-alb"
  }
}

resource "aws_lb_target_group" "ecs_service" {
  vpc_id      = module.vpc.vpc_id
  name        = "${var.prefix}-alb-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  health_check {
    path    = "/login.php"
    matcher = 200
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_service.arn
  }
}
