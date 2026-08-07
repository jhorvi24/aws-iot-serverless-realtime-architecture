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

variable "iot_thing_name" {
  description = "Name of the IoT Thing (ESP32 device)"
  type        = string
}

variable "mqtt_topic" {
  description = "MQTT topic for sensor data"
  type        = string
}

variable "iot_processor_arn" {
  description = "ARN of the IoT processor Lambda function"
  type        = string
}
