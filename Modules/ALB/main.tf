/*==============================================================
      AWS Application Load Balancer + Target groups
===============================================================*/
resource "aws_alb_listener" "http_listener" {  
  count             = var.create_alb ? 1 : 0  
  load_balancer_arn = aws_alb.alb[0].id  
  port              = "80"  
  protocol          = "HTTP"  
  
  default_action {  
    type             = "forward"  
    target_group_arn = var.default_target_group  # Set your default target group here  
  }  
}

# ------- ALB Listenet for HTTPS -------
resource "aws_alb_listener" "https_listener" {
  count             = var.create_alb == true ? (var.enable_https == true ? 1 : 0) : 0
  load_balancer_arn = aws_alb.alb[0].id
  port              = "443"
  protocol          = "HTTPS"

  default_action {
    target_group_arn = var.target_group
    type             = "forward"
  }

  lifecycle {
    // to avoid changes generated by CodeDeploy changes
    ignore_changes = [default_action]
  }
}

# ------- ALB Listener for HTTP -------
resource "aws_alb_listener_rule" "http_listener_rule" {  
  count             = var.create_alb ? length(var.target_groups) : 0  
  listener_arn      = aws_alb_listener.http_listener[0].arn  
  priority          = count.index + 100  # Ensure unique priority for each rule  
  
  action {  
    type             = "forward"  
    target_group_arn = var.target_groups[count.index].arn  # Use target group ARNs from input variable  
  }  
  
  condition {  
    path_pattern {  
      values = [var.target_groups[count.index].path_pattern]  # Use path patterns from input variable  
    }  
  }  
} 

# ------- Target Groups for ALB -------
resource "aws_alb_target_group" "target_group" {
  count                = var.create_target_group == true ? 1 : 0
  name                 = var.name
  port                 = var.port
  protocol             = var.protocol
  vpc_id               = var.vpc
  target_type          = var.tg_type
  deregistration_delay = 5

  health_check {
    enabled             = true
    interval            = 15
    path                = var.health_check_path
    port                = var.health_check_port
    protocol            = var.protocol
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 3
    matcher             = "200"
  }

  lifecycle {
    create_before_destroy = true
  }
}
