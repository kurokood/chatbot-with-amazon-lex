# Minimal Lex bot configuration - slots need to be configured manually in AWS Console
# Due to provider bugs with aws_lexv2models_slot resources

resource "aws_iam_role" "lex_bot_role" {
  name = "LexBotRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lexv2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_lexv2models_bot" "meety_bot" {
  name        = "Meety-Bot"
  description = "Meety chatbot"
  role_arn    = aws_iam_role.lex_bot_role.arn

  data_privacy {
    child_directed = false
  }

  idle_session_ttl_in_seconds = 300
}

resource "aws_lexv2models_bot_locale" "meety_bot_locale" {
  bot_id                           = aws_lexv2models_bot.meety_bot.id
  bot_version                      = "DRAFT"
  locale_id                        = "en_US"
  n_lu_intent_confidence_threshold = 0.40
}

resource "aws_lexv2models_intent" "start_meety" {
  bot_id      = aws_lexv2models_bot.meety_bot.id
  bot_version = "DRAFT"
  locale_id   = aws_lexv2models_bot_locale.meety_bot_locale.locale_id
  name        = "StartMeety"
  description = "Welcome intent"

  sample_utterance {
    utterance = "Hello"
  }
  sample_utterance {
    utterance = "Hey Meety"
  }
  sample_utterance {
    utterance = "I need your help"
  }
}

resource "aws_lexv2models_bot_version" "meety_bot_version" {
  bot_id      = aws_lexv2models_bot.meety_bot.id
  description = "Initial version"

  locale_specification = {
    "en_US" = {
      source_bot_version = "DRAFT"
    }
  }

  depends_on = [
    aws_lexv2models_intent.start_meety
  ]
}

# Bot alias needs to be created manually in AWS Console
# aws_lexv2models_bot_alias not supported in this provider version
