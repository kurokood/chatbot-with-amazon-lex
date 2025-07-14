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

  inline_policy {
    name = "DynamoDBReadAccess"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = ["dynamodb:GetItem", "dynamodb:Query"]
          Effect = "Allow"
          Resource = [
            aws_dynamodb_table.meetings_table.arn,
            "${aws_dynamodb_table.meetings_table.arn}/index/StatusIndex"
          ]
        }
      ]
    })
  }
}

resource "aws_iam_role_policy_attachment" "lambda_execution_role_get_meetings_basic" {
  role       = aws_iam_role.lambda_execution_role_get_meetings.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "get_meetings_lambda" {
  function_name = "get-meetings"
  role          = aws_iam_role.lambda_execution_role_get_meetings.arn
  handler       = "index.lambda_handler"
  runtime       = "python3.12"
  timeout       = 60

  filename = "${path.module}/lambda/get_meetings.zip"
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

  inline_policy {
    name = "DynamoDBReadAccess"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = ["dynamodb:GetItem", "dynamodb:Query"]
          Effect = "Allow"
          Resource = [
            aws_dynamodb_table.meetings_table.arn,
            "${aws_dynamodb_table.meetings_table.arn}/index/StatusIndex"
          ]
        }
      ]
    })
  }
}

resource "aws_iam_role_policy_attachment" "lambda_execution_role_get_pending_meetings_basic" {
  role       = aws_iam_role.lambda_execution_role_get_pending_meetings.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "get_pending_meetings_lambda" {
  function_name = "get-pending-meetings"
  role          = aws_iam_role.lambda_execution_role_get_pending_meetings.arn
  handler       = "index.lambda_handler"
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

  inline_policy {
    name = "DynamoDBWriteAccess"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action   = ["dynamodb:UpdateItem", "dynamodb:DescribeTable"]
          Effect   = "Allow"
          Resource = aws_dynamodb_table.meetings_table.arn
        }
      ]
    })
  }
}

resource "aws_iam_role_policy_attachment" "lambda_execution_role_change_meeting_status_basic" {
  role       = aws_iam_role.lambda_execution_role_change_meeting_status.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "change_meeting_status_lambda" {
  function_name = "change-meeting-status"
  role          = aws_iam_role.lambda_execution_role_change_meeting_status.arn
  handler       = "index.lambda_handler"
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

# CHATBOT LAMBDA
resource "aws_iam_role" "lambda_execution_role_chatbot" {
  name = "LambdaExecutionRoleChatbot"

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

resource "aws_iam_role_policy_attachment" "lambda_execution_role_chatbot_basic" {
  role       = aws_iam_role.lambda_execution_role_chatbot.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_execution_role_chatbot_lex" {
  role       = aws_iam_role.lambda_execution_role_chatbot.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonLexFullAccess"
}

resource "aws_lambda_function" "chatbot_lambda" {
  function_name = "chatbot-meety"
  role          = aws_iam_role.lambda_execution_role_chatbot.arn
  handler       = "index.lambda_handler"
  runtime       = "python3.12"
  timeout       = 60

  filename = "${path.module}/lambda/chatbot.zip"

  environment {
    variables = {
      BOT_ID = aws_lex_bot.meety_bot.id
    }
  }
}

resource "aws_lambda_permission" "chatbot_lambda_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.chatbot_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}

# LEX LAMBDA FUNCTION
resource "aws_iam_role" "lex_lambda_execution_role" {
  name = "LexLambdaExecutionRole"

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

  inline_policy {
    name = "DynamoDBAccess"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = ["dynamodb:PutItem", "dynamodb:Query"]
          Effect = "Allow"
          Resource = [
            aws_dynamodb_table.meetings_table.arn,
            "${aws_dynamodb_table.meetings_table.arn}/index/StatusIndex"
          ]
        }
      ]
    })
  }
}

resource "aws_iam_role_policy_attachment" "lex_lambda_execution_role_basic" {
  role       = aws_iam_role.lex_lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "lex_lambda" {
  function_name = "bot-function-meety"
  role          = aws_iam_role.lex_lambda_execution_role.arn
  handler       = "index.lambda_handler"
  runtime       = "python3.12"
  timeout       = 60

  filename = "${path.module}/lambda/lex.zip"
}

resource "aws_lambda_permission" "lex_lambda_permission" {
  statement_id  = "AllowLex"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lex_lambda.function_name
  principal     = "lexv2.amazonaws.com"
  source_arn    = "arn:aws:lex:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:bot-alias/${aws_lex_bot.meety_bot.name}/TSTALIASID"
}