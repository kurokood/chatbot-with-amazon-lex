# Local values for constructing bot alias ARN
locals {
  bot_alias_name = "prod"
  bot_alias_id   = "HUCBWNPSPM"  # Actual bot alias ID from AWS
  bot_alias_arn  = "arn:aws:lex:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:bot-alias/${aws_lexv2models_bot.meety_generative_bot.id}/${local.bot_alias_id}"
}

resource "aws_cognito_identity_pool" "identity_pool" {
  identity_pool_name               = "meety_identity_pool"
  allow_unauthenticated_identities = true
  allow_classic_flow               = false

  cognito_identity_providers {
    client_id               = aws_cognito_user_pool_client.user_pool_client.id
    provider_name           = aws_cognito_user_pool.user_pool.endpoint
    server_side_token_check = false
  }
}

resource "aws_iam_role" "authenticated_role" {
  name = "meety_authenticated_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "cognito-identity.amazonaws.com"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "cognito-identity.amazonaws.com:aud" = aws_cognito_identity_pool.identity_pool.id
          }
          "ForAnyValue:StringLike" = {
            "cognito-identity.amazonaws.com:amr" = "authenticated"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role" "unauthenticated_role" {
  name = "meety_unauthenticated_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "cognito-identity.amazonaws.com"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "cognito-identity.amazonaws.com:aud" = aws_cognito_identity_pool.identity_pool.id
          }
          "ForAnyValue:StringLike" = {
            "cognito-identity.amazonaws.com:amr" = "unauthenticated"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "lex_policy" {
  name        = "meety_lex_policy"
  description = "Policy for accessing Lex V2 from the frontend"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lex:RecognizeText",
          "lex:RecognizeUtterance",
          "lex:StartConversation"
        ]
        Resource = local.bot_alias_arn
      }
    ]
  })
}

resource "aws_iam_policy" "lex_policy_unauth" {
  name        = "meety_lex_policy_unauth"
  description = "Policy for accessing Lex V2 from the frontend (unauthenticated)"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lex:RecognizeText",
          "lex:RecognizeUtterance"
        ]
        Resource = local.bot_alias_arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lex_policy_attachment" {
  role       = aws_iam_role.authenticated_role.name
  policy_arn = aws_iam_policy.lex_policy.arn
}

resource "aws_iam_role_policy_attachment" "lex_policy_unauth_attachment" {
  role       = aws_iam_role.unauthenticated_role.name
  policy_arn = aws_iam_policy.lex_policy_unauth.arn
}

resource "aws_cognito_identity_pool_roles_attachment" "identity_pool_roles" {
  identity_pool_id = aws_cognito_identity_pool.identity_pool.id

  roles = {
    "authenticated"   = aws_iam_role.authenticated_role.arn
    "unauthenticated" = aws_iam_role.unauthenticated_role.arn
  }
}

# Variables are defined in variables.tf
# Outputs are defined in outputs.tf