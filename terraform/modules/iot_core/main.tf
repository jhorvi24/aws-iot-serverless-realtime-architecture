# ============================================================
# AWS IoT Core - Thing, Certificate, Policy, and Rule
# ============================================================

locals {
  prefix = "${var.project_name}-${var.environment}"
}

# --- IoT Thing ---
resource "aws_iot_thing" "esp32" {
  name = var.iot_thing_name

  attributes = {
    type        = "temperature_humidity_sensor"
    environment = var.environment
  }
}

# --- IoT Certificate ---
resource "aws_iot_certificate" "esp32_cert" {
  active = true
}

# --- Attach Certificate to Thing ---
resource "aws_iot_thing_principal_attachment" "esp32_attachment" {
  principal = aws_iot_certificate.esp32_cert.arn
  thing     = aws_iot_thing.esp32.name
}

# --- IoT Policy ---
resource "aws_iot_policy" "esp32_policy" {
  name = "${local.prefix}-esp32-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iot:Connect"
        ]
        Resource = "arn:aws:iot:${var.region}:${var.account_id}:client/${var.iot_thing_name}"
      },
      {
        Effect = "Allow"
        Action = [
          "iot:Publish"
        ]
        Resource = "arn:aws:iot:${var.region}:${var.account_id}:topic/${var.mqtt_topic}"
      },
      {
        Effect = "Allow"
        Action = [
          "iot:Subscribe"
        ]
        Resource = "arn:aws:iot:${var.region}:${var.account_id}:topicfilter/${var.mqtt_topic}"
      },
      {
        Effect = "Allow"
        Action = [
          "iot:Receive"
        ]
        Resource = "arn:aws:iot:${var.region}:${var.account_id}:topic/${var.mqtt_topic}"
      }
    ]
  })
}

# --- Attach Policy to Certificate ---
resource "aws_iot_policy_attachment" "esp32_policy_attachment" {
  policy = aws_iot_policy.esp32_policy.name
  target = aws_iot_certificate.esp32_cert.arn
}

# --- IoT Topic Rule (routes MQTT messages to Lambda) ---
resource "aws_iot_topic_rule" "sensor_data_rule" {
  name        = "${replace(local.prefix, "-", "_")}_sensor_data"
  description = "Route sensor data from ESP32 to Lambda for processing"
  enabled     = true
  sql         = "SELECT *, topic() as mqtt_topic, timestamp() as received_at FROM '${var.mqtt_topic}'"
  sql_version = "2016-03-23"

  lambda {
    function_arn = var.iot_processor_arn
  }

  error_action {
    cloudwatch_logs {
      log_group_name = "/aws/iot/${local.prefix}/errors"
      role_arn       = aws_iam_role.iot_rule_role.arn
    }
  }
}

# --- IAM Role for IoT Rule error logging ---
resource "aws_iam_role" "iot_rule_role" {
  name = "${local.prefix}-iot-rule-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "iot.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "iot_rule_logging" {
  name = "${local.prefix}-iot-rule-logging"
  role = aws_iam_role.iot_rule_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.region}:${var.account_id}:log-group:/aws/iot/${local.prefix}/*"
      }
    ]
  })
}

# --- Lambda Permission for IoT Rule ---
resource "aws_lambda_permission" "iot_invoke_lambda" {
  statement_id  = "AllowIoTInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.iot_processor_arn
  principal     = "iot.amazonaws.com"
  source_arn    = aws_iot_topic_rule.sensor_data_rule.arn
}

# --- IoT Endpoint Data Source ---
data "aws_iot_endpoint" "endpoint" {
  endpoint_type = "iot:Data-ATS"
}
