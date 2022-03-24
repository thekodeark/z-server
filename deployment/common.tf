data "aws_availability_zones" "available" {
  state = "available"
}

module "networking" {
  source             = "app.terraform.io/KodeArkAdmin/tfe-modules/aws//modules/networking"
  version            = ">= 1.0.0"
  module_name        = local.module_name
  environment        = local.environment
  cidr               = "10.10.0.0/16"
  public_subnets     = ["10.10.100.0/24", "10.10.101.0/24"]
  private_subnets    = ["10.10.0.0/24", "10.10.1.0/24"]
  availability_zones = data.aws_availability_zones.available.names
}

module "security_group_lb" {
  source  = "app.terraform.io/KodeArkAdmin/tfe-modules/aws//modules/security-group"
  version = ">= 1.0.0"
  security_config = {
    vpc_id      = module.networking.vpc.id
    module_name = "${local.module_name}-lb"
    environment = local.environment
    ingress = [
      {
        from_port        = 80
        to_port          = 80
        protocol         = "tcp"
        cidr_blocks      = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
        security_groups  = null
      },
      {
        from_port        = 443
        to_port          = 443
        protocol         = "tcp"
        cidr_blocks      = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
        security_groups  = null
      }
    ]
    egress = [
      {
        from_port        = 0
        to_port          = 0
        protocol         = "-1"
        cidr_blocks      = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
        security_groups  = null
      }
    ]
  }
}

module "security_group_service" {
  source  = "app.terraform.io/KodeArkAdmin/tfe-modules/aws//modules/security-group"
  version = ">= 1.0.0"
  security_config = {
    vpc_id      = module.networking.vpc.id
    module_name = "${local.module_name}-service"
    environment = local.environment
    ingress = [
      {
        from_port        = 0
        to_port          = 0
        protocol         = "-1"
        cidr_blocks      = null
        ipv6_cidr_blocks = null
        security_groups  = [module.security_group_lb.id]
      }
    ]
    egress = [
      {
        from_port        = 0
        to_port          = 0
        protocol         = "-1"
        cidr_blocks      = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
        security_groups  = null
      }
    ]
  }
}

module "security_group_ec2" {
  source  = "app.terraform.io/KodeArkAdmin/tfe-modules/aws//modules/security-group"
  version = ">= 1.0.0"
  security_config = {
    vpc_id      = module.networking.vpc.id
    module_name = "${local.module_name}-ec2"
    environment = local.environment
    ingress = [
      {
        from_port        = 22
        to_port          = 22
        protocol         = "tcp"
        cidr_blocks      = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
        security_groups  = null
      }
    ]
    egress = [
      {
        from_port        = 0
        to_port          = 0
        protocol         = "-1"
        cidr_blocks      = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
        security_groups  = null
      }
    ]
  }
}

module "ecr" {
  source      = "app.terraform.io/KodeArkAdmin/tfe-modules/aws//modules/ecr"
  version     = ">= 1.0.0"
  module_name = local.module_name
  environment = local.environment
}

module "cert" {
  source      = "app.terraform.io/KodeArkAdmin/tfe-modules/aws//modules/cert"
  version     = ">= 1.0.0"
  fqdn        = local.fqdn
  hosted_zone = local.hosted_zone
}