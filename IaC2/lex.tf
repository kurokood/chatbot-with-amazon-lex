resource "aws_lex_slot_type" "meeting_duration" {
  name        = "MeetingDuration"
  description = "Meeting Duration"

  enumeration_value {
    value = "30"
  }

  enumeration_value {
    value = "60"
  }

  value_selection_strategy = "ORIGINAL_VALUE"
}

resource "aws_lex_intent" "start_meety" {
  name = "StartMeety"
  description = "Welcome intent"

  sample_utterances = [
    "Hello",
    "Hey Meety",
    "I need your help"
  ]

  conclusion_statement {
    message {
      content = "Hey, I'm meety, the chatbot to help scheduling meetings. How can I help you?"
      content_type = "PlainText"
    }
  }

  fulfillment_activity {
    type = "ReturnIntent"
  }
}

resource "aws_lex_intent" "book_meeting" {
  name = "BookMeeting"
  description = "Book a meeting"

  sample_utterances = [
    "i want to book a meeting",
    "Can i book a slot?",
    "can you help me book a meeting?"
  ]

  slot {
    name               = "FullName"
    description        = "User Name"
    slot_type          = "AMAZON.FirstName"
    slot_constraint    = "Required"
    priority           = 1
    value_elicitation_prompt {
      message {
        content      = "What is your name?"
        content_type = "PlainText"
      }
      max_attempts = 3
    }
  }

  slot {
    name               = "MeetingDate"
    description        = "Meeting Date"
    slot_type          = "AMAZON.DATE"
    slot_constraint    = "Required"
    priority           = 2
    value_elicitation_prompt {
      message {
        content      = "When do you want to meet?"
        content_type = "PlainText"
      }
      max_attempts = 3
    }
  }

  slot {
    name               = "MeetingTime"
    description        = "Meeting Time"
    slot_type          = "AMAZON.TIME"
    slot_constraint    = "Required"
    priority           = 3
    value_elicitation_prompt {
      message {
        content      = "What time?"
        content_type = "PlainText"
      }
      max_attempts = 3
    }
  }

  slot {
    name               = "MeetingDuration"
    description        = "Meeting Duration"
    slot_type          = aws_lex_slot_type.meeting_duration.name
    slot_constraint    = "Required"
    priority           = 4
    value_elicitation_prompt {
      message {
        content      = "How long do you want to meet in minutes? (30 or 60)"
        content_type = "PlainText"
      }
      max_attempts = 3
    }
  }

  slot {
    name               = "AttendeeEmail"
    description        = "Attendee Email"
    slot_type          = "AMAZON.EmailAddress"
    slot_constraint    = "Required"
    priority           = 5
    value_elicitation_prompt {
      message {
        content      = "Please provide me your email address."
        content_type = "PlainText"
      }
      max_attempts = 3
    }
  }

  confirmation_prompt {
    message {
      content      = "Do you want to proceed with the meeting?"
      content_type = "PlainText"
    }
    max_attempts = 3
  }

  rejection_statement {
    message {
      content      = "No worries, I will cancel the request. Please let me know if you want me to restart the process!"
      content_type = "PlainText"
    }
  }

  fulfillment_activity {
    type = "CodeHook"
    code_hook {
      uri             = aws_lambda_function.lex_lambda.arn
      message_version = "1.0"
    }
  }
}

resource "aws_lex_bot" "meety_bot" {
  name                        = "MeetyBot"
  description                 = "Meety chatbot"
  idle_session_ttl_in_seconds = 300
  child_directed              = false

  intent {
    intent_name    = aws_lex_intent.start_meety.name
    intent_version = "$LATEST"
  }

  intent {
    intent_name    = aws_lex_intent.book_meeting.name
    intent_version = "$LATEST"
  }

  abort_statement {
    message {
      content      = "Sorry, I am not able to assist at this time"
      content_type = "PlainText"
    }
  }
}

resource "aws_lex_bot_alias" "meety_bot_alias" {
  bot_name    = aws_lex_bot.meety_bot.name
  name        = "TSTALIASID"
  bot_version = "$LATEST"
}
