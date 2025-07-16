# Meety - AI-Powered Meeting Management Chatbot

A sophisticated meeting management system powered by **Amazon Lex with Generative AI** and **Amazon Bedrock**, providing natural language conversation capabilities for scheduling and managing meetings.

## 🚀 Architecture Overview

This project has been refactored to use **Generative AI** instead of traditional rule-based chatbots, providing:

- **Natural Language Understanding**: Powered by Amazon Bedrock (Claude 3 models)
- **Intelligent Conversation**: Context-aware responses and dynamic slot filling
- **Flexible Intent Recognition**: Handles varied user expressions naturally
- **Smart Information Extraction**: AI-powered parsing of meeting details from natural language

## 🏗️ Infrastructure Components

### **Frontend**

- **S3 + CloudFront**: Static website hosting with custom SSL certificate
- **Custom Domain**: `chatbot.monvillarin.com` with ACM certificate
- **Origin Access Control (OAC)**: Modern security for S3 access

### **Backend Services**

- **Amazon Lex v2**: Generative AI-enabled chatbot with Bedrock integration
- **Amazon Bedrock**: Claude 3 models for natural language processing
- **API Gateway v2**: HTTP API with JWT authentication
- **AWS Lambda**: Serverless compute with Python 3.12
- **Amazon DynamoDB**: Meeting data storage with GSI
- **Amazon Cognito**: User authentication and authorization

### **AI Models Used**

- **Claude 3 Sonnet**: Advanced reasoning for complex conversations
- **Claude 3 Haiku**: Fast responses for slot resolution and utterance generation

## 📁 Project Structure

```
├── IaC/                          # Infrastructure as Code
│   ├── lex-generative.tf         # Generative AI Lex Bot configuration
│   ├── lambda-generative.tf      # Enhanced Lambda functions
│   ├── apigateway.tf             # API Gateway with generative chatbot route
│   ├── s3-cloudfront.tf          # Frontend hosting with OAC
│   ├── cognito.tf                # User authentication
│   ├── dynamodb.tf               # Meeting data storage
│   ├── variables.tf              # Configuration variables
│   ├── outputs.tf                # Infrastructure outputs
│   ├── versions.tf               # Provider versions
│   └── lambda/                   # Lambda function source code
│       ├── generative_lex.py     # Lex fulfillment with AI
│       ├── generative_chatbot.py # API Gateway chatbot handler
│       ├── generative_lex.zip    # Deployment package
│       └── generative_chatbot.zip # Deployment package
├── frontend/                     # Static web frontend
└── README.md                     # This file
```

## 🤖 Generative AI Features

### **Enhanced Conversation Capabilities**

- **Natural Language Processing**: Understands varied expressions for the same intent
- **Context Awareness**: Maintains conversation context across multiple turns
- **Dynamic Slot Filling**: Intelligently extracts meeting details from natural language
- **Flexible Responses**: AI-generated responses tailored to user context

### **Smart Meeting Management**

- **Intelligent Scheduling**: Understands complex scheduling requests
- **Conflict Detection**: Automatically checks for scheduling conflicts
- **Natural Queries**: Handle requests like "Can we meet next Tuesday afternoon?"
- **Context Preservation**: Remembers partial information across conversation turns

### **AI-Powered Features**

- **Utterance Generation**: Automatically generates training examples
- **Slot Resolution**: Improves understanding of user inputs
- **Descriptive Bot Building**: AI assists in bot configuration

## 🛠️ Deployment Instructions

### **Prerequisites**

1. **AWS CLI** configured with appropriate permissions
2. **Terraform** >= 1.0 installed
3. **Amazon Bedrock** access enabled in your AWS account
4. **Claude 3 models** access granted in Bedrock console

### **Required AWS Permissions**

- Lex v2 full access
- Bedrock model invocation
- Lambda execution
- DynamoDB access
- S3 and CloudFront management
- API Gateway management
- Cognito administration

### **Deployment Steps**

1. **Clone and Navigate**

   ```bash
   git clone <repository-url>
   cd chatbot-with-amazon-lex/IaC
   ```

2. **Configure Variables**

   ```bash
   # Set required variables
   export TF_VAR_username="your-username"
   export TF_VAR_user_email="your-email@example.com"
   ```

3. **Initialize and Deploy**

   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

4. **Enable Bedrock Models**

   - Go to AWS Bedrock Console
   - Enable Claude 3 Sonnet and Haiku models
   - Ensure model access is granted

5. **Configure DNS** (Optional)
   - Point `chatbot.monvillarin.com` to the CloudFront distribution
   - Or use the CloudFront URL directly

## 🔧 Configuration

### **Environment Variables**

The Lambda functions use these environment variables:

- `BEDROCK_MODEL_ID`: Claude model identifier
- `DYNAMODB_TABLE`: Meeting storage table name
- `BOT_ID`: Lex bot identifier
- `BOT_ALIAS_ID`: Bot alias for production

### **Bedrock Models**

- **Primary Model**: `anthropic.claude-3-haiku-20240307-v1:0`
- **Advanced Model**: `anthropic.claude-3-sonnet-20240229-v1:0`
- **Region**: `us-east-1`

## 🎯 API Endpoints

### **Chatbot API**

```
POST /chatbot
Content-Type: application/json

{
  "message": "I want to schedule a meeting for tomorrow at 2 PM",
  "sessionId": "optional-session-id"
}
```

### **Meeting Management**

- `GET /meetings` - List scheduled meetings
- `GET /pending` - List pending meetings
- `PUT /status` - Update meeting status

## 💬 Conversation Examples

### **Natural Scheduling**

```
User: "Can we set up a meeting with John next Tuesday at 2 PM for an hour?"
Bot: "Perfect! I'll schedule a meeting with John for next Tuesday at 2:00 PM - 3:00 PM.
      What's John's email address?"
```

### **Flexible Queries**

```
User: "What meetings do I have this week?"
Bot: "Here are your meetings for this week:
      📅 Tuesday, Jan 16th
      🕐 2:00 PM - 3:00 PM
      👤 John Smith
      📋 Status: Confirmed"
```

### **Context Awareness**

```
User: "I need to meet with Sarah"
Bot: "I'd be happy to help schedule a meeting with Sarah. When would you like to meet?"
User: "Tomorrow afternoon"
Bot: "What time tomorrow afternoon works best for you?"
```

## 🔒 Security Features

- **JWT Authentication**: Cognito-based user authentication
- **Origin Access Control**: Modern S3 security with CloudFront
- **IAM Least Privilege**: Minimal required permissions for each service
- **HTTPS Enforcement**: SSL/TLS encryption with custom certificate
- **CORS Configuration**: Proper cross-origin resource sharing

## 📊 Monitoring and Logging

- **CloudWatch Logs**: Lambda function execution logs
- **Lex Analytics**: Conversation analytics and metrics
- **API Gateway Metrics**: Request/response monitoring
- **DynamoDB Metrics**: Database performance monitoring

## 🚀 Key Improvements Over Traditional Lex

### **Before (Traditional Lex)**

- Fixed slot types and utterances
- Rigid conversation flow
- Manual slot configuration required
- Limited natural language understanding

### **After (Generative AI Lex)**

- ✅ Dynamic utterance generation
- ✅ Flexible conversation handling
- ✅ AI-powered slot resolution
- ✅ Natural language understanding
- ✅ Context-aware responses
- ✅ Reduced manual configuration

## 🔄 Migration Notes

This refactored version:

- Replaces `lex.tf` with `lex-generative.tf`
- Adds `lambda-generative.tf` for enhanced Lambda functions
- Updates API Gateway to use generative chatbot endpoint
- Maintains backward compatibility with existing meeting data
- Preserves all existing API endpoints

## 📝 Development Notes

### **Adding New Intents**

1. Add intent to `lex-generative.tf`
2. Update Lambda fulfillment logic
3. Test with various natural language expressions

### **Customizing AI Behavior**

- Modify prompts in `generative_lex.py`
- Adjust Bedrock model parameters
- Update conversation flow logic

### **Scaling Considerations**

- Lambda concurrent execution limits
- Bedrock API rate limits
- DynamoDB read/write capacity
- Lex conversation limits

## 🆘 Troubleshooting

### **Common Issues**

1. **Bedrock Access Denied**: Ensure models are enabled in Bedrock console
2. **Lambda Timeout**: Increase timeout for complex AI operations
3. **CORS Errors**: Check API Gateway CORS configuration
4. **Bot Not Responding**: Verify bot alias and Lambda permissions

### **Debugging**

- Check CloudWatch logs for Lambda functions
- Monitor Lex conversation logs
- Verify IAM permissions for Bedrock access
- Test API endpoints individually

## 🎉 Getting Started

1. Deploy the infrastructure using Terraform
2. Access the chatbot at `Your custom domain or Cloudfront distribution url`
3. Start a conversation: "Hello, I need to schedule a meeting"
4. Experience natural language meeting management!
