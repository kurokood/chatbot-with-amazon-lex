# Manual Intent Configuration for Lex Bot

After deploying the infrastructure with Terraform, you need to manually configure the following settings for each intent in the AWS Console:

## 1. StartMeety Intent Configuration

1. Go to the AWS Console and navigate to Amazon Lex
2. Select the "MeetyGenerativeBot" bot
3. Go to the "Intents" section and select the "StartMeety" intent
4. Add the following closing response:
   - "Hey, I'm meety, the chatbot to help scheduling meetings. How can I help you?"
   - "Hello, how may I assist you?"
   - "Hello, how can I help you?"

## 2. MeetingAssistant Intent Configuration

1. Go to the "MeetingAssistant" intent
2. Add the following initial response:
   - "Sure"

3. Add the following slots:
   a. **attendeeName**
      - Slot type: AMAZON.FirstName
      - Prompt: "What is your name?"
      - Required: Yes

   b. **date**
      - Slot type: AMAZON.Date
      - Prompt: "What date would you like to schedule the meeting for?"
      - Required: Yes

   c. **time**
      - Slot type: AMAZON.Time
      - Prompt: "What time would you prefer for the meeting?"
      - Required: Yes

   d. **meetingTitle**
      - Slot type: AMAZON.AlphaNumeric
      - Prompt: "What should I call this meeting or what's it regarding?"
      - Required: Yes

4. Configure confirmation settings:
   - Enable confirmation
   - Set the confirmation prompt to: "I'll schedule a meeting on {date} at {time} with {attendeeName} regarding {meetingTitle}. Is that correct?"
   - Set the confirmation response to: "I've scheduled your meeting. Is there anything else I can help you with?"
   - Set the decline response to: "I've cancelled the meeting request."

5. Configure dialog code hook:
   - Enable the dialog code hook
   - Select the Lambda function "generative-lex-fulfillment"

6. Configure fulfillment code hook:
   - Enable the fulfillment code hook
   - Select the Lambda function "generative-lex-fulfillment"

## 3. CustomFallbackIntent Configuration

1. Go to the "CustomFallbackIntent" intent
2. Add the following closing response:
   - "Sorry, I did not get it. I am an expert in scheduling meetings. Do you need help with that?"

## 4. Built-in AMAZON.FallbackIntent Configuration

1. Enable the built-in AMAZON.FallbackIntent in your bot
2. Configure it to redirect to your CustomFallbackIntent

## 5. Build and Test the Bot

1. Click on "Build" to build the bot
2. Go to the "Test" section to test the bot
3. Test each intent:
   - StartMeety: Type "Hello" or "Hi"
   - MeetingAssistant: Type "I want to schedule a meeting"
   - CustomFallbackIntent: Type something unrelated to meetings

## 6. Troubleshooting

If you encounter any issues:

1. Check the CloudWatch logs for the Lambda function
2. Ensure all slots are properly configured
3. Make sure the confirmation settings are enabled
4. Verify that the Lambda function has the correct permissions