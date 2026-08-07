# ============================================================
# Lambda Functions - IoT Processor, API Handler, WebSocket
# ============================================================

locals {
  prefix = "${var.project_name}-${var.environment}"
}

# --- Package Lambda source code ---
data "archive_file" "iot_processor" {
  type        = "zip"
  source_dir  = "${path.root}/../lambda/iot_processor"
  output_path = "${path.root}/.build/iot_processor.zip"
}

data "archive_file" "api_handler" {
  type        = "zip"
  source_dir  = "${path.root}/../lambda/api_handler"
  output_path = "${path.root}/.build/api_handler.zip"
}

data "archive_file" "websocket_handler" {
  type        = "zip"
  source_dir  = "${path.root}/../lambda/websocket_handler"
  output_path = "${path.root}/.build/websocket_handler.zip"
}

# ============================================================
# IAM Roles
# ============================================================

# --- IoT Processor Role ---
resource "aws_iam_role" "iot_processor_role" {
  name = "${local.prefix}-iot-processor-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "iot_processor_policy" {
  name = "${local.prefix}-iot-processor-policy"
  role = aws_iam_role.iot_processor_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:Query"
        ]
        Resource = var.dynamodb_table_arn
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:Scan",
          "dynamodb:GetItem"
        ]
        Resource = var.websocket_connections_table_arn
      },
      {
        Effect = "Allow"
        Action = [
          "execute-api:ManageConnections"
        ]
        Resource = "arn:aws:execute-api:${var.region}:${var.account_id}:*/*/@connections/*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.region}:${var.account_id}:*"
      }
    ]
  })
}

# --- API Handler Role ---
resource "aws_iam_role" "api_handler_role" {
  name = "${local.prefix}-api-handler-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "api_handler_policy" {
  name = "${local.prefix}-api-handler-policy"
  role = aws_iam_role.api_handler_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:Query",
          "dynamodb:GetItem",
          "dynamodb:Scan"
        ]
        Resource = [
          var.dynamodb_table_arn,
          "${var.dynamodb_table_arn}/index/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.region}:${var.account_id}:*"
      }
    ]
  })
}

# --- WebSocket Handler Role ---
resource "aws_iam_role" "websocket_handler_role" {
  name = "${local.prefix}-websocket-handler-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "websocket_handler_policy" {
  name = "${local.prefix}-websocket-handler-policy"
  role = aws_iam_role.websocket_handler_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
          "dynamodb:Scan",
          "dynamodb:GetItem"
        ]
        Resource = var.websocket_connections_table_arn
      },
      {
        Effect = "Allow"
        Action = [
          "execute-api:ManageConnections"
        ]
        Resource = "arn:aws:execute-api:${var.region}:${var.account_id}:*/*/@connections/*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.region}:${var.account_id}:*"
      }
    ]
  })
}

# ============================================================
# Lambda Functions
# ============================================================

# --- IoT Processor Lambda ---
resource "aws_lambda_function" "iot_processor" {
  function_name    = "${local.prefix}-iot-processor"
  filename         = data.archive_file.iot_processor.output_path
  source_code_hash = data.archive_file.iot_processor.output_base64sha256
  runtime          = "python3.12"
  handler          = "handler.lambda_handler"
  role             = aws_iam_role.iot_processor_role.arn
  timeout          = 30
  memory_size      = 128

  environment {
    variables = {
      DYNAMODB_TABLE_NAME     = var.dynamodb_table_name
      CONNECTIONS_TABLE_NAME  = var.websocket_connections_table_name
      WEBSOCKET_API_ENDPOINT  = ""  # Updated after API Gateway creation
      ENVIRONMENT             = var.environment
    }
  }

  tags = {
    Name = "${local.prefix}-iot-processor"
  }
}

# --- API Handler Lambda ---
resource "aws_lambda_function" "api_handler" {
  function_name    = "${local.prefix}-api-handler"
  filename         = data.archive_file.api_handler.output_path
  source_code_hash = data.archive_file.api_handler.output_base64sha256
  runtime          = "python3.12"
  handler          = "handler.lambda_handler"
  role             = aws_iam_role.api_handler_role.arn
  timeout          = 30
  memory_size      = 128

  environment {
    variables = {
      DYNAMODB_TABLE_NAME = var.dynamodb_table_name
      ENVIRONMENT         = var.environment
    }
  }

  tags = {
    Name = "${local.prefix}-api-handler"
  }
}

# --- WebSocket Connect Handler ---
resource "aws_lambda_function" "websocket_connect" {
  function_name    = "${local.prefix}-ws-connect"
  filename         = data.archive_file.websocket_handler.output_path
  source_code_hash = data.archive_file.websocket_handler.output_base64sha256
  runtime          = "python3.12"
  handler          = "handler.connect_handler"
  role             = aws_iam_role.websocket_handler_role.arn
  timeout          = 10
  memory_size      = 128

  environment {
    variables = {
      CONNECTIONS_TABLE_NAME = var.websocket_connections_table_name
      ENVIRONMENT            = var.environment
    }
  }

  tags = {
    Name = "${local.prefix}-ws-connect"
  }
}

# --- WebSocket Disconnect Handler ---
resource "aws_lambda_function" "websocket_disconnect" {
  function_name    = "${local.prefix}-ws-disconnect"
  filename         = data.archive_file.websocket_handler.output_path
  source_code_hash = data.archive_file.websocket_handler.output_base64sha256
  runtime          = "python3.12"
  handler          = "handler.disconnect_handler"
  role             = aws_iam_role.websocket_handler_role.arn
  timeout          = 10
  memory_size      = 128

  environment {
    variables = {
      CONNECTIONS_TABLE_NAME = var.websocket_connections_table_name
      ENVIRONMENT            = var.environment
    }
  }

  tags = {
    Name = "${local.prefix}-ws-disconnect"
  }
}

# --- WebSocket Default Handler ---
resource "aws_lambda_function" "websocket_default" {
  function_name    = "${local.prefix}-ws-default"
  filename         = data.archive_file.websocket_handler.output_path
  source_code_hash = data.archive_file.websocket_handler.output_base64sha256
  runtime          = "python3.12"
  handler          = "handler.default_handler"
  role             = aws_iam_role.websocket_handler_role.arn
  timeout          = 10
  memory_size      = 128

  environment {
    variables = {
      CONNECTIONS_TABLE_NAME = var.websocket_connections_table_name
      ENVIRONMENT            = var.environment
    }
  }

  tags = {
    Name = "${local.prefix}-ws-default"
  }
}

# ============================================================
# CloudWatch Log Groups
# ============================================================

resource "aws_cloudwatch_log_group" "iot_processor" {
  name              = "/aws/lambda/${aws_lambda_function.iot_processor.function_name}"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "api_handler" {
  name              = "/aws/lambda/${aws_lambda_function.api_handler.function_name}"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "websocket_connect" {
  name              = "/aws/lambda/${aws_lambda_function.websocket_connect.function_name}"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "websocket_disconnect" {
  name              = "/aws/lambda/${aws_lambda_function.websocket_disconnect.function_name}"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "websocket_default" {
  name              = "/aws/lambda/${aws_lambda_function.websocket_default.function_name}"
  retention_in_days = 14
}
