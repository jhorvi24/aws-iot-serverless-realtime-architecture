variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS Profile"
  type = string
  default = " "
  
}

variable "project_name" {
  description = "Project name used as prefix for all resources"
  type        = string
  default     = "iot-serverless"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "iot_thing_name" {
  description = "Name of the IoT Thing (ESP32 device)"
  type        = string
  default     = "esp32-sensor-01"
}

variable "mqtt_topic" {
  description = "MQTT topic for sensor data"
  type        = string
  default     = "sensors/esp32/data"
}

variable "dashboard_domain" {
  description = "Custom domain for the dashboard (optional)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project     = "IoT-Serverless"
    ManagedBy   = "Terraform"
  }
}
