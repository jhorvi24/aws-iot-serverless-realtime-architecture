output "table_name" {
  description = "Sensor data DynamoDB table name"
  value       = aws_dynamodb_table.sensor_data.name
}

output "table_arn" {
  description = "Sensor data DynamoDB table ARN"
  value       = aws_dynamodb_table.sensor_data.arn
}

output "connections_table_name" {
  description = "WebSocket connections DynamoDB table name"
  value       = aws_dynamodb_table.websocket_connections.name
}

output "connections_table_arn" {
  description = "WebSocket connections DynamoDB table ARN"
  value       = aws_dynamodb_table.websocket_connections.arn
}
