resource "aws_dynamodb_table" "meetings_table" {
  name           = "Meetings"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "meetingId"

  attribute {
    name = "meetingId"
    type = "S"
  }

  attribute {
    name = "status"
    type = "S"
  }

  attribute {
    name = "date"
    type = "S"
  }

  global_secondary_index {
    name            = "StatusIndex"
    hash_key        = "status"
    range_key       = "date"
    projection_type = "ALL"
  }
}

resource "aws_cognito_user_pool" "user_pool" {
  name = var.user_pool_name

  auto_verified_attributes = ["email"]

  password_policy {
    minimum_length    = 6
    require_lowercase = false
    require_numbers   = false
    require_symbols   = false
    require_uppercase = false
  }

  mfa_configuration = "OFF"

  admin_create_user_config {
    allow_admin_create_user_only = true
  }

  
}

resource "aws_cognito_user_pool_client" "user_pool_client" {
  name                                 = "my-user-pool-client"
  user_pool_id                         = aws_cognito_user_pool.user_pool.id
  generate_secret                      = false
  explicit_auth_flows                  = ["ADMIN_NO_SRP_AUTH"]
}

resource "aws_cognito_user" "user" {
  user_pool_id = aws_cognito_user_pool.user_pool.id
  username     = var.username

  attributes = {
    email          = var.user_email
    email_verified = true
  }
}

resource "aws_apigatewayv2_api" "http_api" {
  name          = var.api_name
  protocol_type = "HTTP"
  description   = "Meeti API"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "PUT", "DELETE"]
    allow_headers = ["*"]
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

data "aws_region" "current" {}
