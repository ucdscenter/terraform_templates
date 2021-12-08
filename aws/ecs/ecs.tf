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
resource "aws_lb" "mla_lb" {
  name               = "${var.name}-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.dsc_public_subnets[0].id, aws_subnet.dsc_public_subnets[1].id]

  enable_deletion_protection = false
}

#ALB target group
resource "aws_alb_target_group" "mla_alb_tg_group" {
  name = "${var.name}-tg"
  port = 80

  protocol    = "HTTP"
  vpc_id      = aws_vpc.dsc_vpc.id
  target_type = "ip"

  health_check {
    healthy_threshold   = "10"
    interval            = "30"
    protocol            = "HTTP"
    timeout             = "20"
    path                = var.health_check_path
    unhealthy_threshold = "2"
  }

  depends_on = [aws_lb.mla_lb]
}

resource "aws_alb_listener" "ecs_alb_http_listner" {
  load_balancer_arn = aws_lb.mla_lb.id
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.mla_alb_tg_group.arn
  }

  depends_on = [aws_alb_target_group.mla_alb_tg_group]
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

#ECS Cluster 
resource "aws_ecs_cluster" "mla_cluster" {
  name = "${var.name}-cluster"
}

#ECS Task Definition 
resource "aws_ecs_task_definition" "uwsgi" {
  count                    = var.create ? 1 : 0
  family                   = "${var.name}-uwsgi"
  task_role_arn            = aws_iam_role.ecs_task_execution_role.arn
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048
  requires_compatibilities = ["FARGATE"]
  container_definitions    = <<EOF
[
  {
    "image": "049879149392.dkr.ecr.us-east-2.amazonaws.com/uwsgi",
    "name": "uwsgi",
    "essential": true,
    "cpu": 256,
    "memoryReservation": 512,
    "portMappings": [
      {
        "containerPort": 8001,
        "hostPort": 8001,
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
        "awslogs-stream-prefix": "${var.cloudwatch_log_stream}/uwsgi"
      }
    },
    "environment": [],
    "placement_constraints": [],
    "secrets": [
      {
        "name": "MLA_DATABASE_HOST",
        "valueFrom": "${var.db_secret_arn}:host::"
      },
      {
        "name": "MLA_DATABASE_NAME",
        "valueFrom": "${var.db_secret_arn}:rds_dbname::"
      },
      {
      "name": "MLA_DATABASE_USERNAME",
      "valueFrom": "${var.db_secret_arn}:username::"
      },
      {
      "name": "ENGINE",
      "valueFrom": "${var.db_secret_arn}:engine::"
      },
       {
      "name": "PORT",
      "valueFrom": "${var.db_secret_arn}:port::"
      },
       {
      "name": "DB_INSTANCE_IDENTIFIER",
      "valueFrom": "${var.db_secret_arn}:dbInstanceIdentifier::"
      },      
      {
      "name": "MLA_ADMIN_PASSWORD",
      "valueFrom": "${var.db_secret_arn}:password::"
      }
    ],
    "volume": []
  }
]
EOF
}

resource "aws_ecs_task_definition" "nginx" {
  count                    = var.create ? 1 : 0
  family                   = "${var.name}-nginx"
  task_role_arn            = aws_iam_role.ecs_task_execution_role.arn
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048
  requires_compatibilities = ["FARGATE"]
  container_definitions    = <<EOF
[
  {
    "image": "049879149392.dkr.ecr.us-east-2.amazonaws.com/nginx",
    "name": "nginx",
    "essential": true,
    "cpu": 256,
    "memoryReservation": 512,
    "portMappings": [
      {
        "containerPort": 80,
        "hostPort": 80,
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
        "awslogs-stream-prefix": "${var.cloudwatch_log_stream}/nginx"
      }
    },
    "environment": [],
    "placement_constraints": [],
    "secrets": [],
    "volume": []
  }
]
EOF
}

resource "aws_ecs_task_definition" "redis" {
  count                    = var.create ? 1 : 0
  family                   = "${var.name}-redis"
  task_role_arn            = aws_iam_role.ecs_task_execution_role.arn
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048
  requires_compatibilities = ["FARGATE"]
  container_definitions    = <<EOF
[
  {
    "image": "049879149392.dkr.ecr.us-east-2.amazonaws.com/redis",
    "name": "redis",
    "essential": true,
    "cpu": 256,
    "memoryReservation": 512,
    "portMappings": [
      {
        "containerPort": 6379,
        "hostPort": 6379,
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
        "awslogs-stream-prefix": "${var.cloudwatch_log_stream}/redis"
      }
    },
    "environment": [],
    "placement_constraints": [],
    "secrets": [],
    "volume": []
  }
]
EOF
}

resource "aws_ecs_task_definition" "worker" {
  count                    = var.create ? 1 : 0
  family                   = "${var.name}-worker"
  task_role_arn            = aws_iam_role.ecs_task_execution_role.arn
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048
  requires_compatibilities = ["FARGATE"]
  container_definitions    = <<EOF
[
  {
    "image": "049879149392.dkr.ecr.us-east-2.amazonaws.com/worker",
    "name": "worker",
    "essential": true,
    "cpu": 256,
    "memoryReservation": 512,
    "portMappings": [
      {
        "containerPort": 8001,
        "hostPort": 8001,
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
        "awslogs-stream-prefix": "${var.cloudwatch_log_stream}/worker"
      }
    },
    "environment": [],
    "placement_constraints": [],
    "secrets": [
      {
        "name": "MLA_DATABASE_HOST",
        "valueFrom": "${var.dev_db_secret_arn}:host::"
      },
      {
      "name": "MLA_DATABASE_USERNAME",
      "valueFrom": "${var.dev_db_secret_arn}:username::"
      },
      {
        "name": "MLA_DATABASE_NAME",
        "valueFrom": "${var.dev_db_secret_arn}:rds_dbname::"
      },
      {
      "name": "ENGINE",
      "valueFrom": "${var.dev_db_secret_arn}:engine::"
      },
      {
      "name": "PORT",
      "valueFrom": "${var.dev_db_secret_arn}:port::"
      },
      {
      "name": "DB_INSTANCE_IDENTIFIER",
      "valueFrom": "${var.dev_db_secret_arn}:dbInstanceIdentifier::"
      },      
      {
      "name": "MLA_ADMIN_PASSWORD",
      "valueFrom": "${var.dev_db_secret_arn}:password::"
      }
    ],
    "volume": []
  }
]
EOF
}

#ECS Service 
resource "aws_ecs_service" "uwsgi" {
  name                               = "${var.name}-uwsgi"
  cluster                            = aws_ecs_cluster.mla_cluster.id
  task_definition                    = aws_ecs_task_definition.uwsgi[0].arn
  desired_count                      = 1
  launch_type                        = "FARGATE"
  scheduling_strategy                = "REPLICA"
  platform_version                   = "LATEST"
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
  #health_check_grace_period_seconds = 60   
  #iam_role                          = aws_iam_role.mla_svc.arn  
  depends_on = [aws_iam_role.mla_svc]

  network_configuration {
    security_groups  = [aws_security_group.alb.id, aws_security_group.service.id]
    subnets          = [aws_subnet.dsc_public_subnets[0].id, aws_subnet.dsc_public_subnets[1].id]
    assign_public_ip = true
  }

  #load_balancer {
  #  target_group_arn = aws_alb_target_group.mla_alb_tg_group.arn
  #  container_name   = "${local.environment_prefix}-uwsgi"
  #  container_port   = "8001"            #var.container_port
  #}
}

resource "aws_ecs_service" "nginx" {
  name                               = "${var.name}-nginx"
  cluster                            = aws_ecs_cluster.mla_cluster.id
  task_definition                    = aws_ecs_task_definition.nginx[0].arn
  desired_count                      = 1
  launch_type                        = "FARGATE"
  scheduling_strategy                = "REPLICA"
  platform_version                   = "LATEST"
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
  #health_check_grace_period_seconds  = 60   
  #iam_role                           = aws_iam_role.mla_svc.arn  
  depends_on = [aws_iam_role.mla_svc]

  network_configuration {
    security_groups  = [aws_security_group.alb.id, aws_security_group.service.id]
    subnets          = [aws_subnet.dsc_public_subnets[0].id, aws_subnet.dsc_public_subnets[1].id]
    assign_public_ip = true
  }

  #load_balancer {
  #  target_group_arn = aws_alb_target_group.mla_alb_tg_group.arn
  #  container_name   = "${local.environment_prefix}-nginx"
  #  container_port   = 
  #}
}

resource "aws_ecs_service" "redis" {
  name                               = "${var.name}-redis"
  cluster                            = aws_ecs_cluster.mla_cluster.id
  task_definition                    = aws_ecs_task_definition.redis[0].arn
  desired_count                      = 1
  launch_type                        = "FARGATE"
  scheduling_strategy                = "REPLICA"
  platform_version                   = "LATEST"
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
  #health_check_grace_period_seconds  = 60   
  #iam_role                           = aws_iam_role.mla_svc.arn  
  depends_on = [aws_iam_role.mla_svc]

  network_configuration {
    security_groups  = [aws_security_group.alb.id, aws_security_group.service.id]
    subnets          = [aws_subnet.dsc_public_subnets[0].id, aws_subnet.dsc_public_subnets[1].id]
    assign_public_ip = true
  }

  #load_balancer {
  #  target_group_arn = aws_alb_target_group.mla_alb_tg_group.arn
  #  container_name   = "${local.environment_prefix}-redis"
  #  container_port   =
  #}
}

resource "aws_ecs_service" "worker" {
  name                               = "${var.name}-worker"
  cluster                            = aws_ecs_cluster.mla_cluster.id
  task_definition                    = aws_ecs_task_definition.worker[0].arn
  desired_count                      = 1
  launch_type                        = "FARGATE"
  scheduling_strategy                = "REPLICA"
  platform_version                   = "LATEST"
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
  #health_check_grace_period_seconds  = 60   
  #iam_role                           = aws_iam_role.mla_svc.arn  
  depends_on = [aws_iam_role.mla_svc]

  network_configuration {
    security_groups  = [aws_security_group.alb.id, aws_security_group.service.id]
    subnets          = [aws_subnet.dsc_public_subnets[0].id, aws_subnet.dsc_public_subnets[1].id]
    assign_public_ip = true
  }

  #load_balancer {
  #  target_group_arn = aws_alb_target_group.mla_alb_tg_group.arn
  #  container_name   = "${local.environment_prefix}-worker"
  #  container_port   = 
  #}
}
