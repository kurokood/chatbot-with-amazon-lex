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
   

6. Configure fulfillment code hook:
   - Enable the fulfillment code hook
   - Select the Lambda function "generative-lex-fulfillment"

## 4. FallbackIntent Configuration

1. Go to the "FallbackIntent" intent
2. Add the following closing response:
   - "Sorry, I did not get it. I am an expert in scheduling meetings. Do you need help with that?"

## 5. Create a Bot Alias

1. Go to the "Aliases" section of your bot
2. Create a new alias named "MeetyBot" (update the alias ID in the Lambda environment variables)
3. Associate the alias with the Lambda function "generative-lex-fulfillment"

## 6. Build and Test the Bot

1. Click on "Build" to build the bot
2. Go to the "Test" section to test the bot
3. Test each intent:
   - StartMeety: Type "Hello" or "Hi"
   - MeetingAssistant: Type "I want to schedule a meeting"
   - FallbackIntent: Type something unrelated to meetings

## 7. Troubleshooting

If you encounter any issues:

1. Check the CloudWatch logs for the Lambda function
2. Ensure all slots are properly configured
3. Make sure the confirmation settings are enabled
4. Verify that the Lambda function has the correct permissions
