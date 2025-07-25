# Enhanced Lambda functions for Generative AI Lex Bot

# IAM Role for Generative AI Lambda with Bedrock permissions
resource "aws_iam_role" "generative_lambda_execution_role" {
  name = "GenerativeLambdaExecutionRole"

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

# Basic Lambda execution policy
resource "aws_iam_role_policy_attachment" "generative_lambda_basic_execution" {
  role       = aws_iam_role.generative_lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Note: Bedrock policy removed as we're not using generative AI features yet

# DynamoDB access policy for Lambda
resource "aws_iam_role_policy" "generative_lambda_dynamodb_policy" {
  name = "GenerativeLambdaDynamoDBPolicy"
  role = aws_iam_role.generative_lambda_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = [
          aws_dynamodb_table.meetings_table.arn,
          "${aws_dynamodb_table.meetings_table.arn}/index/StatusIndex"
        ]
      }
    ]
  })
}

# Note: Lex runtime policy removed as fulfillment Lambda doesn't need to call Lex directly

# Generative AI Lambda function for Lex fulfillment
resource "aws_lambda_function" "generative_lex_lambda" {
  function_name = "generative-lex-fulfillment"
  role          = aws_iam_role.generative_lambda_execution_role.arn
  handler       = "meety_lex.lambda_handler"
  runtime       = "python3.12"
  timeout       = 60

  filename = "${path.module}/lambda/meety_lex.zip"

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.meetings_table.name
      BOT_ID         = aws_lexv2models_bot.meety_generative_bot.id
      BOT_ALIAS_ID   = var.lex_bot_alias_id
    }
  }
}

# Lambda permission for Lex to invoke the function
resource "aws_lambda_permission" "generative_lex_lambda_permission" {
  statement_id  = "AllowLexInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.generative_lex_lambda.function_name
  principal     = "lexv2.amazonaws.com"
  source_arn    = "arn:aws:lex:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:bot-alias/${aws_lexv2models_bot.meety_generative_bot.id}/*"
}

# Note: generative_chatbot_lambda removed as we use direct Lex integration in frontend
