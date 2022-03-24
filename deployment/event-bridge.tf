#locals {
#  order_input_transformer = {
#    input_paths = {
#      order_id = "$.detail.order_id"
#    }
#    input_template = <<EOF
#    {
#      "id": <order_id>
#    }
#    EOF
#  }
#}
#
#module "event-bridge" {
#  source = "app.terraform.io/KodeArkAdmin/tfe-modules/aws//modules/event-bridge"
#
#  module_name = local.module_name
#  environment = local.environment
#  target_orders = [
#    {
#      name              = "send-orders-to-sqs"
#      arn               = module.sqs.sqs_queue_arn
#      input_transformer = local.order_input_transformer
#    }
#  ]
#  event_pattern = { "source" : ["myapp.orders"] }
#}