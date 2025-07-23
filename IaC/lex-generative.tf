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

# StartMeety Intent - For greeting and starting conversations
resource "aws_lexv2models_intent" "start_meety" {
  bot_id      = aws_lexv2models_bot.meety_generative_bot.id
  bot_version = "DRAFT"
  locale_id   = aws_lexv2models_bot_locale.meety_generative_locale.locale_id
  name        = "StartMeety"
  description = "Intent for greeting and starting conversations"

  # Sample utterances for greetings
  sample_utterance {
    utterance = "Hello"
  }
  sample_utterance {
    utterance = "Hi"
  }
  sample_utterance {
    utterance = "Hey Meety"
  }
  sample_utterance {
    utterance = "help"
  }
}

# Meeting Assistant Intent - For scheduling meetings
resource "aws_lexv2models_intent" "meeting_assistant" {
  bot_id      = aws_lexv2models_bot.meety_generative_bot.id
  bot_version = "DRAFT"
  locale_id   = aws_lexv2models_bot_locale.meety_generative_locale.locale_id
  name        = "MeetingAssistant"
  description = "Intent for scheduling meetings"

  # Sample utterances for scheduling meetings
  sample_utterance {
    utterance = "I want to schedule a meeting"
  }
  sample_utterance {
    utterance = "Book a meeting"
  }
  sample_utterance {
    utterance = "Schedule a meeting"
  }
  sample_utterance {
    utterance = "Set up a meeting"
  }
  sample_utterance {
    utterance = "Create a meeting"
  }
  sample_utterance {
    utterance = "I need to schedule a meeting"
  }
  sample_utterance {
    utterance = "Help me book a meeting"
  }

  # Enable fulfillment with Lambda
  fulfillment_code_hook {
    enabled = true
  }

  # Note: Slots and confirmation settings need to be configured manually in AWS Console
  # The current Terraform AWS provider doesn't support these blocks directly
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
    aws_lexv2models_intent.start_meety,
    aws_lexv2models_intent.meeting_assistant,
    aws_lexv2models_bot_locale.meety_generative_locale
  ]
}

# Bot alias needs to be created manually in AWS Console
# The AWS provider doesn't support the aws_lexv2models_bot_alias resource type
# Steps to create the bot alias:
# 1. Go to the AWS Console > Amazon Lex > Bots > MeetyGenerativeBot
# 2. Go to Aliases tab and create a new alias named "prod"
# 3. Associate it with the version created by Terraform
# 4. Enable the generative AI features in the console
