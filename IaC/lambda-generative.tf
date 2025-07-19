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

# Bedrock access policy for Lambda
resource "aws_iam_role_policy" "generative_lambda_bedrock_policy" {
  name = "GenerativeLambdaBedrockPolicy"
  role = aws_iam_role.generative_lambda_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream"
        ]
        Resource = [
          "arn:aws:bedrock:us-east-1::foundation-model/anthropic.claude-3-sonnet-20240229-v1:0",
          "arn:aws:bedrock:us-east-1::foundation-model/anthropic.claude-3-haiku-20240307-v1:0"
        ]
      }
    ]
  })
}

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
      DYNAMODB_TABLE   = aws_dynamodb_table.meetings_table.name
      BOT_ID           = aws_lexv2models_bot.meety_generative_bot.id
      BOT_ALIAS_ID     = "TSTALIASID" # Manual alias created in AWS Console
    }
  }
}

# Lambda permission for Lex to invoke the function
resource "aws_lambda_permission" "generative_lex_lambda_permission" {
  statement_id  = "AllowLexInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.generative_lex_lambda.function_name
  principal     = "lexv2.amazonaws.com"
  source_arn    = "arn:aws:lex:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:bot-alias/${aws_lexv2models_bot.meety_generative_bot.id}/TSTALIASID"
}

# Enhanced Chatbot Lambda for API Gateway with Generative AI
resource "aws_lambda_function" "generative_chatbot_lambda" {
  function_name = "generative-chatbot-api"
  role          = aws_iam_role.generative_lambda_execution_role.arn
  handler       = "generative_chatbot.lambda_handler"
  runtime       = "python3.12"
  timeout       = 60

  filename = "${path.module}/lambda/generative_chatbot.zip"

  environment {
    variables = {
      BOT_ID       = aws_lexv2models_bot.meety_generative_bot.id
      BOT_ALIAS_ID = "TSTALIASID" # Manual alias created in AWS Console
      LOCALE_ID    = "en_US"
    }
  }
}

# Lambda permission for API Gateway to invoke the chatbot function
resource "aws_lambda_permission" "generative_chatbot_lambda_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.generative_chatbot_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}
