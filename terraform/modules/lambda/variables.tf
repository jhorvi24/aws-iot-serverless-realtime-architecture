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

variable "dynamodb_table_name" {
  description = "DynamoDB sensor data table name"
  type        = string
}

variable "dynamodb_table_arn" {
  description = "DynamoDB sensor data table ARN"
  type        = string
}

variable "websocket_connections_table_name" {
  description = "DynamoDB WebSocket connections table name"
  type        = string
}

variable "websocket_connections_table_arn" {
  description = "DynamoDB WebSocket connections table ARN"
  type        = string
}
