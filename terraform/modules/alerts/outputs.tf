output "sns_topic_arn" {
  description = "SNS Topic ARN for sensor alerts"
  value       = aws_sns_topic.sensor_alerts.arn
}

output "temperature_threshold_high" {
  description = "Temperature high threshold"
  value       = var.temperature_threshold_high
}

output "temperature_threshold_low" {
  description = "Temperature low threshold"
  value       = var.temperature_threshold_low
}

output "humidity_threshold_high" {
  description = "Humidity high threshold"
  value       = var.humidity_threshold_high
}

output "humidity_threshold_low" {
  description = "Humidity low threshold"
  value       = var.humidity_threshold_low
}
