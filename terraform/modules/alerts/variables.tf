variable "project_name" {
  description = "Project name prefix"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "alert_email" {
  description = "Email address to receive alert notifications"
  type        = string
}

variable "temperature_threshold_high" {
  description = "Temperature upper threshold (Celsius) to trigger alert"
  type        = number
  default     = 35.0
}

variable "temperature_threshold_low" {
  description = "Temperature lower threshold (Celsius) to trigger alert"
  type        = number
  default     = 5.0
}

variable "humidity_threshold_high" {
  description = "Humidity upper threshold (%) to trigger alert"
  type        = number
  default     = 85.0
}

variable "humidity_threshold_low" {
  description = "Humidity lower threshold (%) to trigger alert"
  type        = number
  default     = 20.0
}
