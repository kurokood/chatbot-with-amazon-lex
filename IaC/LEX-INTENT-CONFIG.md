# Lex Intent Configuration

This document describes the configuration of the Lex intents, slots, and responses for the Meety chatbot.

## Automated Configuration

The `configure-lex-intents.ps1` script automates the configuration of the Lex intents, slots, and responses. It uses the AWS CLI to interact with the Lex V2 API.

## Intent Configuration

### StartMeety Intent

The StartMeety intent is used for greeting and starting conversations.

#### Sample Utterances
- "Hello"
- "Hi"
- "Hey Meety"
- "help"

#### Closing Responses
- "Hey, I'm meety, the chatbot to help scheduling meetings. How can I help you?"
- "Hello, how may I assist you?"
- "Hi, how can I help you?"

### MeetingAssistant Intent

The MeetingAssistant intent is used for scheduling meetings.

#### Sample Utterances
- "I want to schedule a meeting"
- "Book a meeting"
- "Schedule a meeting"
- "Set up a meeting"
- "Create a meeting"
- "I need to schedule a meeting"
- "Help me book a meeting"

#### Initial Response
- "Sure!"

#### Slots

| Slot Name | Slot Type | Prompt | Required |
|-----------|-----------|--------|----------|
| FullName | AMAZON.FirstName | "What is your name?" | Yes |
| MeetingDate | AMAZON.Date | "What date would you like to schedule the meeting for?" | Yes |
| MeetingTime | AMAZON.Time | "What time would you prefer for the meeting?" | Yes |
| MeetingDuration | AMAZON.Duration | "How long do you want to meet in minutes? (30 or 60)" | Yes |
| AttendeeEmail | AMAZON.EmailAddress | "Please provide me your email address." | Yes |
| confirm | AMAZON.Confirmation | "Do you want to proceed with the meeting?" | Yes |

#### Fulfillment
- Fulfillment code hook is enabled
- Lambda function: "generative-lex-fulfillment"

### FallbackIntent

The FallbackIntent is used when the user's input doesn't match any other intent.

#### Closing Response
- "Sorry, I did not get it. Could you try again?"

## Manual Configuration

If you prefer to configure the Lex intents manually, follow these steps:

### 1. StartMeety Intent Configuration
1. Go to the AWS Console and navigate to Amazon Lex
2. Select the "MeetyGenerativeBot" bot
3. Go to the "Intents" section and select the "StartMeety" intent
4. Add the following closing response:
   - "Hey, I'm meety, the chatbot to help scheduling meetings. How can I help you?"
   - "Hello, how may I assist you?"
   - "Hi, how can I help you?"

### 2. MeetingAssistant Intent Configuration
1. Go to the "MeetingAssistant" intent
2. Add the following initial response:
   - "Sure!"
3. Add the following slots:
   a. **FullName**
   - Slot type: AMAZON.FirstName
   - Prompt: "What is your name?"
   - Required: Yes
   b. **MeetingDate**
   - Slot type: AMAZON.Date
   - Prompt: "What date would you like to schedule the meeting for?"
   - Required: Yes
   c. **MeetingTime**
   - Slot type: AMAZON.Time
   - Prompt: "What time would you prefer for the meeting?"
   - Required: Yes
   d. **MeetingDuration**
   - Slot type: AMAZON.Duration
   - Prompt: "How long do you want to meet in minutes? (30 or 60)"
   - Required: Yes
   e. **AttendeeEmail**
   - Slot type: AMAZON.EmailAddress
   - Prompt: "Please provide me your email address."
   - Required: Yes
   f. **confirm**
   - Slot type: AMAZON.Confirmation
   - Prompt: "Do you want to proceed with the meeting?"
   - Required: Yes
4. Configure fulfillment code hook:
   - Enable the fulfillment code hook
   - Select the Lambda function "generative-lex-fulfillment"

### 3. FallbackIntent Configuration
1. Go to the "FallbackIntent" intent
2. Add the following closing response:
   - "Sorry, I did not get it. Could you try again?"
   - "Apologies, but I'm not quite sure what you're referring to."