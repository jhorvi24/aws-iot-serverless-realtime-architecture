# ============================================================
# DynamoDB Tables - Sensor Data & WebSocket Connections
# ============================================================

locals {
  prefix = "${var.project_name}-${var.environment}"
}

# --- Sensor Data Table ---
resource "aws_dynamodb_table" "sensor_data" {
  name         = "${local.prefix}-sensor-data"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "device_id"
  range_key    = "timestamp"

  attribute {
    name = "device_id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "N"
  }

  ttl {
    attribute_name = "expiry_time"
    enabled        = true
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Name = "${local.prefix}-sensor-data"
  }
}

# --- WebSocket Connections Table ---
resource "aws_dynamodb_table" "websocket_connections" {
  name         = "${local.prefix}-ws-connections"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "connection_id"

  attribute {
    name = "connection_id"
    type = "S"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  tags = {
    Name = "${local.prefix}-ws-connections"
  }
}
