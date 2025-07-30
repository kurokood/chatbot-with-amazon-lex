# Meety - AI-powered Meeting Management Chatbot

Meety is a comprehensive meeting management application that combines conversational AI with a web-based admin interface. Users can schedule meetings through natural language interactions with an AI chatbot powered by Amazon Lex V2, while administrators can manage meetings through a dedicated web interface.

## 🚀 Features

- **AI Chatbot Interface**: Schedule meetings using natural language with Amazon Lex V2
- **Admin Dashboard**: Web-based interface for managing meetings and users
- **Real-time Updates**: View pending meetings and update their status
- **User Authentication**: Secure login system with Amazon Cognito
- **Responsive Design**: Works on desktop and mobile devices
- **Direct Lex Integration**: Optimized architecture with direct frontend-to-Lex communication

## 🏗️ Architecture

The application uses a modern serverless architecture with the following AWS services:

- **Amazon Cognito**: User authentication and authorization with Identity Pool
- **Amazon Lex V2**: Conversational AI chatbot with slot-based conversation flow
- **Amazon DynamoDB**: NoSQL database for meeting data storage
- **Amazon S3 + CloudFront**: Static website hosting with global CDN
- **Amazon API Gateway**: HTTP API for backend services (admin functions)
- **AWS Lambda**: Serverless compute for backend logic
- **Amazon Route53**: DNS management for custom domain

### System Overview
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│                 │    │                 │    │                 │
│   Frontend      │    │   Amazon        │    │   Amazon        │
│   (HTML/JS)     │◄──►│   Cognito       │◄──►│   Lex V2        │
│                 │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────┬───────┘
         │                       │                      │
         │                       │                      ▼
         ▼                       ▼              ┌─────────────────┐
┌─────────────────┐    ┌─────────────────┐    │                 │
│                 │    │                 │    │   AWS Lambda    │
│   CloudFront    │    │   API Gateway   │    │   (Fulfillment) │
│   + S3          │    │   + Lambda      │    │                 │
│                 │    │                 │    └─────────┬───────┘
└─────────────────┘    └─────────────────┘              │
                                │                       ▼
                                ▼               ┌─────────────────┐
                       ┌─────────────────┐     │                 │
                       │                 │     │   Amazon        │
                       │   DynamoDB      │◄────│   DynamoDB      │
                       │                 │     │                 │
                       └─────────────────┘     └─────────────────┘
```

### Key Architectural Decisions

**1. Direct Lex Integration**
- Frontend communicates directly with Amazon Lex V2 using AWS SDK
- Eliminates API Gateway overhead for chatbot interactions
- Reduces latency and simplifies the conversation flow

**2. Dual Authentication Model**
- **Anonymous Access**: Anyone can use the chatbot (Cognito Identity Pool unauthenticated role)
- **Authenticated Access**: Admin users get additional permissions for meeting management

**3. Serverless Backend**
- All backend logic runs on AWS Lambda
- Auto-scaling and pay-per-use pricing model
- No server management required

**4. Static Frontend with CDN**
- Frontend hosted on S3 with CloudFront distribution
- Global content delivery for optimal performance
- Custom domain with SSL certificate

## 📁 Project Structure

```
├── .github/                 # GitHub workflows and CI/CD
├── .kiro/                   # Kiro AI assistant configuration
├── frontend/                # Static web frontend
│   ├── assets/              # Compiled JavaScript, CSS, and images
│   └── index.html           # Main HTML entry point
├── IaC/                     # Infrastructure as Code (Terraform)
│   ├── lambda/              # Lambda function source code and packages
│   ├── *.tf                 # Terraform configuration files
│   └── terraform.tfvars.example # Template for environment variables
├── *.ps1                    # PowerShell deployment and utility scripts
└── README.md                # This comprehensive guide
```

## 📋 Prerequisites

### 1. AWS Account Setup
- AWS CLI installed and configured with appropriate permissions
- AWS account with permissions to create:
  - Cognito User Pools and Identity Pools
  - Lambda functions and IAM roles
  - DynamoDB tables
  - S3 buckets and CloudFront distributions
  - API Gateway and Route53 records
  - Lex V2 bots

### 2. Domain and SSL Certificate
- **Route53 Hosted Zone**: Create a hosted zone for your domain
- **ACM Certificate**: Create an SSL certificate in the `us-east-1` region for CloudFront
  - Certificate must cover your domain (e.g., `*.yourdomain.com` or `chatbot.yourdomain.com`)
  - Certificate must be validated and in "Issued" status

### 3. Development Tools
- **Terraform** (>= 1.0) - Infrastructure as Code
- **PowerShell** - For deployment scripts (Windows/Linux/macOS)
- **AWS CLI** - For manual operations and script execution

## ⚙️ Configuration Guide

### Environment Variables Setup

Before deploying, you need to create a `terraform.tfvars` file with your specific configuration:

```bash
# Navigate to the IaC directory
cd IaC

# Copy the example template
cp terraform.tfvars.example terraform.tfvars

# Edit with your specific values
```

### Required Variables

#### 1. S3 Bucket Name
```hcl
s3_bucket_name = "your-unique-bucket-name"
```
- **Description**: Name for the S3 bucket that will host the frontend
- **Requirements**: Must be globally unique across all AWS accounts
- **Example**: `"meety-frontend-prod-123456"`

#### 2. User Configuration
```hcl
username   = "your-username"
user_email = "your-email@example.com"
```
- **Description**: Initial user that will be created in Cognito User Pool
- **Requirements**: Valid email address for receiving temporary password
- **Example**: 
  ```hcl
  username   = "admin"
  user_email = "admin@yourcompany.com"
  ```

#### 3. Domain Configuration
```hcl
zone_name = "yourdomain.com"
```
- **Description**: Your Route53 hosted zone domain name
- **Requirements**: Must have a Route53 hosted zone already created
- **Example**: `"mycompany.com"`

#### 4. SSL Certificate
```hcl
acm_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
```
- **Description**: ARN of your ACM SSL certificate
- **Requirements**: 
  - Certificate must be in `us-east-1` region (for CloudFront)
  - Certificate must be validated and issued
  - Certificate must cover your domain

### Example Configuration

```hcl
# terraform.tfvars example
s3_bucket_name = "meety-frontend-mycompany-2024"
username       = "admin"
user_email     = "admin@mycompany.com"
zone_name      = "mycompany.com"
acm_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/abcd1234-..."
```

### Optional Variables

These variables have sensible defaults but can be customized:

```hcl
api_name         = "meety-api"           # API Gateway name
user_pool_name   = "meety-userpool"     # Cognito User Pool name
lex_bot_alias_id = "prod"               # Lex bot alias ID
```

### Security Notes

- The `terraform.tfvars` file contains sensitive information
- This file is automatically excluded from version control (`.gitignore`)
- Never commit `terraform.tfvars` to your repository
- Use `terraform.tfvars.example` as a template for team members

## 🚀 Deployment Instructions

### Option 1: One-Click Automated Deployment (Recommended)

Deploy the entire application with a single command:

```powershell
# Run from the project root directory
./deploy.ps1
```

This master deployment script will:
1. **Build Lambda Packages** - Create deployment packages for all Lambda functions
2. **Deploy Infrastructure** - Apply Terraform configuration to create AWS resources
3. **Configure Lex Bot** - Automatically set up intents, slots, and responses
4. **Create Bot Alias** - Create production alias for the Lex bot
5. **Update Configuration** - Update frontend with actual AWS resource IDs
6. **Deploy Frontend** - Upload static files to S3 and invalidate CloudFront cache

**Total deployment time**: ~5-10 minutes

### Option 2: Step-by-Step Deployment

For more control over the deployment process:

#### Step 1: Build Lambda Packages
```powershell
./build-lambda-packages.ps1
```

#### Step 2: Deploy Infrastructure
```bash
cd IaC
terraform init
terraform plan    # Review changes
terraform apply   # Deploy resources
```

#### Step 3: Configure Lex Bot
```powershell
# Automated configuration (recommended)
./configure-lex-intents-fixed.ps1

# Or configure manually via AWS Console (see Lex Configuration section below)
```

#### Step 4: Create Bot Alias and Update Configuration
```powershell
./create-lex-alias.ps1
# This script also calls update-config.ps1 automatically
```

#### Step 5: Deploy Frontend
```powershell
# Get bucket name from Terraform outputs
$outputs = terraform -chdir=IaC output -json | ConvertFrom-Json
$bucketName = $outputs.s3_bucket_name.value

# Upload files to S3
aws s3 sync frontend/ s3://$bucketName/ --delete

# Invalidate CloudFront cache
$distributionId = $outputs.cloudfront_distribution_id.value
aws cloudfront create-invalidation --distribution-id $distributionId --paths "/*"
```

## 🤖 Lex Bot Configuration

### Automated Configuration

The `configure-lex-intents-fixed.ps1` script automates the configuration of the Lex intents, slots, and responses. It uses the AWS CLI to interact with the Lex V2 API.

### Intent Configuration

#### StartMeety Intent

The StartMeety intent is used for greeting and starting conversations.

**Sample Utterances:**
- "Hello"
- "Hi"
- "Hey Meety"
- "help"

**Closing Responses:**
- "Hi! I'm Meety, your meeting assistant. How can I help you schedule a meeting today?"
- "Hello! how may i help you today?"
- "Hi! how can i help you?"

#### MeetingAssistant Intent

The MeetingAssistant intent is used for scheduling meetings.

**Sample Utterances:**
- "I want to schedule a meeting"
- "Book a meeting"
- "Schedule a meeting"
- "Set up a meeting"
- "Create a meeting"
- "I need to schedule a meeting"
- "Help me book a meeting"

**Initial Response:**
- "Sure!"

**Slots Configuration:**

| Slot Name | Slot Type | Prompt | Required |
|-----------|-----------|--------|----------|
| a_FullName | AMAZON.FirstName | "What is your name?" | Yes |
| b_MeetingDate | AMAZON.Date | "What date would you like to schedule the meeting for?" | Yes |
| c_MeetingTime | AMAZON.Time | "What time would you prefer for the meeting?" | Yes |
| d_MeetingDuration | AMAZON.Duration | "How long do you want to meet in minutes? (30 or 60)" | Yes |
| e_AttendeeEmail | AMAZON.EmailAddress | "Please provide me your email address." | Yes |
| f_Confirm | AMAZON.Confirmation | "Do you want to proceed with the meeting?" | Yes |

**Fulfillment:**
- Fulfillment code hook is enabled
- Lambda function: "generative-lex-fulfillment"

#### FallbackIntent

The FallbackIntent is used when the user's input doesn't match any other intent.

**Closing Response:**
- "Sorry, I did not get it. Could you try again?"

### Manual Configuration

If you prefer to configure the Lex intents manually:

#### 1. StartMeety Intent Configuration
1. Go to the AWS Console and navigate to Amazon Lex
2. Select the "MeetyGenerativeBot" bot
3. Go to the "Intents" section and select the "StartMeety" intent
4. Add the closing responses listed above

#### 2. MeetingAssistant Intent Configuration
1. Go to the "MeetingAssistant" intent
2. Add the initial response: "Sure!"
3. Add all the slots from the table above with their respective configurations
4. Configure fulfillment code hook:
   - Enable the fulfillment code hook
   - Select the Lambda function "generative-lex-fulfillment"

#### 3. FallbackIntent Configuration
1. Go to the "FallbackIntent" intent
2. Add the closing response: "Sorry, I did not get it. Could you try again?"

## 🎯 Usage Guide

### Accessing the Application

After successful deployment, access your application at:
```
https://chatbot.yourdomain.com
```
(Replace with your actual domain from the Route53 configuration)

### Chatbot Interface

**Starting a Conversation:**
- Type "Hello", "Hi", or "Help" to begin
- The bot will greet you and offer assistance

**Scheduling a Meeting:**
1. Type "I want to schedule a meeting" or similar
2. Provide the following information when prompted:
   - **Your name**: Full name for the meeting
   - **Meeting date**: Date in YYYY-MM-DD format or natural language
   - **Meeting time**: Time in HH:MM format or natural language
   - **Duration**: Meeting length (30 or 60 minutes)
   - **Email address**: Your contact email
   - **Confirmation**: Confirm to save the meeting

**Example Conversation:**
```
User: Hi
Bot: Hi! I'm Meety, your meeting assistant. How can I help you schedule a meeting today?

User: I want to schedule a meeting
Bot: Sure! What is your name?

User: John Doe
Bot: What date would you like to schedule the meeting for?

User: Tomorrow
Bot: What time would you prefer for the meeting?

User: 2 PM
Bot: How long do you want to meet in minutes? (30 or 60)

User: 60
Bot: Please provide me your email address.

User: john@example.com
Bot: Do you want to proceed with the meeting?

User: Yes
Bot: Perfect! I've scheduled your meeting for [date] at 2:00 PM...
```

### Admin Dashboard

**Signing In:**
1. Click "Sign In" in the top navigation
2. Use the credentials from your `terraform.tfvars` configuration
3. Check your email for the temporary password (first login only)

**Managing Meetings:**
- **View Pending Meetings**: See all meetings awaiting approval
- **Approve/Reject**: Update meeting status with action buttons
- **Meeting Details**: View complete meeting information including attendee details

## 🧪 Testing the Application

**Quick Test Checklist:**
- [ ] Chatbot responds to greetings
- [ ] Meeting scheduling flow works end-to-end
- [ ] Admin login functions properly
- [ ] Pending meetings appear in admin dashboard
- [ ] Meeting status updates work
- [ ] Email notifications are received (if configured)

## 🔧 Troubleshooting

### Common Configuration Issues

1. **S3 Bucket Already Exists**
   - Error: `BucketAlreadyExists`
   - Solution: Choose a different, globally unique bucket name

2. **Certificate Not Found**
   - Error: `InvalidParameterValue`
   - Solution: Verify the certificate ARN and ensure it's in `us-east-1`

3. **Route53 Zone Not Found**
   - Error: `NoSuchHostedZone`
   - Solution: Create the Route53 hosted zone first or verify the domain name

4. **Invalid Email Format**
   - Error: `InvalidParameterValue`
   - Solution: Ensure the email address is valid and properly formatted

### Runtime Issues

1. **Chatbot Not Responding**
   - Check browser console for JavaScript errors
   - Verify Cognito Identity Pool permissions
   - Ensure Lex bot is built and alias exists

2. **Authentication Issues**
   - Verify Cognito User Pool configuration
   - Check temporary password in email
   - Ensure ACM certificate is valid

3. **Meeting Not Saving**
   - Check Lambda function logs in CloudWatch
   - Verify DynamoDB table permissions
   - Ensure all required slots are filled

4. **Frontend Not Loading**
   - Check S3 bucket policy and CloudFront distribution
   - Verify DNS records in Route53
   - Clear browser cache and try again

### Debugging Steps
1. Check AWS CloudWatch logs for Lambda functions
2. Verify all Terraform resources are created successfully
3. Test API endpoints directly using curl or Postman
4. Check browser developer tools for network errors

## 📊 Project Maintenance

### Environment-Specific Configurations

**Development:**
```hcl
s3_bucket_name = "meety-frontend-dev-123"
username       = "dev-admin"
user_email     = "dev-admin@mycompany.com"
```

**Production:**
```hcl
s3_bucket_name = "meety-frontend-prod-123"
username       = "admin"
user_email     = "admin@mycompany.com"
```

### Maintenance Recommendations

1. Regularly run `terraform plan` to check for configuration drift
2. Use variables for all environment-specific values
3. Keep deployment scripts dynamic and avoid hardcoded resource names
4. Periodically review and remove unused files and resources
5. Maintain consistent code formatting across all files
6. Monitor CloudWatch logs for errors and performance issues
7. Update Lambda function dependencies regularly
8. Review and rotate access keys and certificates

### Data Flow

**Meeting Scheduling Flow:**
1. User interacts with chatbot interface
2. Frontend sends messages directly to Lex V2
3. Lex processes intent and extracts slot values
4. Lex calls Lambda fulfillment function
5. Lambda saves meeting data to DynamoDB
6. Response flows back through Lex to frontend

**Admin Management Flow:**
1. Admin authenticates via Cognito User Pool
2. Frontend calls API Gateway with JWT token
3. API Gateway validates token and routes to Lambda
4. Lambda performs CRUD operations on DynamoDB
5. Results returned to admin interface

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

If you encounter issues or have questions:

1. Check the troubleshooting section above
2. Review the AWS CloudWatch logs
3. Validate your `terraform.tfvars` configuration
4. Ensure all prerequisites are met
5. Open an issue in the GitHub repository

---

**Built with ❤️ using AWS Serverless Technologies**