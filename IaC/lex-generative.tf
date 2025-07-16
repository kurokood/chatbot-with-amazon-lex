# Lex Generative AI Bot Configuration with Amazon Bedrock Integration

# IAM Role for Lex Bot with Bedrock permissions
resource "aws_iam_role" "lex_generative_bot_role" {
  name = "LexGenerativeBotRole"

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

# IAM Policy for Bedrock access
resource "aws_iam_role_policy" "lex_bedrock_policy" {
  name = "LexBedrockPolicy"
  role = aws_iam_role.lex_generative_bot_role.id

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
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Lex Bot with Generative AI capabilities
resource "aws_lexv2models_bot" "meety_generative_bot" {
  name        = "MeetyGenerativeBot"
  description = "Meety chatbot with Generative AI powered by Amazon Bedrock"
  role_arn    = aws_iam_role.lex_generative_bot_role.arn

  data_privacy {
    child_directed = false
  }

  idle_session_ttl_in_seconds = 300

  # Enable generative AI features
  test_bot_alias_tags = {
    Environment = "development"
    BotType     = "generative"
  }
}

# Bot Locale with Generative AI configuration
resource "aws_lexv2models_bot_locale" "meety_generative_locale" {
  bot_id                           = aws_lexv2models_bot.meety_generative_bot.id
  bot_version                      = "DRAFT"
  locale_id                        = "en_US"
  description                      = "Generative AI enabled locale for meeting management"
  n_lu_intent_confidence_threshold = 0.40

  # Note: Generative AI settings need to be configured manually in AWS Console
  # The current Terraform AWS provider doesn't support generative_ai_settings block
}

# Meeting Management Intent with Generative AI
resource "aws_lexv2models_intent" "meeting_management" {
  bot_id      = aws_lexv2models_bot.meety_generative_bot.id
  bot_version = "DRAFT"
  locale_id   = aws_lexv2models_bot_locale.meety_generative_locale.locale_id
  name        = "MeetingManagement"
  description = "Comprehensive meeting management with natural language understanding"

  # Sample utterances - Generative AI will expand these automatically
  sample_utterance {
    utterance = "I want to schedule a meeting"
  }
  sample_utterance {
    utterance = "Book a meeting for me"
  }
  sample_utterance {
    utterance = "Can you help me set up a meeting"
  }
  sample_utterance {
    utterance = "Schedule a call"
  }
  sample_utterance {
    utterance = "I need to arrange a meeting"
  }

  # Enable fulfillment with Lambda
  fulfillment_code_hook {
    enabled = true
  }
}

# Welcome Intent for initial greetings
resource "aws_lexv2models_intent" "welcome_intent" {
  bot_id      = aws_lexv2models_bot.meety_generative_bot.id
  bot_version = "DRAFT"
  locale_id   = aws_lexv2models_bot_locale.meety_generative_locale.locale_id
  name        = "WelcomeIntent"
  description = "Welcome users and introduce capabilities"

  sample_utterance {
    utterance = "Hello"
  }
  sample_utterance {
    utterance = "Hi"
  }
  sample_utterance {
    utterance = "Hey"
  }
  sample_utterance {
    utterance = "Good morning"
  }
  sample_utterance {
    utterance = "Help"
  }
}

# Bot Version for deployment
resource "aws_lexv2models_bot_version" "meety_generative_version" {
  bot_id      = aws_lexv2models_bot.meety_generative_bot.id
  description = "Generative AI enabled version"

  locale_specification = {
    "en_US" = {
      source_bot_version = "DRAFT"
    }
  }

  depends_on = [
    aws_lexv2models_intent.meeting_management,
    aws_lexv2models_intent.welcome_intent,
    aws_lexv2models_bot_locale.meety_generative_locale
  ]
}

# Bot alias needs to be created manually in AWS Console
# aws_lexv2models_bot_alias not supported in current provider version
