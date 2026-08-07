output "rest_api_url" {
  description = "REST API endpoint URL"
  value       = "${aws_api_gateway_stage.rest_stage.invoke_url}"
}

output "websocket_api_url" {
  description = "WebSocket API endpoint URL"
  value       = "${aws_apigatewayv2_stage.websocket_stage.invoke_url}"
}

output "websocket_api_id" {
  description = "WebSocket API Gateway ID"
  value       = aws_apigatewayv2_api.websocket.id
}

output "rest_api_id" {
  description = "REST API Gateway ID"
  value       = aws_api_gateway_rest_api.sensor_api.id
}
