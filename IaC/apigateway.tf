resource "aws_apigatewayv2_api" "http_api" {
  name          = var.api_name
  protocol_type = "HTTP"
  description   = "Meeti API"

  cors_configuration {
    allow_origins = ["*"]  # Use wildcard for testing
    allow_methods = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    allow_headers = ["Content-Type", "Authorization", "X-Amz-Date", "X-Api-Key", "X-Amz-Security-Token", "Accept"]
    allow_credentials = false  # Set to false when using wildcard origin
    expose_headers = ["WWW-Authenticate", "Server-Authorization"]
    max_age = 300
  }
}

resource "aws_apigatewayv2_stage" "http_api_stage" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "dev"
  auto_deploy = true
}

resource "aws_apigatewayv2_authorizer" "jwt_authorizer" {
  api_id           = aws_apigatewayv2_api.http_api.id
  name             = "CognitoAuthorizer"
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]

  jwt_configuration {
    audience = [aws_cognito_user_pool_client.user_pool_client.id]
    issuer   = "https://cognito-idp.${data.aws_region.current.name}.amazonaws.com/${aws_cognito_user_pool.user_pool.id}"
  }
}

# GET MEETINGS ROUTE
resource "aws_apigatewayv2_route" "get_meetings" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "GET /meetings"
  target    = "integrations/${aws_apigatewayv2_integration.get_meetings.id}"

  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.jwt_authorizer.id
}

resource "aws_apigatewayv2_integration" "get_meetings" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.get_meetings_lambda.invoke_arn
  payload_format_version = "2.0"
}

# GET PENDING MEETINGS ROUTE
resource "aws_apigatewayv2_route" "get_pending_meetings" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "GET /pending"
  target    = "integrations/${aws_apigatewayv2_integration.get_pending_meetings.id}"

  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.jwt_authorizer.id
}

resource "aws_apigatewayv2_integration" "get_pending_meetings" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.get_pending_meetings_lambda.invoke_arn
  payload_format_version = "2.0"
}

# PUT STATUS ROUTE
resource "aws_apigatewayv2_route" "put_status" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "PUT /status"
  target    = "integrations/${aws_apigatewayv2_integration.put_status.id}"

  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.jwt_authorizer.id
}

resource "aws_apigatewayv2_integration" "put_status" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.change_meeting_status_lambda.invoke_arn
  payload_format_version = "2.0"
}

# GENERATIVE AI CHATBOT ROUTE
resource "aws_apigatewayv2_route" "generative_chatbot" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST /chatbot"
  target    = "integrations/${aws_apigatewayv2_integration.generative_chatbot.id}"
}

# OPTIONS route for CORS preflight requests with direct integration
resource "aws_apigatewayv2_route" "generative_chatbot_options" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "OPTIONS /chatbot"
  target    = "integrations/${aws_apigatewayv2_integration.options_integration.id}"
}

# Integration for POST /chatbot
resource "aws_apigatewayv2_integration" "generative_chatbot" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.generative_chatbot_lambda.invoke_arn
  payload_format_version = "2.0"
}

# Direct integration for OPTIONS /chatbot (CORS preflight)
resource "aws_apigatewayv2_integration" "options_integration" {
  api_id             = aws_apigatewayv2_api.http_api.id
  integration_type   = "MOCK"
  
  integration_method = "OPTIONS"
  
  # Return a 200 OK with CORS headers
  integration_response_selection_expression = "$default"
  
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}
# Integration response for OPTIONS method
resource "aws_apigatewayv2_integration_response" "options_integration_response" {
  api_id                   = aws_apigatewayv2_api.http_api.id
  integration_id           = aws_apigatewayv2_integration.options_integration.id
  integration_response_key = "$default"
  
  # Include CORS headers in the response
  response_templates = {
    "application/json" = "#set($origin = $input.params().header.get('Origin'))\n{\n  \"statusCode\": 200,\n  \"headers\": {\n    \"Access-Control-Allow-Origin\": \"*\",\n    \"Access-Control-Allow-Headers\": \"Content-Type,Authorization,X-Amz-Date,X-Api-Key,X-Amz-Security-Token,Accept\",\n    \"Access-Control-Allow-Methods\": \"GET,POST,OPTIONS\",\n    \"Access-Control-Max-Age\": \"300\"\n  },\n  \"body\": \"{\\\"message\\\": \\\"CORS preflight successful\\\"}\"\n}"
  }
}

# Route response for OPTIONS method
resource "aws_apigatewayv2_route_response" "options_route_response" {
  api_id             = aws_apigatewayv2_api.http_api.id
  route_id           = aws_apigatewayv2_route.generative_chatbot_options.id
  route_response_key = "$default"
}