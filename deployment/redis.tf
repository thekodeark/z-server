module "redis" {
  source = "app.terraform.io/KodeArkAdmin/tfe-modules/aws//modules/elastic-cache"

  module_name = local.module_name
  environment = local.environment
  subnet_ids  = module.networking.private_subnets
  security_group_ids = [
    module.security_group_ec2.id,
    module.security_group_service.id
  ]
}