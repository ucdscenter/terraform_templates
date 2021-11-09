#Cloudwatch log group 
resource "aws_cloudwatch_log_group" "dsc_lma_log" {
  name              = var.cloudwatch_log_group_name
  retention_in_days = 30
}

#Cloudwatch log stream 
resource "aws_cloudwatch_log_stream" "dsc_lma_stream" {
  name           = var.cloudwatch_log_stream 
  log_group_name = aws_cloudwatch_log_group.dsc_lma_log.name
}

#ALB 
resource "aws_lb" "treatment_lb" {
  name               = "${var.name}-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [ aws_security_group.alb.id ]
  subnets            =  [ "subnet-097c6f21a3fc9e20a" , "subnet-07ac3ee92b8d45912"  ] 

  enable_deletion_protection = false
}

#ALB target group
resource "aws_alb_target_group" "treat_alb_tg_group" {
  name         = "${var.name}-tg"
  port         = 80

  protocol     = "HTTP"
  vpc_id       = var.vpc_id
  target_type  = "ip"

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "HTTP"
    timeout             = "3"
    path                = var.health_check_path   
    unhealthy_threshold = "2"
  }

  depends_on =  [ aws_lb.treatment_lb ]
}

resource "aws_alb_listener" "ecs_alb_http_listner" {
  load_balancer_arn = aws_lb.treatment_lb.id
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_alb_target_group.treat_alb_tg_group.arn
  }

  depends_on        = [ aws_alb_target_group.treat_alb_tg_group ]
}

#Redirect traffic to target group
#resource "aws_alb_listener" "ecs_alb_https_listner" {
#  load_balancer_arn = aws_lb.treatment_lb.id
#  port              = 443
#  protocol          = "HTTPS"
#  depends_on        = [ aws_alb_target_group.treat_alb_tg_group ]
#  ssl_policy        = "ELBSecurityPolicy-2016-08"
#  certificate_arn   = ""
#  
#  default_action {
#    target_group_arn = aws_alb_target_group.treat_alb_tg_group.id
#    type             =  "forward"
#
#  }
#}  

#Autoscaling group 
#resource "aws_appautoscaling_target" "ecs_target" {
#  max_capacity       = 4
#  min_capacity       = 2
#  resource_id        = "service/${aws_ecs_cluster.treatment_db_cluster.name}/${aws_ecs_service.uclib_treatment_db.name}"
#  scalable_dimension = "ecs:service:DesiredCount"
#  service_namespace  = "ecs"
#}

#resource "aws_appautoscaling_policy" "ecs_policy" {
#  name               = "scale-down"
#  policy_type        = "StepScaling"
#  resource_id        = "service/${aws_ecs_cluster.treatment_db_cluster.name}/${aws_ecs_service.uclib_treatment_db.name}"
#  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
#  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace
#
#  step_scaling_policy_configuration {
#    adjustment_type         = "ChangeInCapacity"
#    cooldown                = 60
#    metric_aggregation_type = "Maximum"
#
#    step_adjustment {
#      metric_interval_upper_bound = 0
#      scaling_adjustment          = -1
#    }
#  }
#}

#ECS Cluster 
resource "aws_ecs_cluster" "treatment_db_cluster" {
  name = "${var.name}-cluster"
}

#ECS Task Definition 
resource "aws_ecs_task_definition" "uclib_treatment_definition" {
  count                    = var.create ? 1:0 
  family                   = "${var.name}-task"
  task_role_arn            = aws_iam_role.ecs_task_execution_role.arn
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048
  requires_compatibilities = ["FARGATE"]
  container_definitions = <<EOF
[
  {
    "image": "${var.app_image}",
    "name": "${local.environment_prefix}-app",
    "essential": true,
    "cpu": 256,
    "memoryReservation": 512,
    "portMappings": [
      {
        "containerPort": 8000,
        "hostPort": 8000,
        "protocol": "tcp"
      }
    ],
    "mountPoints": [],
    "entryPoint": [],
    "command": [],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-region": "${var.aws_region}",
        "awslogs-group": "${var.cloudwatch_log_group_name}",
        "awslogs-stream-prefix": "${var.cloudwatch_log_stream}"
      }
    },
    "environment": [
      {
        "name": "MLA_DATABASE_POOL",
        "value": "5"
      },
      {
        "name": "MLA_DATABASE_TIMEOUT",
        "value": "5000"
      },
      {
        "name": "RAILS_LOG_TO_STDOUT",
        "value": "true"
      }
    ],
    "placement_constraints": [],
    "secrets": [
      {
        "name": "MLA_DATABASE_HOST",
        "valueFrom": "${var.db_secret_arn}:host::"
      },
      {
      "name": "MLA_DATABASE_USERNAME",
      "valueFrom": "${var.db_secret_arn}:username::"
      },
      {
      "name": "ENGINE",
      "valueFrom": "${var.admin_secret_arn}:engine::"
      },
       {
      "name": "PORT",
      "valueFrom": "${var.admin_secret_arn}:port::"
      },
       {
      "name": "DB_INSTANCE_IDENTIFIER",
      "valueFrom": "${var.admin_secret_arn}:dbInstanceIdentifier::"
      },      
      {
      "name": "MLA_ADMIN_PASSWORD",
      "valueFrom": "${var.admin_secret_arn}:password::"
      }
    ],
    "volume": []
  }
]
EOF
}

#ECS Service 
resource "aws_ecs_service" "uclib_treatment_db" {
  name                               = "${var.name}-service" 
  cluster                            = aws_ecs_cluster.treatment_db_cluster.id
  task_definition                    = aws_ecs_task_definition.uclib_treatment_definition[0].arn
  desired_count                      = 1
  launch_type                        = "FARGATE" 
  scheduling_strategy                = "REPLICA"
  platform_version                   = "LATEST"
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
  #health_check_grace_period_seconds  = 60   
  #iam_role                           = aws_iam_role.treatment_db_svc.arn  
  depends_on                         = [ aws_iam_role.treatment_db_svc ] 

  network_configuration {
    security_groups  = [ aws_security_group.alb.id, aws_security_group.service.id ]
    subnets          = [ "subnet-097c6f21a3fc9e20a" , "subnet-07ac3ee92b8d45912"  ] 
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.treat_alb_tg_group.arn
    container_name   = "${local.environment_prefix}-app"
    container_port   = var.container_port
  }
}

output "alb" {
  value = aws_security_group.alb.id
}

output "service" {
  value = aws_security_group.service.id 
}
