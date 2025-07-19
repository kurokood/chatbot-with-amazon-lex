# Manual Configuration Steps for Lex Bot

After deploying the infrastructure with Terraform, you need to manually configure the following settings in the AWS Console:

## 1. Configure Slots in the Lex Bot

1. Go to the AWS Console and navigate to Amazon Lex
2. Select the "MeetyGenerativeBot" bot
3. Go to the "Intents" section and select the "MeetingAssistant" intent
4. Add the following slots:

   a. **date**
      - Slot type: AMAZON.Date
      - Prompt: "What date would you like to schedule the meeting for?"
      - Required: Yes

   b. **time**
      - Slot type: AMAZON.Time
      - Prompt: "What time would you prefer for the meeting?"
      - Required: Yes

   c. **attendeeName**
      - Slot type: AMAZON.Person
      - Prompt: "Who will you be meeting with?"
      - Required: Yes

   d. **meetingTitle**
      - Slot type: AMAZON.AlphaNumeric
      - Prompt: "What should I call this meeting or what's it regarding?"
      - Required: Yes

## 2. Configure Confirmation Settings

1. In the same intent, scroll down to "Confirmation"
2. Enable confirmation
3. Set the confirmation prompt to: "I'll schedule a meeting on {date} at {time} with {attendeeName} regarding {meetingTitle}. Is that correct?"
4. Set the confirmation response to: "I've scheduled your meeting. Is there anything else I can help you with?"
5. Set the decline response to: "I've cancelled the meeting request."

## 3. Configure Dialog Code Hook

1. In the same intent, scroll down to "Dialog code hook"
2. Enable the dialog code hook
3. Select the Lambda function "generative-lex-fulfillment"

## 4. Configure Fulfillment Code Hook

1. In the same intent, scroll down to "Fulfillment"
2. Enable the fulfillment code hook
3. Select the Lambda function "generative-lex-fulfillment"

## 5. Create a Bot Alias

1. Go to the "Aliases" section of your bot
2. Create a new alias named "TSTALIASID" (or update the alias ID in the Lambda environment variables)
3. Associate the alias with the Lambda function "generative-lex-fulfillment"

## 6. Build and Test the Bot

1. Click on "Build" to build the bot
2. Go to the "Test" section to test the bot
3. Type "I want to schedule a meeting" and follow the prompts

## Troubleshooting

If you encounter any issues:

1. Check the CloudWatch logs for the Lambda function
2. Ensure all slots are properly configured
3. Make sure the confirmation settings are enabled
4. Verify that the Lambda function has the correct permissions