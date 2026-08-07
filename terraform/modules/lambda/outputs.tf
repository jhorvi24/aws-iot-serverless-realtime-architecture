output "iot_processor_arn" {
  description = "IoT Processor Lambda ARN"
  value       = aws_lambda_function.iot_processor.arn
}

output "iot_processor_function_name" {
  description = "IoT Processor Lambda function name"
  value       = aws_lambda_function.iot_processor.function_name
}

output "api_handler_invoke_arn" {
  description = "API Handler Lambda invoke ARN"
  value       = aws_lambda_function.api_handler.invoke_arn
}

output "api_handler_function_name" {
  description = "API Handler Lambda function name"
  value       = aws_lambda_function.api_handler.function_name
}

output "websocket_connect_invoke_arn" {
  description = "WebSocket Connect Lambda invoke ARN"
  value       = aws_lambda_function.websocket_connect.invoke_arn
}

output "websocket_connect_function_name" {
  description = "WebSocket Connect Lambda function name"
  value       = aws_lambda_function.websocket_connect.function_name
}

output "websocket_disconnect_invoke_arn" {
  description = "WebSocket Disconnect Lambda invoke ARN"
  value       = aws_lambda_function.websocket_disconnect.invoke_arn
}

output "websocket_disconnect_function_name" {
  description = "WebSocket Disconnect Lambda function name"
  value       = aws_lambda_function.websocket_disconnect.function_name
}

output "websocket_default_invoke_arn" {
  description = "WebSocket Default Lambda invoke ARN"
  value       = aws_lambda_function.websocket_default.invoke_arn
}

output "websocket_default_function_name" {
  description = "WebSocket Default Lambda function name"
  value       = aws_lambda_function.websocket_default.function_name
}
