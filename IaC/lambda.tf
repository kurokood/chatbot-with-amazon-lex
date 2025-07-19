# SHARED IAM POLICY FOR DYNAMODB READ ACCESS
data "aws_iam_policy_document" "dynamodb_read_policy" {
  statement {
    effect = "Allow"
    actions = ["dynamodb:GetItem", "dynamodb:Query"]
    resources = [
      aws_dynamodb_table.meetings_table.arn,
      "${aws_dynamodb_table.meetings_table.arn}/index/StatusIndex"
    ]
  }
}

resource "aws_iam_policy" "dynamodb_read_policy" {
  name   = "DynamoDBReadAccess"
  policy = data.aws_iam_policy_document.dynamodb_read_policy.json
}

# SHARED IAM POLICY FOR DYNAMODB WRITE ACCESS
data "aws_iam_policy_document" "dynamodb_write_policy" {
  statement {
    effect = "Allow"
    actions = ["dynamodb:UpdateItem", "dynamodb:DescribeTable"]
    resources = [aws_dynamodb_table.meetings_table.arn]
  }
}

resource "aws_iam_policy" "dynamodb_write_policy" {
  name   = "DynamoDBWriteAccess"
  policy = data.aws_iam_policy_document.dynamodb_write_policy.json
}

# Removed unused dynamodb_put_query_policy - no longer referenced

# GET MEETINGS LAMBDA
resource "aws_iam_role" "lambda_execution_role_get_meetings" {
  name = "LambdaExecutionRoleGetMeetings"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_execution_role_get_meetings_basic" {
  role       = aws_iam_role.lambda_execution_role_get_meetings.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_execution_role_get_meetings_dynamodb" {
  role       = aws_iam_role.lambda_execution_role_get_meetings.name
  policy_arn = aws_iam_policy.dynamodb_read_policy.arn
}

resource "aws_lambda_function" "get_meetings_lambda" {
  function_name = "get-meetings"
  role          = aws_iam_role.lambda_execution_role_get_meetings.arn
  handler       = "get_meetings.lambda_handler"
  runtime       = "python3.12"
  timeout       = 60

  filename = "${path.module}/lambda/get_meetings.zip"

  # Inline code from CloudFormation template
  source_code_hash = filebase64sha256("${path.module}/lambda/get_meetings.zip")
}

resource "aws_lambda_permission" "get_meetings_lambda_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_meetings_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}

# GET PENDING MEETINGS LAMBDA
resource "aws_iam_role" "lambda_execution_role_get_pending_meetings" {
  name = "LambdaExecutionRoleGetPendingMeetings"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_execution_role_get_pending_meetings_basic" {
  role       = aws_iam_role.lambda_execution_role_get_pending_meetings.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_execution_role_get_pending_meetings_dynamodb" {
  role       = aws_iam_role.lambda_execution_role_get_pending_meetings.name
  policy_arn = aws_iam_policy.dynamodb_read_policy.arn
}

resource "aws_lambda_function" "get_pending_meetings_lambda" {
  function_name = "get-pending-meetings"
  role          = aws_iam_role.lambda_execution_role_get_pending_meetings.arn
  handler       = "get_pending_meetings.lambda_handler"
  runtime       = "python3.12"
  timeout       = 60

  filename = "${path.module}/lambda/get_pending_meetings.zip"
}

resource "aws_lambda_permission" "get_pending_meetings_lambda_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_pending_meetings_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}

# CHANGE MEETING STATUS LAMBDA
resource "aws_iam_role" "lambda_execution_role_change_meeting_status" {
  name = "LambdaExecutionRoleChangeMeetingStatus"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_execution_role_change_meeting_status_basic" {
  role       = aws_iam_role.lambda_execution_role_change_meeting_status.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_execution_role_change_meeting_status_dynamodb" {
  role       = aws_iam_role.lambda_execution_role_change_meeting_status.name
  policy_arn = aws_iam_policy.dynamodb_write_policy.arn
}

resource "aws_lambda_function" "change_meeting_status_lambda" {
  function_name = "change-meeting-status"
  role          = aws_iam_role.lambda_execution_role_change_meeting_status.arn
  handler       = "change_meeting_status.lambda_handler"
  runtime       = "python3.12"
  timeout       = 60

  filename = "${path.module}/lambda/change_meeting_status.zip"
}

resource "aws_lambda_permission" "change_meeting_status_lambda_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.change_meeting_status_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}

# Old chatbot and lex Lambda functions removed - replaced by generative AI versions in lambda-generative.tf