module "sqs" {
  source = "app.terraform.io/KodeArkAdmin/tfe-modules/aws//modules/sqs"

  module_name = local.module_name
  environment = local.environment
}