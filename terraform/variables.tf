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

# --- Alert Configuration ---

variable "alert_email" {
  description = "Email address to receive sensor alert notifications"
  type        = string
  default     = ""
}

variable "temperature_threshold_high" {
  description = "Temperature upper threshold (Celsius) - triggers alert when exceeded"
  type        = number
  default     = 35.0
}

variable "temperature_threshold_low" {
  description = "Temperature lower threshold (Celsius) - triggers alert when below"
  type        = number
  default     = 5.0
}

variable "humidity_threshold_high" {
  description = "Humidity upper threshold (%) - triggers alert when exceeded"
  type        = number
  default     = 85.0
}

variable "humidity_threshold_low" {
  description = "Humidity lower threshold (%) - triggers alert when below"
  type        = number
  default     = 20.0
}
