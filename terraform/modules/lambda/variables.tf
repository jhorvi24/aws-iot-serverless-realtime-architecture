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

variable "sns_topic_arn" {
  description = "SNS Topic ARN for sensor alerts"
  type        = string
}

variable "temperature_threshold_high" {
  description = "Temperature upper threshold (Celsius)"
  type        = number
}

variable "temperature_threshold_low" {
  description = "Temperature lower threshold (Celsius)"
  type        = number
}

variable "humidity_threshold_high" {
  description = "Humidity upper threshold (%)"
  type        = number
}

variable "humidity_threshold_low" {
  description = "Humidity lower threshold (%)"
  type        = number
}
