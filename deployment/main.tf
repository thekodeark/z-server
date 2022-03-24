module "ecs_cluster" {
  source      = "app.terraform.io/KodeArkAdmin/tfe-modules/aws//modules/ecs-cluster"
  version     = ">= 1.0.0"
  module_name = local.module_name
  environment = local.environment
}

module "ec2" {
  source           = "app.terraform.io/KodeArkAdmin/tfe-modules/aws//modules/ec2-launch-config"
  version          = ">= 1.0.0"
  module_name      = local.module_name
  environment      = local.environment
  ecs_cluster_name = module.ecs_cluster.cluster.name
  private_subnets  = module.networking.private_subnets
  ecs_scaling_config = {
    min_capacity     = 1
    max_capacity     = 10
    desired_capacity = 5
  }

  ec2_config = {
    security_group_ids = [module.security_group_ec2.id, module.security_group_service.id]
    instance_type      = local.instance_type
    public_key         = local.ssh_pub_key
  }
}

module "cloudwatch" {
  source      = "app.terraform.io/KodeArkAdmin/tfe-modules/aws//modules/cloudwatch"
  version     = ">= 1.0.0"
  module_name = local.module_name
  environment = local.environment
}

module "alb" {
  source      = "app.terraform.io/KodeArkAdmin/tfe-modules/aws//modules/alb"
  version     = ">= 1.0.0"
  module_name = local.module_name
  environment = local.environment

  public_subnets        = module.networking.public_subnets
  vpc_id                = module.networking.vpc.id
  zone_id               = module.cert.zone_id
  public_security_group = module.security_group_lb.id
  certificate_arn       = module.cert.arn
  fqdn                  = local.fqdn
  lb_health_check_config = {
    healthy_threshold   = null
    interval            = "15"
    protocol            = "HTTP"
    port                = 3000
    matcher             = null
    timeout             = "10"
    path                = "/"
    unhealthy_threshold = null
  }
}

module "api-ecs-task-definition" {
  source      = "app.terraform.io/KodeArkAdmin/tfe-modules/aws//modules/ecs-task-definition"
  version     = ">= 1.0.0"
  module_name = local.module_name
  environment = local.environment
  container_definition = [
    {
      name      = "${local.module_name}-service",
      image     = "erashu212/web:latest",
      cpu       = 10,
      memory    = 256,
      links     = [],
      essential = true,
      portMappings = [
        {
          hostPort      = 0,
          containerPort = 3000,
          protocol      = "tcp"
        }
      ],
      command     = null, // ["gunicorn", "-w", "3", "-b", ":8000", "project.wsgi:application"],
      environment = [],
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group  = module.cloudwatch.log_group.name
          awslogs-region = data.aws_region.active.name
        }
      }
    },
    {
      name      = "nginx",
      image     = "erashu212/web:latest",
      essential = true,
      cpu       = 10,
      memory    = 128,
      command   = null,
      links     = ["${local.module_name}-service"],
      environment = [],
      portMappings = [
        {
          hostPort      = 0,
          containerPort = 80,
          protocol      = "tcp"
        }
      ],
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          "awslogs-group"  = module.cloudwatch.log_group.name
          "awslogs-region" = data.aws_region.active.name
        }
      }
    }
  ]
}

module "api-ecs-service" {
  source      = "app.terraform.io/KodeArkAdmin/tfe-modules/aws//modules/ecs-service"
  version     = ">= 1.0.0"
  module_name = local.module_name
  environment = local.environment
  ecs_task_definition = {
    family = module.api-ecs-task-definition.family
    arn    = module.api-ecs-task-definition.arn
  }

  ecs_cluster_id = module.ecs_cluster.cluster.id
  desired_count  = 5

  lb_config = {
    target_group_arn = module.alb.target_group_arn
    container_name   = "nginx"
    container_port   = 80
  }
}