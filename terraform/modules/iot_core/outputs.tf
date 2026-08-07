output "iot_endpoint" {
  description = "AWS IoT Core MQTT endpoint"
  value       = data.aws_iot_endpoint.endpoint.endpoint_address
}

output "certificate_arn" {
  description = "IoT Certificate ARN"
  value       = aws_iot_certificate.esp32_cert.arn
}

output "certificate_pem" {
  description = "IoT Certificate PEM (save securely for ESP32)"
  value       = aws_iot_certificate.esp32_cert.certificate_pem
  sensitive   = true
}

output "private_key" {
  description = "IoT Certificate Private Key (save securely for ESP32)"
  value       = aws_iot_certificate.esp32_cert.private_key
  sensitive   = true
}

output "thing_name" {
  description = "IoT Thing name"
  value       = aws_iot_thing.esp32.name
}

output "topic_rule_arn" {
  description = "IoT Topic Rule ARN"
  value       = aws_iot_topic_rule.sensor_data_rule.arn
}
