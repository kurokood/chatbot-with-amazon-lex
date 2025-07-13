resource "aws_iam_role" "meety_runtime_role" {
  name = "MeetyRuntimeRole"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "lexv2.amazonaws.com"
        }
      },
    ]
  })

  inline_policy {
    name = "LexRuntimeRolePolicy"
    policy = jsonencode({
      Version   = "2012-10-17"
      Statement = [
        {
          Action   = ["polly:SynthesizeSpeech", "comprehend:DetectSentiment"]
          Effect   = "Allow"
          Resource = "*"
        },
      ]
    })
  }
}

resource "aws_lex_bot" "meety_bot" {
  name                              = "MeetyBot"
  description                       = "Meety chatbot"
  role_arn                          = aws_iam_role.meety_runtime_role.arn
  data_privacy                      = {
    child_directed = false
  }
  idle_session_ttl_in_seconds       = 300
  auto_build_bot_locales            = false

  bot_locale {
    locale_id = "en_US"
    description = "Meety"
    nlu_confidence_threshold = 0.60
    voice_settings {
      voice_id = "Ivy"
    }

    slot_type {
      name = "MeetingDuration"
      description = "Meeting Duration"
      slot_type_values {
        sample_value {
          value = "30"
        }
        sample_value {
          value = "60"
        }
      }
      value_selection_setting {
        resolution_strategy = "ORIGINAL_VALUE"
      }
    }

    intent {
      name = "StartMeety"
      description = "Welcome intent"
      sample_utterances {
        utterance = "Hello"
      }
      sample_utterances {
        utterance = "Hey Meety"
      }
      sample_utterances {
        utterance = "I need your help"
      }
      intent_closing_setting {
        is_active = true
        closing_response {
          message_groups {
            message {
              plain_text_message {
                value = "Hey, I'm meety, the chatbot to help scheduling meetings. How can I help you?"
              }
            }
          }
        }
      }
    }

    intent {
      name = "BookMeeting"
      description = "Book a meeting"
      sample_utterances {
        utterance = "i want to book a meeting"
      }
      sample_utterances {
        utterance = "Can i book a slot?"
      }
      sample_utterances {
        utterance = "can you help me book a meeting?"
      }
      slot_priority {
        priority = 1
        slot_name = "FullName"
      }
      slot_priority {
        priority = 2
        slot_name = "MeetingDate"
      }
      slot_priority {
        priority = 3
        slot_name = "MeetingTime"
      }
      slot_priority {
        priority = 4
        slot_name = "MeetingDuration"
      }
      slot_priority {
        priority = 5
        slot_name = "AttendeeEmail"
      }
      intent_confirmation_setting {
        prompt_specification {
          message_groups {
            message {
              plain_text_message {
                value = "Do you want to proceed with the meeting?"
              }
            }
          }
          max_retries = 3
          allow_interrupt = true
        }
        declination_response {
          message_groups {
            message {
              plain_text_message {
                value = "No worries, I will cancel the request. Please let me know if you want me to restart the process!"
              }
            }
          }
          allow_interrupt = false
        }
      }
      slot {
        name = "FullName"
        description = "User Name"
        slot_type_name = "AMAZON.FirstName"
        value_elicitation_setting {
          slot_constraint = "Required"
          prompt_specification {
            message_groups {
              message {
                plain_text_message {
                  value = "What is your name?"
                }
              }
            }
            max_retries = 3
            allow_interrupt = false
          }
        }
      }
      slot {
        name = "MeetingDate"
        description = "Meeting Date"
        slot_type_name = "AMAZON.Date"
        value_elicitation_setting {
          slot_constraint = "Required"
          prompt_specification {
            message_groups {
              message {
                plain_text_message {
                  value = "When do you want to meet?"
                }
              }
            }
            max_retries = 3
            allow_interrupt = false
          }
        }
      }
      slot {
        name = "MeetingTime"
        description = "Meeting Time"
        slot_type_name = "AMAZON.Time"
        value_elicitation_setting {
          slot_constraint = "Required"
          prompt_specification {
            message_groups {
              message {
                plain_text_message {
                  value = "What time?"
                }
              }
            }
            max_retries = 3
            allow_interrupt = false
          }
        }
      }
      slot {
        name = "MeetingDuration"
        description = "Meeting Duration"
        slot_type_name = "MeetingDuration"
        value_elicitation_setting {
          slot_constraint = "Required"
          prompt_specification {
            message_groups {
              message {
                plain_text_message {
                  value = "How long do you want to meet in minutes? (30 or 60)"
                }
              }
            }
            max_retries = 3
            allow_interrupt = false
          }
        }
      }
      slot {
        name = "AttendeeEmail"
        description = "Attendee Email"
        slot_type_name = "AMAZON.EmailAddress"
        value_elicitation_setting {
          slot_constraint = "Required"
          prompt_specification {
            message_groups {
              message {
                plain_text_message {
                  value = "Please provide me your email address."
                }
              }
            }
            max_retries = 3
            allow_interrupt = false
          }
        }
      }
    }

    intent {
      name = "FallbackIntent"
      description = "Default intent when no other intent matches"
      parent_intent_signature = "AMAZON.FallbackIntent"
      intent_closing_setting {
        is_active = true
        closing_response {
          message_groups {
            message {
              plain_text_message {
                value = "Sorry, i did not get it. I am an expert in scheduling meetings. Do you need help with that?"
              }
            }
          }
        }
      }
    }
  }
}
