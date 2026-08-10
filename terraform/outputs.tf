output "iot_endpoint" {
  description = "AWS IoT Core endpoint for MQTT connections"
  value       = module.iot_core.iot_endpoint
}

output "rest_api_url" {
  description = "REST API endpoint for querying sensor data"
  value       = module.api_gateway.rest_api_url
}

output "websocket_api_url" {
  description = "WebSocket API endpoint for real-time data"
  value       = module.api_gateway.websocket_api_url
}

output "cognito_user_pool_id" {
  description = "Cognito User Pool ID"
  value       = module.cognito.user_pool_id
}

output "cognito_client_id" {
  description = "Cognito App Client ID"
  value       = module.cognito.client_id
}

output "dashboard_url" {
  description = "CloudFront URL for the dashboard"
  value       = module.frontend_hosting.cloudfront_url
}

output "s3_bucket_name" {
  description = "S3 bucket for dashboard static files"
  value       = module.frontend_hosting.bucket_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID (for cache invalidation)"
  value       = module.frontend_hosting.cloudfront_distribution_id
}

output "iot_certificate_arn" {
  description = "IoT Certificate ARN (attach to ESP32)"
  value       = module.iot_core.certificate_arn
}

output "iot_certificate_pem" {
  description = "IoT Device Certificate PEM (for ESP32)"
  value       = module.iot_core.certificate_pem
  sensitive   = true
}

output "iot_private_key" {
  description = "IoT Device Private Key (for ESP32)"
  value       = module.iot_core.private_key
  sensitive   = true
}

output "sns_alerts_topic_arn" {
  description = "SNS Topic ARN for sensor alerts"
  value       = module.alerts.sns_topic_arn
}
