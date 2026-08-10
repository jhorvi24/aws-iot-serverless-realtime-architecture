# ============================================================
# Alerts Module - SNS Topic for threshold notifications
# ============================================================

locals {
  prefix = "${var.project_name}-${var.environment}"
}

# --- SNS Topic for sensor alerts ---
resource "aws_sns_topic" "sensor_alerts" {
  name = "${local.prefix}-sensor-alerts"

  tags = {
    Name = "${local.prefix}-sensor-alerts"
  }
}

# --- Email subscription ---
resource "aws_sns_topic_subscription" "email_alert" {
  topic_arn = aws_sns_topic.sensor_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}
