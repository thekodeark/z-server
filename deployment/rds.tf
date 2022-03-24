module "rds" {
  source = "app.terraform.io/KodeArkAdmin/tfe-modules/aws//modules/rds"

  module_name = local.module_name
  environment = local.environment
  subnet_ids  = module.networking.private_subnets
  security_group_ids = [
    module.security_group_ec2.id,
    module.security_group_service.id
  ]
  db_config = {
    db_name  = "testdb"
    username = "test"
    port     = 5432
    password = "ashu@123#"
  }
}