output "user_pool_id" {
  description = "Cognito User Pool ID"
  value       = aws_cognito_user_pool.dashboard.id
}

output "user_pool_arn" {
  description = "Cognito User Pool ARN"
  value       = aws_cognito_user_pool.dashboard.arn
}

output "client_id" {
  description = "Cognito App Client ID"
  value       = aws_cognito_user_pool_client.dashboard_client.id
}

output "domain" {
  description = "Cognito hosted UI domain"
  value       = aws_cognito_user_pool_domain.dashboard_domain.domain
}

output "hosted_ui_url" {
  description = "Full Cognito hosted UI URL"
  value       = "https://${aws_cognito_user_pool_domain.dashboard_domain.domain}.auth.${data.aws_region.current.name}.amazoncognito.com"
}
