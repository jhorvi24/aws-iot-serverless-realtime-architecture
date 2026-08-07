# ============================================================
# IoT Serverless Architecture - Main Configuration
# ============================================================

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
  prefix     = "${var.project_name}-${var.environment}"
}

# --- DynamoDB Module ---
module "dynamodb" {
  source       = "./modules/dynamodb"
  project_name = var.project_name
  environment  = var.environment
}

# --- Cognito Module ---
module "cognito" {
  source       = "./modules/cognito"
  project_name = var.project_name
  environment  = var.environment
}

# --- Lambda Module ---
module "lambda" {
  source       = "./modules/lambda"
  project_name = var.project_name
  environment  = var.environment
  region       = local.region
  account_id   = local.account_id

  dynamodb_table_name = module.dynamodb.table_name
  dynamodb_table_arn  = module.dynamodb.table_arn

  websocket_connections_table_name = module.dynamodb.connections_table_name
  websocket_connections_table_arn  = module.dynamodb.connections_table_arn
}

# --- API Gateway Module ---
module "api_gateway" {
  source       = "./modules/api_gateway"
  project_name = var.project_name
  environment  = var.environment
  region       = local.region
  account_id   = local.account_id

  cognito_user_pool_arn = module.cognito.user_pool_arn

  api_handler_invoke_arn    = module.lambda.api_handler_invoke_arn
  api_handler_function_name = module.lambda.api_handler_function_name

  websocket_connect_invoke_arn       = module.lambda.websocket_connect_invoke_arn
  websocket_connect_function_name    = module.lambda.websocket_connect_function_name
  websocket_disconnect_invoke_arn    = module.lambda.websocket_disconnect_invoke_arn
  websocket_disconnect_function_name = module.lambda.websocket_disconnect_function_name
  websocket_default_invoke_arn       = module.lambda.websocket_default_invoke_arn
  websocket_default_function_name    = module.lambda.websocket_default_function_name
}

# --- IoT Core Module ---
module "iot_core" {
  source       = "./modules/iot_core"
  project_name = var.project_name
  environment  = var.environment
  region       = local.region
  account_id   = local.account_id

  iot_thing_name = var.iot_thing_name
  mqtt_topic     = var.mqtt_topic

  iot_processor_arn = module.lambda.iot_processor_arn
}

# --- Frontend Hosting Module ---
module "frontend_hosting" {
  source       = "./modules/frontend_hosting"
  project_name = var.project_name
  environment  = var.environment
}

# --- Update Lambda with WebSocket API endpoint ---
resource "aws_lambda_function_event_invoke_config" "iot_processor_config" {
  function_name = module.lambda.iot_processor_function_name

  depends_on = [module.api_gateway]
}
