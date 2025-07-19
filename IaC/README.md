# Meety Chatbot - Infrastructure as Code

This directory contains the Terraform configuration for deploying the Meety chatbot infrastructure.

## Deployment Instructions

1. Initialize Terraform:
   ```
   terraform init
   ```

2. Apply the configuration:
   ```
   terraform apply
   ```

3. After deployment, you'll need to manually configure the following in the AWS Console:

### Manual Configuration Steps

#### 1. Configure Slots in the Lex Bot

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

#### 2. Configure Confirmation Settings

1. In the same intent, scroll down to "Confirmation"
2. Enable confirmation
3. Set the confirmation prompt to: "I'll schedule a meeting on {date} at {time} with {attendeeName} regarding {meetingTitle}. Is that correct?"
4. Set the confirmation response to: "I've scheduled your meeting. Is there anything else I can help you with?"
5. Set the decline response to: "I've cancelled the meeting request."

#### 3. Create a Bot Alias

1. Go to the "Aliases" section of your bot
2. Create a new alias named "TSTALIASID" (or update the alias ID in the Lambda environment variables)
3. Associate the alias with the Lambda function "generative-lex-fulfillment"

## Testing the Bot

After completing the manual configuration steps, you can test the bot in the AWS Console:

1. Go to the "Test" section of your bot
2. Type "I want to schedule a meeting"
3. Follow the prompts to provide the date, time, attendee name, and meeting title
4. Confirm the meeting when prompted

The meeting will be saved to the DynamoDB table.