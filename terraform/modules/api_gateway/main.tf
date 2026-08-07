# ============================================================
# API Gateway - REST API + WebSocket API
# ============================================================

locals {
  prefix = "${var.project_name}-${var.environment}"
}

# ============================================================
# REST API (for historical data queries)
# ============================================================

resource "aws_api_gateway_rest_api" "sensor_api" {
  name        = "${local.prefix}-sensor-api"
  description = "REST API for IoT sensor data queries"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# --- Cognito Authorizer ---
resource "aws_api_gateway_authorizer" "cognito" {
  name            = "${local.prefix}-cognito-authorizer"
  rest_api_id     = aws_api_gateway_rest_api.sensor_api.id
  type            = "COGNITO_USER_POOLS"
  provider_arns   = [var.cognito_user_pool_arn]
  identity_source = "method.request.header.Authorization"
}

# --- /sensors resource ---
resource "aws_api_gateway_resource" "sensors" {
  rest_api_id = aws_api_gateway_rest_api.sensor_api.id
  parent_id   = aws_api_gateway_rest_api.sensor_api.root_resource_id
  path_part   = "sensors"
}

# --- /sensors/{device_id} resource ---
resource "aws_api_gateway_resource" "sensor_device" {
  rest_api_id = aws_api_gateway_rest_api.sensor_api.id
  parent_id   = aws_api_gateway_resource.sensors.id
  path_part   = "{device_id}"
}

# --- GET /sensors/{device_id} ---
resource "aws_api_gateway_method" "get_sensor_data" {
  rest_api_id   = aws_api_gateway_rest_api.sensor_api.id
  resource_id   = aws_api_gateway_resource.sensor_device.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id

  request_parameters = {
    "method.request.path.device_id"       = true
    "method.request.querystring.from"     = false
    "method.request.querystring.to"       = false
    "method.request.querystring.limit"    = false
  }
}

resource "aws_api_gateway_integration" "get_sensor_data" {
  rest_api_id             = aws_api_gateway_rest_api.sensor_api.id
  resource_id             = aws_api_gateway_resource.sensor_device.id
  http_method             = aws_api_gateway_method.get_sensor_data.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.api_handler_invoke_arn
}

# --- GET /sensors (list all devices latest data) ---
resource "aws_api_gateway_method" "list_sensors" {
  rest_api_id   = aws_api_gateway_rest_api.sensor_api.id
  resource_id   = aws_api_gateway_resource.sensors.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_integration" "list_sensors" {
  rest_api_id             = aws_api_gateway_rest_api.sensor_api.id
  resource_id             = aws_api_gateway_resource.sensors.id
  http_method             = aws_api_gateway_method.list_sensors.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.api_handler_invoke_arn
}

# --- CORS: OPTIONS /sensors ---
resource "aws_api_gateway_method" "sensors_options" {
  rest_api_id   = aws_api_gateway_rest_api.sensor_api.id
  resource_id   = aws_api_gateway_resource.sensors.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "sensors_options" {
  rest_api_id = aws_api_gateway_rest_api.sensor_api.id
  resource_id = aws_api_gateway_resource.sensors.id
  http_method = aws_api_gateway_method.sensors_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "sensors_options_200" {
  rest_api_id = aws_api_gateway_rest_api.sensor_api.id
  resource_id = aws_api_gateway_resource.sensors.id
  http_method = aws_api_gateway_method.sensors_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "sensors_options_200" {
  rest_api_id = aws_api_gateway_rest_api.sensor_api.id
  resource_id = aws_api_gateway_resource.sensors.id
  http_method = aws_api_gateway_method.sensors_options.http_method
  status_code = aws_api_gateway_method_response.sensors_options_200.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization,X-Amz-Date,X-Api-Key'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# --- CORS: OPTIONS /sensors/{device_id} ---
resource "aws_api_gateway_method" "sensor_device_options" {
  rest_api_id   = aws_api_gateway_rest_api.sensor_api.id
  resource_id   = aws_api_gateway_resource.sensor_device.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "sensor_device_options" {
  rest_api_id = aws_api_gateway_rest_api.sensor_api.id
  resource_id = aws_api_gateway_resource.sensor_device.id
  http_method = aws_api_gateway_method.sensor_device_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "sensor_device_options_200" {
  rest_api_id = aws_api_gateway_rest_api.sensor_api.id
  resource_id = aws_api_gateway_resource.sensor_device.id
  http_method = aws_api_gateway_method.sensor_device_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "sensor_device_options_200" {
  rest_api_id = aws_api_gateway_rest_api.sensor_api.id
  resource_id = aws_api_gateway_resource.sensor_device.id
  http_method = aws_api_gateway_method.sensor_device_options.http_method
  status_code = aws_api_gateway_method_response.sensor_device_options_200.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization,X-Amz-Date,X-Api-Key'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# --- Deploy REST API ---
resource "aws_api_gateway_deployment" "rest_deployment" {
  rest_api_id = aws_api_gateway_rest_api.sensor_api.id

  depends_on = [
    aws_api_gateway_integration.get_sensor_data,
    aws_api_gateway_integration.list_sensors,
    aws_api_gateway_integration.sensors_options,
    aws_api_gateway_integration.sensor_device_options,
  ]

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.sensors,
      aws_api_gateway_resource.sensor_device,
      aws_api_gateway_method.get_sensor_data,
      aws_api_gateway_method.list_sensors,
      aws_api_gateway_integration.get_sensor_data,
      aws_api_gateway_integration.list_sensors,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "rest_stage" {
  deployment_id = aws_api_gateway_deployment.rest_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.sensor_api.id
  stage_name    = var.environment
}

# --- Lambda Permission for REST API ---
resource "aws_lambda_permission" "api_gateway_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.api_handler_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.sensor_api.execution_arn}/*/*"
}

# ============================================================
# WebSocket API (for real-time data streaming)
# ============================================================

resource "aws_apigatewayv2_api" "websocket" {
  name                       = "${local.prefix}-websocket-api"
  protocol_type              = "WEBSOCKET"
  route_selection_expression = "$request.body.action"
}

# --- Connect Route ---
resource "aws_apigatewayv2_integration" "websocket_connect" {
  api_id             = aws_apigatewayv2_api.websocket.id
  integration_type   = "AWS_PROXY"
  integration_uri    = var.websocket_connect_invoke_arn
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "websocket_connect" {
  api_id    = aws_apigatewayv2_api.websocket.id
  route_key = "$connect"
  target    = "integrations/${aws_apigatewayv2_integration.websocket_connect.id}"
}

# --- Disconnect Route ---
resource "aws_apigatewayv2_integration" "websocket_disconnect" {
  api_id             = aws_apigatewayv2_api.websocket.id
  integration_type   = "AWS_PROXY"
  integration_uri    = var.websocket_disconnect_invoke_arn
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "websocket_disconnect" {
  api_id    = aws_apigatewayv2_api.websocket.id
  route_key = "$disconnect"
  target    = "integrations/${aws_apigatewayv2_integration.websocket_disconnect.id}"
}

# --- Default Route ---
resource "aws_apigatewayv2_integration" "websocket_default" {
  api_id             = aws_apigatewayv2_api.websocket.id
  integration_type   = "AWS_PROXY"
  integration_uri    = var.websocket_default_invoke_arn
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "websocket_default" {
  api_id    = aws_apigatewayv2_api.websocket.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.websocket_default.id}"
}

# --- Deploy WebSocket API ---
resource "aws_apigatewayv2_stage" "websocket_stage" {
  api_id      = aws_apigatewayv2_api.websocket.id
  name        = var.environment
  auto_deploy = true

  default_route_settings {
    throttling_burst_limit = 100
    throttling_rate_limit  = 50
  }
}

# --- Lambda Permissions for WebSocket API ---
resource "aws_lambda_permission" "websocket_connect" {
  statement_id  = "AllowWebSocketConnect"
  action        = "lambda:InvokeFunction"
  function_name = var.websocket_connect_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.websocket.execution_arn}/*/*"
}

resource "aws_lambda_permission" "websocket_disconnect" {
  statement_id  = "AllowWebSocketDisconnect"
  action        = "lambda:InvokeFunction"
  function_name = var.websocket_disconnect_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.websocket.execution_arn}/*/*"
}

resource "aws_lambda_permission" "websocket_default" {
  statement_id  = "AllowWebSocketDefault"
  action        = "lambda:InvokeFunction"
  function_name = var.websocket_default_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.websocket.execution_arn}/*/*"
}
