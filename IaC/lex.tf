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
  name        = "MeetyBot"
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

resource "aws_lexv2models_slot_type" "meeting_duration" {
  bot_id      = aws_lexv2models_bot.meety_bot.id
  bot_version = "DRAFT"
  locale_id   = "en_US"
  name        = "MeetingDuration"
  description = "Meeting Duration"
  
  slot_type_values {
    sample_value {
      value = "30"
    }
  }
  
  slot_type_values {
    sample_value {
      value = "60"
    }
  }
  
  depends_on = [aws_lexv2models_bot_locale.meety_bot_locale]
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

resource "aws_lexv2models_intent" "book_meeting" {
  bot_id      = aws_lexv2models_bot.meety_bot.id
  bot_version = "DRAFT"
  locale_id   = aws_lexv2models_bot_locale.meety_bot_locale.locale_id
  name        = "BookMeeting"
  description = "Book a meeting"

  sample_utterance {
    utterance = "i want to book a meeting"
  }
  sample_utterance {
    utterance = "Can i book a slot?"
  }
  sample_utterance {
    utterance = "can you help me book a meeting?"
  }
}

resource "aws_lexv2models_slot" "full_name" {
  bot_id       = aws_lexv2models_bot.meety_bot.id
  bot_version  = "DRAFT"
  locale_id    = aws_lexv2models_bot_locale.meety_bot_locale.locale_id
  intent_id    = aws_lexv2models_intent.book_meeting.intent_id
  name         = "FullName"
  description  = "User Name"
  slot_type_id = "AMAZON.FirstName"
  
  value_elicitation_setting {
    slot_constraint = "Required"
    prompt_specification {
      message_group {
        message {
          plain_text_message {
            value = "What is your name?"
          }
        }
      }
      max_retries = 3
    }
  }
}

resource "aws_lexv2models_slot" "meeting_date" {
  bot_id       = aws_lexv2models_bot.meety_bot.id
  bot_version  = "DRAFT"
  locale_id    = aws_lexv2models_bot_locale.meety_bot_locale.locale_id
  intent_id    = aws_lexv2models_intent.book_meeting.intent_id
  name         = "MeetingDate"
  description  = "Meeting Date"
  slot_type_id = "AMAZON.Date"
  
  value_elicitation_setting {
    slot_constraint = "Required"
    prompt_specification {
      message_group {
        message {
          plain_text_message {
            value = "When do you want to meet?"
          }
        }
      }
      max_retries = 3
    }
  }
}

resource "aws_lexv2models_slot" "meeting_time" {
  bot_id       = aws_lexv2models_bot.meety_bot.id
  bot_version  = "DRAFT"
  locale_id    = aws_lexv2models_bot_locale.meety_bot_locale.locale_id
  intent_id    = aws_lexv2models_intent.book_meeting.intent_id
  name         = "MeetingTime"
  description  = "Meeting Time"
  slot_type_id = "AMAZON.Time"
  
  value_elicitation_setting {
    slot_constraint = "Required"
    prompt_specification {
      message_group {
        message {
          plain_text_message {
            value = "What time?"
          }
        }
      }
      max_retries = 3
    }
  }
}

resource "aws_lexv2models_slot" "meeting_duration" {
  bot_id       = aws_lexv2models_bot.meety_bot.id
  bot_version  = "DRAFT"
  locale_id    = aws_lexv2models_bot_locale.meety_bot_locale.locale_id
  intent_id    = aws_lexv2models_intent.book_meeting.intent_id
  name         = "MeetingDuration"
  description  = "Meeting Duration"
  slot_type_id = aws_lexv2models_slot_type.meeting_duration.slot_type_id
  
  value_elicitation_setting {
    slot_constraint = "Required"
    prompt_specification {
      message_group {
        message {
          plain_text_message {
            value = "How long do you want to meet in minutes? (30 or 60)"
          }
        }
      }
      max_retries = 3
    }
  }
}

resource "aws_lexv2models_slot" "attendee_email" {
  bot_id       = aws_lexv2models_bot.meety_bot.id
  bot_version  = "DRAFT"
  locale_id    = aws_lexv2models_bot_locale.meety_bot_locale.locale_id
  intent_id    = aws_lexv2models_intent.book_meeting.intent_id
  name         = "AttendeeEmail"
  description  = "Attendee Email"
  slot_type_id = "AMAZON.EmailAddress"
  
  value_elicitation_setting {
    slot_constraint = "Required"
    prompt_specification {
      message_group {
        message {
          plain_text_message {
            value = "Please provide me your email address."
          }
        }
      }
      max_retries = 3
    }
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
    aws_lexv2models_intent.start_meety,
    aws_lexv2models_intent.book_meeting,
    aws_lexv2models_slot.full_name,
    aws_lexv2models_slot.meeting_date,
    aws_lexv2models_slot.meeting_time,
    aws_lexv2models_slot.meeting_duration,
    aws_lexv2models_slot.attendee_email
  ]
}

resource "aws_lex_bot_alias" "meety_bot_alias" {
  name        = "TSTALIASID"
  bot_name    = aws_lexv2models_bot.meety_bot.name
  bot_version = aws_lexv2models_bot_version.meety_bot_version.bot_version
  description = "Test alias"
}
