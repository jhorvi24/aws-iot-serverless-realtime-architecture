variable "project_name" {
  description = "Project name prefix"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "account_id" {
  description = "AWS account ID"
  type        = string
}

variable "cognito_user_pool_arn" {
  description = "Cognito User Pool ARN for REST API authorization"
  type        = string
}

variable "api_handler_invoke_arn" {
  description = "API Handler Lambda invoke ARN"
  type        = string
}

variable "api_handler_function_name" {
  description = "API Handler Lambda function name"
  type        = string
}

variable "websocket_connect_invoke_arn" {
  description = "WebSocket Connect Lambda invoke ARN"
  type        = string
}

variable "websocket_connect_function_name" {
  description = "WebSocket Connect Lambda function name"
  type        = string
}

variable "websocket_disconnect_invoke_arn" {
  description = "WebSocket Disconnect Lambda invoke ARN"
  type        = string
}

variable "websocket_disconnect_function_name" {
  description = "WebSocket Disconnect Lambda function name"
  type        = string
}

variable "websocket_default_invoke_arn" {
  description = "WebSocket Default Lambda invoke ARN"
  type        = string
}

variable "websocket_default_function_name" {
  description = "WebSocket Default Lambda function name"
  type        = string
}
